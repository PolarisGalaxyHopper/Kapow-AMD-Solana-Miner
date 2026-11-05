#!/bin/bash
# ============================================================
#   KAPOW SOL Miner — installer
#   1. checks for AMD GPUs      2. downloads TeamRedMiner v0.10.21 from its official
#   GitHub release and verifies the SHA-256      3. creates config.env (asks for
#   your wallet)      4. puts KAPOW 4G / 8G icons on your desktop (if you have one)
#   Safe to run again at any time.
# ============================================================
set -e
cd "$(dirname "$0")"
KIT_DIR="$(pwd)"

TRM_VER="0.10.21"
TRM_URL="https://github.com/todxx/teamredminer/releases/download/v${TRM_VER}/teamredminer-v${TRM_VER}-linux.tgz"
TRM_SHA256="3d5987bba0125150cbb47c49b5929ea579dca1ac3cae4b7a70e96c2c5f843836"

MG='\033[0;35m'; BM='\033[1;35m'; YL='\033[0;33m'; RD='\033[1;31m'; NC='\033[0m'

echo -e "${BM}"
cat << 'BANNER'
 ██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗
 ██║ ██╔╝██╔══██╗██╔══██╗██╔═══██╗██║    ██║
 █████╔╝ ███████║██████╔╝██║   ██║██║ █╗ ██║
 ██╔═██╗ ██╔══██║██╔═══╝ ██║   ██║██║███╗██║
 ██║  ██╗██║  ██║██║     ╚██████╔╝╚███╔███╔╝
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝  ╚══╝╚══╝
BANNER
echo -e "  Polaris Galaxy Hopper · SOL via unMineable · TeamRedMiner v${TRM_VER}${NC}"
echo ""

echo -e "${MG}[1/4] AMD GPUs${NC}"
AMD_COUNT=$(grep -l '^amdgpu$' /sys/class/hwmon/hwmon*/name 2>/dev/null | wc -l)
if (( AMD_COUNT > 0 )); then
    echo "      found ${AMD_COUNT} AMD GPU(s)"
else
    echo -e "      ${YL}no AMD GPU seen by the amdgpu driver. The miner will not find cards until the driver is installed.${NC}"
fi

echo -e "${MG}[2/4] TeamRedMiner v${TRM_VER}${NC}"
if [[ -x "$KIT_DIR/teamredminer" ]]; then
    echo "      already installed"
else
    dl=""; command -v curl >/dev/null && dl="curl -sSL -o"; [[ -z "$dl" ]] && command -v wget >/dev/null && dl="wget -q -O"
    if [[ -z "$dl" ]]; then echo -e "      ${RD}need curl or wget (apt install curl)${NC}"; exit 1; fi
    tmp="$(mktemp -d)"
    echo "      downloading from github.com/todxx/teamredminer ..."
    $dl "$tmp/trm.tgz" "$TRM_URL"
    got="$(sha256sum "$tmp/trm.tgz" | cut -d' ' -f1)"
    if [[ "$got" != "$TRM_SHA256" ]]; then
        echo -e "      ${RD}SHA-256 mismatch — download refused.${NC}"
        echo "      expected ${TRM_SHA256}"
        echo "      got      ${got}"
        rm -rf "$tmp"; exit 1
    fi
    tar -xzf "$tmp/trm.tgz" -C "$tmp"
    cp "$tmp/teamredminer-v${TRM_VER}-linux/teamredminer" "$KIT_DIR/teamredminer"
    chmod +x "$KIT_DIR/teamredminer"
    rm -rf "$tmp"
    echo "      installed and verified (sha256 ok)"
fi

echo -e "${MG}[3/4] your settings${NC}"
chmod +x "$KIT_DIR"/*.sh "$KIT_DIR"/*.py 2>/dev/null || true
[[ -f config.env ]] || cp config.env.example config.env
# shellcheck disable=SC1091
source ./config.env
if [[ -n "${WALLET:-}" ]] && [[ "$WALLET" =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; then
    echo "      wallet already set in config.env: ${WALLET}"
else
    if [[ -t 0 ]]; then
        echo "      Enter the Solana wallet address that should receive your SOL (leave empty to do it on first start):"
        read -r -p "      Wallet address: " w
        if [[ "$w" =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; then
            sed -i "s|^WALLET=.*|WALLET=${w}|" config.env; echo "      saved"
        else
            echo "      not set — kapow.sh will ask on first start"
        fi
    else
        echo "      WALLET not set — kapow.sh will ask on first start (or edit config.env)"
    fi
fi

echo -e "${MG}[4/4] desktop icons${NC}"
DESK="${HOME}/Desktop"; APPS="${HOME}/.local/share/applications"
if [[ -d "$DESK" ]] || [[ -d "$APPS" ]]; then
    mkdir -p "$APPS"
    for ed in 4G 8G; do
        src="$KIT_DIR/KAPOW-${ed}.desktop.in"
        for dst in "$DESK/KAPOW-${ed}.desktop" "$APPS/kapow-${ed,,}.desktop"; do
            [[ -d "$(dirname "$dst")" ]] || continue
            sed "s|@KIT_DIR@|${KIT_DIR}|g" "$src" > "$dst"; chmod +x "$dst"
        done
    done
    command -v gio >/dev/null && for ed in 4G 8G; do [[ -f "$DESK/KAPOW-${ed}.desktop" ]] && gio set "$DESK/KAPOW-${ed}.desktop" metadata::trusted true 2>/dev/null; done
    echo "      KAPOW 4G and KAPOW 8G icons placed on the desktop / app menu"
else
    echo "      no desktop found — start with ./start-4g.sh or ./start-8g.sh"
fi

echo ""
echo -e "${BM}  KAPOW is ready.${NC}"
echo -e "${MG}  4 GB cards:  ./start-4g.sh        8 GB cards:  ./start-8g.sh${NC}"
echo -e "${MG}  (or double-click the KAPOW icon on your desktop)${NC}"
echo ""
