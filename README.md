<div align="center">

# Mythic Validator

[![Network](https://img.shields.io/badge/network-mythic%20l2-39FF14?style=flat-square)](https://mythic.sh)
[![Built by](https://img.shields.io/badge/built%20by-MythicLabs-7B2FFF?style=flat-square)](https://mythiclabs.io)
[![License: BUSL-1.1](https://img.shields.io/badge/license-BUSL--1.1-39FF14?style=flat-square)](./LICENSE)
[![Firedancer](https://img.shields.io/badge/firedancer-v0.812-black?style=flat-square)](https://github.com/firedancer-io/firedancer)

**Run a full validator on the Mythic L2 AI-native blockchain. Powered by Firedancer.**

[Install](https://mythic.sh/install) · [Documentation](https://mythic.sh/docs/validators) · [Network Status](https://mythic.sh/tokenomics)

</div>

---

## Quick Start

One command to install and configure a Mythic validator:

```bash
curl -sSf mythic.sh/install | sudo bash
```

The installer auto-detects your hardware and selects the appropriate tier:

| Tier | CPU | RAM | Storage | Role |
|------|-----|-----|---------|------|
| Mini | 8+ cores | 32GB | 500GB SSD | RPC-only, lean |
| **Validator** | **32+ cores** | **128GB** | **2TB NVMe** | **Full RPC + tx history** |
| AI | 48+ cores | 256GB | 10TB NVMe | GPU inference sidecar |

This repo is the **Validator** (standard) tier. See also: [mythic-mini](https://github.com/MythicFoundation/mythic-mini) · [mythic-ai-validator](https://github.com/MythicFoundation/mythic-ai-validator)

## Requirements

- **OS:** Ubuntu 22.04+ (Linux required)
- **CPU:** 32+ cores
- **RAM:** 128GB+
- **Storage:** 2TB NVMe SSD
- **Network:** 1Gbps+, public IP, ports 8001/UDP + 8899/TCP open

## What Gets Installed

- **Firedancer** (fdctl) v0.812 — high-performance SVM validator client
- **Solana CLI** — for key generation and on-chain operations
- **Config** at `/etc/mythic/config.toml` — pre-tuned for validator tier
- **Identity keypair** at `/etc/mythic/validator-identity.json`
- **Vote keypair** at `/etc/mythic/vote-account.json`
- **Systemd service** — `mythic-validator.service`

## Configuration

The installer places a Firedancer config at `/etc/mythic/config.toml`:

```toml
[consensus]
  identity_path       = "/etc/mythic/validator-identity.json"
  vote_account_path   = "/etc/mythic/vote-account.json"
  snapshot_fetch      = true
  genesis_fetch       = true

[rpc]
  port                = 8899
  full_api            = true
  transaction_history = true

[gossip]
  port                = 8001
  entrypoints         = ["20.96.180.64:8001"]

[tiles]
  layout = "1 net, 1 quic, 2 verify, 1 dedup, 1 resolv, 1 pack, 4 bank, 1 poh, 1 shred, 1 store, 1 metric, 1 sign, 1 plugin"
```

Full config template: [`mythic-validator.toml`](./mythic-validator.toml)

## Usage

```bash
# Start
sudo systemctl start mythic-validator

# Status
sudo systemctl status mythic-validator

# Logs
journalctl -u mythic-validator -f

# Stop
sudo systemctl stop mythic-validator
```

## Register On-Chain

After your validator syncs and catches up:

```bash
# 1. Fund identity
solana transfer $(solana-keygen pubkey /etc/mythic/validator-identity.json) 10 \
  --url https://rpc.mythic.sh

# 2. Create vote account
solana create-vote-account /etc/mythic/vote-account.json \
  /etc/mythic/validator-identity.json \
  $(solana-keygen pubkey /etc/mythic/validator-identity.json) \
  --url https://rpc.mythic.sh

# 3. Verify
solana validators --url https://rpc.mythic.sh
```

## Mythic CLI

Install the Mythic CLI for easy management:

```bash
curl -sSf mythic.sh/cli | bash
```

Then:

```bash
mythic validator status     # Check node + network
mythic validator claim      # Claim rewards
mythic supply               # MYTH supply stats
mythic fee info             # Fee and burn stats
```

## Rewards

- **Fee split:** 50% validators / 10% foundation / 40% burned
- **AI bonus:** 2x multiplier for AI-capable validators (see [mythic-ai-validator](https://github.com/MythicFoundation/mythic-ai-validator))
- Rewards distributed per-epoch via the Mythic staking program

## Security

- Back up your keys immediately after installation
- Keys are stored at `/etc/mythic/` with `600` permissions
- Consider using a hardware wallet for the authorized withdrawer
- Never share your `validator-identity.json` or `vote-account.json`

## License

[Business Source License 1.1](./LICENSE) — converts to MIT on February 1, 2028.
