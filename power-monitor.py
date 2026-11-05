#!/usr/bin/env python3
"""
KAPOW — Power & Health Monitor (small always-on-top window). Usage: tools/power-monitor.py [4g|8g]
Pins to top-right of screen. Always on top.
"""
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk
import glob, re, os, sys

EDITION = (sys.argv[1] if len(sys.argv) > 1 else "4g").lower()
LOG_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), f"kapow-{EDITION}.log")
UPDATE_MS = 5000
Y_POS     = 4

def get_gpu_stats():
    """Read every AMD card straight from the kernel (works on any Linux, HiveOS included)."""
    out = []
    try:
        for h in sorted(glob.glob("/sys/class/hwmon/hwmon*")):
            try:
                if open(os.path.join(h, "name")).read().strip() != "amdgpu":
                    continue
                def rd(name, div):
                    try:
                        return int(open(os.path.join(h, name)).read().strip()) // div
                    except Exception:
                        return 0
                power = rd("power1_average", 1000000) or rd("power1_input", 1000000)
                out.append({"idx": len(out), "temp": rd("temp1_input", 1000),
                            "fan": rd("pwm1", 1) * 100 // 255, "power": power})
            except Exception:
                continue
    except Exception:
        pass
    return out

def get_hashrate():
    try:
        if not os.path.exists(LOG_FILE):
            return "no log"
        with open(LOG_FILE) as f:
            lines = f.readlines()
        for line in reversed(lines):
            m = re.search(r"Total\s+(?:alph|etchash):\s+([\d.]+\s*[kMG]?h/s)", line)
            if m:
                return m.group(1)
        return "—"
    except:
        return "—"

class PowerMonitor(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_title("KAPOW Power")
        self.set_type_hint(Gdk.WindowTypeHint.UTILITY)
        self.set_keep_above(True)
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_app_paintable(True)

        # Reposition to top-right after window size is known
        self.connect("size-allocate", self._snap_to_top_right)

        self._snapped = False

        # Drag to move
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.connect("button-press-event",
            lambda w, e: self.begin_move_drag(e.button, int(e.x_root), int(e.y_root), e.time)
            if e.button == 1 else None)

        self.grid = Gtk.Grid()
        self.grid.set_row_spacing(1)
        self.grid.set_border_width(6)
        self.add(self.grid)

        self.rows = []
        self.build_ui()
        self.update()
        GLib.timeout_add(UPDATE_MS, self.update)

    def _snap_to_top_right(self, widget, alloc):
        if self._snapped:
            return
        display = Gdk.Display.get_default()
        monitor = display.get_primary_monitor() or display.get_monitor(0)
        geo = monitor.get_geometry()
        sw = geo.width
        w, _ = self.get_size()
        if w > 50:
            self.move(sw - w - 4, Y_POS)
            self._snapped = True

    def lbl(self, text, color="#aaaaaa", bold=False, size=10, align=Gtk.Align.START):
        l = Gtk.Label()
        weight = " weight='bold'" if bold else ""
        l.set_markup(f"<span foreground='{color}' font='{size}'{weight}>{text}</span>")
        l.set_halign(align)
        return l

    def build_ui(self):
        r = 0
        # Title
        title = self.lbl(f"⚡  KAPOW {EDITION.upper()}  POWER", "#cc44ff", bold=True, size=10)
        self.grid.attach(title, 0, r, 3, 1)
        r += 1

        sep = Gtk.Separator()
        self.grid.attach(sep, 0, r, 3, 1)
        r += 1

        # Header
        self.grid.attach(self.lbl("GPU", "#555555", size=9), 0, r, 1, 1)
        self.grid.attach(self.lbl("TEMP  FAN", "#555555", size=9), 1, r, 1, 1)
        self.grid.attach(self.lbl("PWR", "#555555", size=9, align=Gtk.Align.END), 2, r, 1, 1)
        r += 1

        # GPU rows
        self.gpu_labels = []
        for i in range(6):
            g  = self.lbl(f"G-", "#555555", size=9)
            tf = self.lbl("—", "#555555", size=9)
            pw = self.lbl("—W", "#555555", size=9, align=Gtk.Align.END)
            self.grid.attach(g,  0, r, 1, 1)
            self.grid.attach(tf, 1, r, 1, 1)
            self.grid.attach(pw, 2, r, 1, 1)
            self.gpu_labels.append((g, tf, pw))
            r += 1

        sep2 = Gtk.Separator()
        self.grid.attach(sep2, 0, r, 3, 1)
        r += 1

        # Total power
        self.grid.attach(self.lbl("TOTAL", "#555555", size=10), 0, r, 1, 1)
        self.total_lbl = self.lbl("—W", "#00ccdd", bold=True, size=10)
        self.grid.attach(self.total_lbl, 1, r, 2, 1)
        r += 1

        # Hashrate
        self.grid.attach(self.lbl("HASH", "#555555", size=10), 0, r, 1, 1)
        self.hash_lbl = self.lbl("—", "#44ff88", size=10)
        self.grid.attach(self.hash_lbl, 1, r, 2, 1)
        r += 1

        # Warning row
        self.warn_lbl = self.lbl("", "#ffcc00", size=9)
        self.warn_lbl.set_no_show_all(True)
        self.grid.attach(self.warn_lbl, 0, r, 3, 1)

    def update(self):
        gpus = get_gpu_stats()
        total = 0
        warns = []

        for i, (gl, tfl, pwl) in enumerate(self.gpu_labels):
            if i < len(gpus):
                g = gpus[i]
                total += g["power"]

                tc = "#ff4444" if g["temp"] >= 83 else "#ffcc00" if g["temp"] >= 75 else "#88cc88"
                fc = "#ffcc00" if g["fan"] >= 93 else "#aaaaaa"

                gl.set_markup(f"<span foreground='#888888' font='9'>G{g['idx']}</span>")
                tfl.set_markup(
                    f"<span foreground='{tc}' font='9'>{g['temp']}°C</span>"
                    f"<span foreground='#444444' font='9'>  </span>"
                    f"<span foreground='{fc}' font='9'>{g['fan']}%</span>"
                )
                pwl.set_markup(f"<span foreground='#aaaaaa' font='9'>{g['power']}W</span>")

                if g["temp"] >= 83:
                    warns.append(f"G{g['idx']} HOT {g['temp']}°C")
                if g["fan"] >= 95:
                    warns.append(f"G{g['idx']} FAN MAX")
            else:
                gl.set_markup(f"<span foreground='#333333' font='9'>—</span>")
                tfl.set_markup(f"<span foreground='#333333' font='9'>—</span>")
                pwl.set_markup(f"<span foreground='#333333' font='9'>—</span>")

        pwr_color = "#ff4444" if total > 600 else "#ffcc00" if total > 540 else "#00ccdd"
        self.total_lbl.set_markup(
            f"<span foreground='{pwr_color}' font='10' weight='bold'>{total}W</span>"
        )

        hr = get_hashrate()
        self.hash_lbl.set_markup(f"<span foreground='#44ff88' font='10'>{hr}</span>")

        if warns:
            self.warn_lbl.set_markup(
                f"<span foreground='#ffcc00' font='9'>⚠ {'  '.join(warns)}</span>"
            )
            self.warn_lbl.show()
        else:
            self.warn_lbl.hide()

        self.show_all()
        return True

if __name__ == "__main__":
    win = PowerMonitor()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
