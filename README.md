# KAPOW — SOL Miner for AMD GPUs

Turn an old AMD graphics card into SOL. KAPOW is a one-folder kit from Polaris Galaxy Hopper that runs **TeamRedMiner** against **unMineable**, which pays you in **Solana (SOL)** straight to your own wallet. No account, no sign-up, no personal data: your wallet address *is* your account.

- **KAPOW 4G** — RX 470 / 480 / 570 / 580 with 4 GB. Mines ALPH (Blake3), because the ETC DAG no longer fits in 4 GB.
- **KAPOW 8G** — RX 480 / 580 with 8 GB, Vega, RX 5700. Mines ETCHASH.

Both pay SOL. Pick the one that matches your cards, or run both on a mixed rig (each on its own cards, see *Advanced*).

## Install (Linux, HiveOS included)

```
git clone https://github.com/PolarisGalaxyHopper/Kapow-AMD-Solana-Miner.git
cd Kapow-AMD-Solana-Miner
./install.sh          # downloads TeamRedMiner v0.10.21 from its official release and checks the SHA-256,
                      # asks for your Solana wallet, puts KAPOW 4G / 8G icons on your desktop
./start-4g.sh         # or ./start-8g.sh, or double-click the KAPOW icon
```

That is all. The miner window shows your wallet, worker name, pool and a link to your live stats:
`https://unmineable.com/coins/SOL/address/<your wallet>`. Close the window to stop mining.

## Your settings

Everything you might want to change is in **`config.env`** (created from `config.env.example`):

| Setting | What it is | Default |
|---|---|---|
| `WALLET` | your Solana address, where SOL is paid | asked on first start |
| `WORKER` | a name for this rig on your stats page | `rig1` |
| `REFERRAL` | unMineable referral code sent with each share: your pool fee drops from 1 % to 0.75 % and the project is credited | `U-91QW42` |
| `POOL_4G` / `POOL_8G` | unMineable stratum for each edition | `blake3.unmineable.com:3333` / `etchash.unmineable.com:3333` |
| `API_PORT_4G` / `API_PORT_8G` | the miner's local stats port (loopback only) | `10081` / `10082` |
| `TRM_EXTRA` | extra TeamRedMiner flags, e.g. `-d 0,1,2` to pick cards | empty |

Any Solana wallet works: Phantom, Solflare, Backpack, a hardware wallet, or an exchange deposit address for SOL.

## What is in the folder

| File | Purpose |
|---|---|
| `install.sh` | one-time setup, safe to re-run |
| `kapow.sh 4g\|8g` | the launcher (banner, settings, auto-restart loop) |
| `start-4g.sh`, `start-8g.sh` | shortcuts for the launcher |
| `gpu_restart.sh` | called by the miner when a card looks dead; checks the miner's own stats first so a quiet moment between jobs is not mistaken for a crash |
| `watchdog.sh 4g\|8g` | optional: warns on hot cards, fans at max, memory pressure; stops the miner above 85 °C |
| `power-stats.sh 4g\|8g` | small terminal view: temperature, fan, watts and hashrate per card |
| `power-monitor.py 4g\|8g` | the same as a tiny always-on-top window (needs python3-gi / GTK 3) |
| `KAPOW-4G.desktop.in`, `KAPOW-8G.desktop.in`, `kapow4g.svg`, `kapow8g.svg` | the KAPOW desktop icons (install.sh fills in the paths) |
| `SETUP.md` | the longer guide: payouts, HiveOS notes, troubleshooting |

## Facts worth knowing

- **Payouts** come from unMineable in SOL, after their minimum payout is reached, to the wallet in your config. unMineable's fee is 1 %, or **0.75 % with the referral code** the kit sends by default (`REFERRAL` in `config.env`); the same code credits the Polaris Galaxy Hopper project. TeamRedMiner has its own built-in developer fee. KAPOW itself adds nothing.
- **New to unMineable?** Sign up or just look around at https://unmineable.com/?ref=U-91QW42 — no account is needed to mine; the wallet address is enough.
- **Expected speed**: about 440 Mh/s per RX 470/570 4 GB on ALPH; about 28–30 Mh/s per 8 GB card on ETCHASH. A six-card 4 GB rig makes roughly 2.6 Gh/s at 540–600 W.
- **Nothing leaves your rig** except the pool connection. The miner's stats API listens on localhost only. No telemetry, no remote control.
- **Safety**: cards above 83 °C are shown in red; the optional watchdog stops the miner at 85 °C. Clean dust, renew thermal paste, keep the risers seated.

## Advanced

- Mixed rig: put the 4 GB cards on one edition and the 8 GB cards on the other with `-d` in each window, e.g. start 4G with `TRM_EXTRA="-d 0,1,2"` and 8G with `TRM_EXTRA="-d 3,4,5"` (edit `config.env` between starts, or run `TRM_EXTRA=... ./kapow.sh 8g`).
- Other payout coins: unMineable pays many coins. Change `SOL:` in `kapow.sh` to another ticker and the pool host to the matching algorithm if you know what you are doing.
- Run as a service: `watchdog.sh` plus `kapow.sh` in a `screen` or a systemd unit both work; the launcher already restarts the miner after a crash.

## Licence

MIT, Polaris Galaxy Hopper. TeamRedMiner is a separate program with its own licence; `install.sh` downloads it from its official GitHub release and verifies the checksum.
