#!/bin/bash
# Called by TeamRedMiner (--watchdog_script) when it flags a GPU as dead.
# Between ALPH jobs a card can look idle for a moment, so the miner's own API is
# asked first; the miner is only restarted when the whole rig really reports 0 h/s.
GPU="${1:-?}"
PORT="${KAPOW_API_PORT:-10081}"
DIR="${KAPOW_KIT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LOG="${DIR}/watchdog.log"
stamp() { date '+%Y-%m-%d %H:%M:%S'; }

stats=$(curl -s --max-time 3 "http://127.0.0.1:${PORT}" 2>/dev/null)
if [[ -z "$stats" ]]; then
    echo "[$(stamp)] GPU ${GPU}: miner API unreachable — restarting miner" >> "$LOG"
    pkill -f "api_listen=127.0.0.1:${PORT}" 2>/dev/null
    exit 0
fi
total=$(printf '%s' "$stats" | python3 -c '
import json,sys
d=json.load(sys.stdin)
g=d.get("Algorithms",[{}])[0].get("GPUs",[])
print(sum(float(x.get("Hashrate Avg",0)) for x in g))' 2>/dev/null)
if [[ -z "$total" || "$total" == "0" || "$total" == "0.0" ]]; then
    echo "[$(stamp)] GPU ${GPU}: confirmed dead (rig average 0 h/s) — restarting miner" >> "$LOG"
    pkill -f "api_listen=127.0.0.1:${PORT}" 2>/dev/null
else
    echo "[$(stamp)] GPU ${GPU}: false alarm (rig average ${total} h/s) — ignored" >> "$LOG"
fi
