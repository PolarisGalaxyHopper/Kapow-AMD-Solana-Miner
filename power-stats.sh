#!/bin/bash
# KAPOW — live temperature / fan / power / hashrate in a small terminal.
# Usage: ./power-stats.sh [4g|8g]    (default 4g)      Ctrl+C to close.
ED="${1:-4g}"; DIR="$(cd "$(dirname "$0")" && pwd)"; LOG="${DIR}/kapow-${ED}.log"
PU='\033[0;35m'; GR='\033[0;32m'; YL='\033[1;33m'; RD='\033[1;31m'; CY='\033[1;36m'; DM='\033[2;37m'; NC='\033[0m'
while true; do
    clear
    echo -e "${PU}⚡ KAPOW ${ED^^}  POWER MONITOR${NC}"
    echo -e "${DM}─────────────────────────────${NC}"
    total=0; i=0
    for h in /sys/class/hwmon/hwmon*; do
        [[ "$(cat "$h/name" 2>/dev/null)" == amdgpu ]] || continue
        t=$(( $(cat "$h/temp1_input" 2>/dev/null || echo 0) / 1000 ))
        f=$(( $(cat "$h/pwm1" 2>/dev/null || echo 0) * 100 / 255 ))
        p=$(( $(cat "$h/power1_average" 2>/dev/null || cat "$h/power1_input" 2>/dev/null || echo 0) / 1000000 ))
        total=$(( total + p ))
        tc=$GR; (( t >= 75 )) && tc=$YL; (( t >= 83 )) && tc=$RD
        warn=""; (( t >= 83 )) && warn=" HOT!"; (( f >= 95 )) && warn="$warn FAN MAX"
        printf "  ${DM}G%d${NC}  ${tc}%3d°C${NC}  fan:%3d%%  %3dW${YL}%s${NC}\n" "$i" "$t" "$f" "$p" "$warn"
        i=$((i+1))
    done
    pc=$CY; (( total > 540 )) && pc=$YL; (( total > 600 )) && pc=$RD
    echo -e "${DM}─────────────────────────────${NC}"
    echo -e "  TOTAL  ${pc}${total}W${NC}"
    hr=$(grep -E "Total +(alph|etchash):" "$LOG" 2>/dev/null | tail -1 | grep -oE '(alph|etchash): [0-9.]+ ?[kMG]?h/s' | head -1 | cut -d' ' -f2-)
    echo -e "  HASH   ${GR}${hr:-—}${NC}"
    echo -e "${DM}─────────────────────────────${NC}\n  ${DM}updates every 5 s  •  Ctrl+C to close${NC}"
    sleep 5
done
