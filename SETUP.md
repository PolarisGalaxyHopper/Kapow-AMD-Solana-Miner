# KAPOW — setup guide

## 1. What you need

- A Linux box with one or more AMD cards and the `amdgpu` driver (HiveOS, Ubuntu 20.04+, Debian 11+ all work).
- Internet access on port 3333 to `*.unmineable.com`.
- A Solana wallet address. Make one in Phantom, Solflare or Backpack, or use a hardware wallet. An exchange SOL deposit address also works.

## 2. Install

```
git clone https://github.com/PolarisGalaxyHopper/Kapow-AMD-Solana-Miner.git
cd Kapow-AMD-Solana-Miner
./install.sh
```

`install.sh` downloads **TeamRedMiner v0.10.21** from `github.com/todxx/teamredminer`, compares the file's SHA-256 against the value pinned in the script, and refuses anything that does not match. It then creates `config.env` and asks for your wallet. Running it again later only repairs what is missing.

## 3. Start

- Desktop: double-click **KAPOW 4G** or **KAPOW 8G**.
- Terminal: `./start-4g.sh` or `./start-8g.sh`.

The first start asks for your wallet if `config.env` does not have one yet, and saves it. From then on it just mines. Close the window (or Ctrl+C) to stop.

## 4. Which edition

| Cards | Edition | Algorithm | Why |
|---|---|---|---|
| RX 470 / 480 / 570 / 580 **4 GB** | 4G | ALPH (Blake3) | the ETC DAG is larger than 4 GB, so these cards can no longer mine ETCHASH |
| RX 480 / 580 **8 GB**, Vega 56/64, RX 5600/5700 | 8G | ETCHASH | best earner for 8 GB Polaris/Vega/Navi on unMineable |

Both pay SOL. On a mixed rig run both, each limited to its own cards with `TRM_EXTRA="-d ..."` (card numbers as TeamRedMiner lists them at start).

## 5. Referral code and fees

`config.env` ships with `REFERRAL=U-91QW42`. The launcher appends it to the worker name (`SOL:<wallet>.<worker>#U-91QW42`), which is how unMineable applies a referral on the mining side: your fee drops from 1 % to 0.75 % and the Polaris Galaxy Hopper project receives unMineable's referral credit. Clear the value to mine without it. The same code is in the sign-up link https://unmineable.com/?ref=U-91QW42.

## 6. Watching your earnings

unMineable shows everything at `https://unmineable.com/coins/SOL/address/<your wallet>`: hashrate, each worker by name, pending balance and payouts. The address page appears a few minutes after the first accepted share. Payout happens automatically once the pending balance reaches unMineable's minimum for SOL.

## 7. HiveOS notes

- Run KAPOW from a terminal on the rig's desktop or over SSH. It does not need a HiveOS flight sheet.
- HiveOS `autofan` keeps controlling the fans; KAPOW does not touch fan curves. If you prefer TeamRedMiner's own fan control, add it to `TRM_EXTRA`.
- Do not start a HiveOS miner on the same cards at the same time.

## 8. Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| `teamredminer is not installed yet` | install not run | `./install.sh` |
| `SHA-256 mismatch — download refused` | corrupted or tampered download | run `./install.sh` again; if it repeats, do not use the file |
| No GPUs listed by the miner | driver not loaded | `lsmod \| grep amdgpu`; on HiveOS check the card is in `gpu-detect list` |
| Hashrate fine, shares 0 | pool unreachable | `nc -vz blake3.unmineable.com 3333`; check your firewall / ISP |
| One card restarts the miner repeatedly | riser, power or bad card | swap the riser USB cable, reseat the x1 adapter, check the PCIe power lead |
| Card shown red / miner stops at 85 °C | cooling | dust, thermal paste, fan direction, ambient temperature |
| Two desktops or two miners after a reboot | started twice | only one window per edition; the launcher closes a stale copy on the same port |

## 9. Privacy

The only outbound connection is the stratum session to unMineable. The miner's JSON stats API listens on `127.0.0.1` only. Your wallet address is public on the blockchain anyway; the worker name is whatever you choose.
