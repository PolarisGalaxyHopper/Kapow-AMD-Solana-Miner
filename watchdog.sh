#!/bin/bash
# ============================================================
#   KAPOW — optional health watchdog
#   Run it in a second terminal:  tools/watchdog.sh 4g   (or 8g)
#   Every 30 s: warns on hot cards / fans at max / memory pressure,
#   and stops the miner when a card passes the critical temperature.
#   (kapow.sh restarts the miner 10 s later; if it keeps tripping, fix the cooling.)
# ============================================================
ED="${1:-4g}"; DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${DIR}/watchdog.log"
# shellcheck disable=SC1091
source "${DIR}/config.env" 2>/dev/null || true
if [[ "$ED" == 4g ]]; then PORT="${API_PORT_4G:-10081}"; else PORT="${API_PORT_8G:-10082}"; fi
TEMP_WARN=78; TEMP_CRITICAL=85; FAN_WARN=92; MEM_WARN_PCT=85; INTERVAL=30
stamp() { date '+%Y-%m-%d %H:%M:%S'; }
log()   { echo "[$(stamp)] $*" | tee -a "$LOG"; }

check_gpus() {
    local i=0 total=0
    for h in /sys/class/hwmon/hwmon*; do
        [[ "$(cat "$h/name" 2>/dev/null)" == amdgpu ]] || continue
        local t=$(( $(cat "$h/temp1_input" 2>/dev/null || echo 0) / 1000 ))
        local f=$(( $(cat "$h/pwm1" 2>/dev/null || echo 0) * 100 / 255 ))
        local p=$(( $(cat "$h/power1_average" 2>/dev/null || cat "$h/power1_input" 2>/dev/null || echo 0) / 1000000 ))
        total=$(( total + p ))
        if (( t >= TEMP_CRITICAL )); then
            log "!!! CRITICAL: GPU${i} ${t}°C — stopping the miner to protect the card"
            pkill -f "api_listen=127.0.0.1:${PORT}" 2>/dev/null
        elif (( t >= TEMP_WARN )); then
            log "  WARN: GPU${i} ${t}°C (warn at ${TEMP_WARN}°C)"
        fi
        (( f >= FAN_WARN )) && log "  WARN: GPU${i} fan ${f}% — check airflow / thermal paste"
        (( f <= 20 && t >= 60 )) && log "  WARN: GPU${i} fan ${f}% at ${t}°C — fan may be stuck"
        i=$((i+1))
    done
    log "  ${i} GPU(s), total ${total} W"
}
check_memory() {
    local tot avail pct; tot=$(awk '/MemTotal/{print $2}' /proc/meminfo); avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    pct=$(( (tot - avail) * 100 / tot )); (( pct >= MEM_WARN_PCT )) && log "  WARN: memory ${pct}% used"
}
check_miner() { pgrep -f "api_listen=127.0.0.1:${PORT}" >/dev/null || log "  miner for ${ED} is not running (start it with ./start-${ED}.sh)"; }

log "=== KAPOW watchdog (${ED}) started — warn ${TEMP_WARN}°C, critical ${TEMP_CRITICAL}°C, every ${INTERVAL}s ==="
while true; do check_miner; check_gpus; check_memory; sleep "$INTERVAL"; done
