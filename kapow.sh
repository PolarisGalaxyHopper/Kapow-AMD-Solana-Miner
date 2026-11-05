#!/bin/bash
# ============================================================
#   KAPOW SOL Miner — launcher
#   Usage:  ./kapow.sh 4g      (4 GB AMD cards → ALPH Blake3 → unMineable → SOL)
#           ./kapow.sh 8g      (8 GB AMD cards → ETCHASH     → unMineable → SOL)
#   Settings live in config.env next to this file.
# ============================================================
set -u
cd "$(dirname "$0")"
KIT_DIR="$(pwd)"

EDITION="${1:-}"
case "$EDITION" in
    4g|4G) EDITION=4g; ALGO=alph;    LABEL="4G"; ALGO_LABEL="ALPH Blake3"; CARDS="RX 470 / 480 / 570 / 580 (4 GB)";   C1='\033[1;35m'; C2='\033[0;35m'; DM='\033[2;35m' ;;
    8g|8G) EDITION=8g; ALGO=etchash; LABEL="8G"; ALGO_LABEL="ETCHASH";     CARDS="RX 480 / 580 8 GB · Vega · RX 5700"; C1='\033[1;36m'; C2='\033[0;36m'; DM='\033[2;36m' ;;
    *) echo "Usage: $0 4g | 8g"; exit 2 ;;
esac
YL='\033[0;33m'; NC='\033[0m'

# ---------- settings ----------
if [[ ! -f config.env ]]; then
    cp config.env.example config.env
fi
# shellcheck disable=SC1091
source ./config.env
WORKER="${WORKER:-rig1}"
if [[ "$EDITION" == 4g ]]; then POOL="${POOL_4G:-blake3.unmineable.com:3333}";  API_PORT="${API_PORT_4G:-10081}"
else                            POOL="${POOL_8G:-etchash.unmineable.com:3333}"; API_PORT="${API_PORT_8G:-10082}"; fi
TRM_EXTRA="${TRM_EXTRA:-}"
REFERRAL="${REFERRAL-U-91QW42}"   # default when the setting is missing; an empty REFERRAL= in config.env opts out
REF_SUFFIX="${REFERRAL:+#${REFERRAL}}"

valid_wallet() { [[ "$1" =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; }

if ! valid_wallet "${WALLET:-}"; then
    echo ""
    echo -e "  ${C2}Enter the Solana wallet address that should receive your SOL.${NC}"
    while true; do
        read -r -p "  Wallet address: " WALLET
        valid_wallet "$WALLET" && break
        echo -e "  ${YL}That does not look like a Solana address (32–44 base58 characters). Try again.${NC}"
    done
    # save it for next time
    if grep -q '^WALLET=' config.env; then sed -i "s|^WALLET=.*|WALLET=${WALLET}|" config.env; else echo "WALLET=${WALLET}" >> config.env; fi
    echo -e "  ${DM}Saved to config.env${NC}"
fi

TRM="${KIT_DIR}/teamredminer"
if [[ ! -x "$TRM" ]]; then
    echo -e "\n  ${YL}teamredminer is not installed yet. Run:  ./install.sh${NC}\n"
    exit 1
fi

# ---------- banner ----------
clear
echo -e "${C1}"
cat << 'BANNER'
 ██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗
 ██║ ██╔╝██╔══██╗██╔══██╗██╔═══██╗██║    ██║
 █████╔╝ ███████║██████╔╝██║   ██║██║ █╗ ██║
 ██╔═██╗ ██╔══██║██╔═══╝ ██║   ██║██║███╗██║
 ██║  ██╗██║  ██║██║     ╚██████╔╝╚███╔███╔╝
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝  ╚══╝╚══╝
BANNER
echo -e "${DM}══════════════════════════════════════════════════${NC}"
echo -e "${C2}      ${LABEL} EDITION  ·  Polaris Galaxy Hopper${NC}"
echo -e "${C2}      ${ALGO_LABEL} → unMineable → SOL${NC}"
echo -e "${DM}      TeamRedMiner v0.10.21${NC}"
echo -e "${DM}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${C2}AMD GPU : ${CARDS}${NC}"
echo -e "  ${C2}Wallet  : ${C1}${WALLET}${NC}"
echo -e "  ${C2}Worker  : ${WORKER}${NC}"
echo -e "  ${C2}Pool    : ${POOL}${NC}"
if [[ -n "$REFERRAL" ]]; then echo -e "  ${C2}Referral: ${REFERRAL}  ${DM}(pool fee 0.75 % instead of 1 %)${NC}"; fi
echo -e "  ${C2}Stats   : https://unmineable.com/coins/SOL/address/${WALLET}${NC}"
echo ""
echo -e "  ${DM}Close this window or press Ctrl+C to stop mining.${NC}"
echo ""

# one miner per edition: stop a stale copy using the same API port
if pgrep -f "api_listen=127.0.0.1:${API_PORT}" >/dev/null 2>&1; then
    pkill -f "api_listen=127.0.0.1:${API_PORT}" 2>/dev/null; sleep 3
fi

export KAPOW_API_PORT="$API_PORT" KAPOW_KIT_DIR="$KIT_DIR"
trap 'echo; echo "  Stopping miner..."; pkill -f "api_listen=127.0.0.1:${API_PORT}" 2>/dev/null; exit 0' INT TERM

while true; do
    # shellcheck disable=SC2086
    "$TRM" \
        -a "$ALGO" \
        -o "stratum+tcp://${POOL}" \
        -u "SOL:${WALLET}.${WORKER}${REF_SUFFIX}" \
        -p x \
        --api_listen=127.0.0.1:${API_PORT} \
        --log_file="${KIT_DIR}/kapow-${EDITION}.log" \
        --watchdog_script="${KIT_DIR}/gpu_restart.sh" \
        $TRM_EXTRA
    code=$?
    echo -e "\n  ${YL}[$(date '+%Y-%m-%d %H:%M:%S')] Miner stopped (exit ${code}). Restarting in 10 s. Close the window to stop.${NC}\n"
    sleep 10
done
