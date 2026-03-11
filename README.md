<p align="center">
  <img src="https://mythic.sh/brand/mythic-logo-green.svg" alt="Mythic" width="120" />
</p>

<h1 align="center">Mythic Validator</h1>

<p align="center">
  Run a validator node on <strong>Mythic L2</strong> — the AI-native blockchain built on Solana.<br/>
  Earn MYTH rewards for securing the network. AI-capable validators earn a <strong>2x multiplier</strong>.
</p>

<p align="center">
  <a href="https://mythic.sh/docs">Documentation</a> &middot;
  <a href="https://mythic.sh">Explorer</a> &middot;
  <a href="https://discord.gg/mythic">Discord</a> &middot;
  <a href="https://x.com/MythicL2">Twitter</a>
</p>

---

## Why Run a Mythic Validator?

| Benefit | Details |
|---------|---------|
| **Earn MYTH rewards** | Validators receive 50% of all network fees every epoch |
| **AI bonus multiplier** | GPU-enabled validators earn **2x** the base reward rate |
| **Secure the network** | Help operate the first AI-native L2 settlement layer on Solana |
| **Governance power** | Staked MYTH grants voting weight in protocol governance |
| **Early operator advantage** | Join during the network's growth phase for maximum rewards |

---

## Hardware Requirements

| Component | Minimum | Recommended | AI-Enhanced |
|-----------|---------|-------------|-------------|
| **CPU** | 8 cores | 16 cores | 32+ cores |
| **RAM** | 32 GB | 64 GB | 128 GB |
| **Storage** | 500 GB NVMe | 1 TB NVMe | 2 TB NVMe RAID0 |
| **GPU** | — | — | NVIDIA A100 / H100 |
| **Network** | 100 Mbps | 1 Gbps | 10 Gbps |
| **OS** | Ubuntu 22.04+ | Ubuntu 22.04+ | Ubuntu 22.04+ |

> Mythic L2 runs a modified Solana validator (Agave). Requirements are similar to running a Solana validator, plus GPU for AI workloads.

---

## Quick Start

Get a validator running in three steps:

```bash
# 1. Clone and run setup
git clone https://github.com/MythicFoundation/mythic-validator.git
cd mythic-validator
chmod +x setup.sh start-mainnet.sh start-testnet.sh scripts/*.sh
./setup.sh

# 2. Configure your node
cp .env.example .env
nano .env  # Set your identity keypair path, ports, etc.

# 3. Start the validator
./start-mainnet.sh
```

Your node will begin producing blocks and syncing with the Mythic L2 network.

---

## Detailed Setup Guide

### Prerequisites

- **OS:** Ubuntu 22.04 or later (Debian-based Linux)
- **User:** Non-root user with `sudo` access
- **Ports:** 8899 (RPC), 8900 (WebSocket), 9900 (Gossip), 10000 (TPU) must be accessible

### Step 1: Install Solana CLI

The setup script handles this automatically, but if you prefer manual installation:

```bash
# Install Solana CLI v3.0.15
sh -c "$(curl -sSfL https://release.anza.xyz/v3.0.15/install)"

# Add to PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo export PATH=/Users/raphaelcardona/.local/share/solana/install/active_release/bin:/Users/raphaelcardona/.opencode/bin:/Users/raphaelcardona/.local/bin:/opt/homebrew/opt/postgresql@14/bin:/Users/raphaelcardona/.nvm/versions/node/v25.2.1/bin:/Users/raphaelcardona/.local/share/solana/install/active_release/bin:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/debugCommand:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/copilotCli:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pmk/env/global/bin:/opt/homebrew/bin:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/debugCommand:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/copilotCli:/Users/raphaelcardona/.opencode/bin:/Users/raphaelcardona/.local/bin:/Users/raphaelcardona/.deno/bin:/opt/homebrew/opt/postgresql@14/bin:/Users/raphaelcardona/.nvm/versions/node/v25.2.1/bin:/Users/raphaelcardona/.local/share/solana/install/active_release/bin:/Users/raphaelcardona/.cargo/bin:/Users/raphaelcardona/.lmstudio/bin:/Users/raphaelcardona/Library/Python/3.9/bin:/Users/raphaelcardona/.vscode/extensions/ms-python.debugpy-2025.18.0-darwin-arm64/bundled/scripts/noConfigScripts:/Users/raphaelcardona/.lmstudio/bin:/Users/raphaelcardona/Library/Python/3.9/bin >> ~/.bashrc

# Verify
solana --version
# Expected: solana-cli 3.0.15
```

### Step 2: Install Rust & Build Tools

```bash
# Install Rust
curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Install build dependencies
sudo apt update && sudo apt install -y \
    build-essential pkg-config libssl-dev libudev-dev \
    llvm clang cmake protobuf-compiler
```

### Step 3: Build Programs from Source

Mythic L2 loads 11 BPF programs at genesis. You must build them from the `mythic-mainnet-beta` source:

```bash
# Clone the program source
git clone https://github.com/MythicL2/mythic-mainnet-beta.git
cd mythic-mainnet-beta

# Build all 11 programs (takes 5-15 minutes depending on hardware)
cargo build-sbf --force-tools-install

# Copy compiled programs to the validator directory
mkdir -p ../mythic-validator/programs
cp target/deploy/*.so ../mythic-validator/programs/
cd ..
```

Or use the included build script:

```bash
./scripts/build-programs.sh
```

After building, you should have these `.so` files in `./programs/`:

| Program | File | Address |
|---------|------|---------|
| Bridge (L1) | `mythic_bridge.so` | `MythBrdg11111111111111111111111111111111111` |
| Bridge (L2) | `mythic_bridge_l2.so` | `MythBrdgL2111111111111111111111111111111111` |
| AI Precompiles | `mythic_ai_precompiles.so` | `CT1yUSX8n5uid5PyrPYnoG5H6Pp2GoqYGEKmMehq3uWJ` |
| Compute Market | `mythic_compute_market.so` | `AVWSp12ji5yoiLeC9whJv5i34RGF5LZozQin6T58vaEh` |
| Settlement | `mythic_settlement.so` | `MythSett1ement11111111111111111111111111111` |
| MYTH Token | `mythic_token.so` | `MythToken1111111111111111111111111111111111` |
| Launchpad | `mythic_launchpad.so` | `MythPad111111111111111111111111111111111111` |
| Swap | `mythic_swap.so` | `MythSwap11111111111111111111111111111111111` |
| Staking | `mythic_staking.so` | `MythStak11111111111111111111111111111111111` |
| Governance | `mythic_governance.so` | `MythGov111111111111111111111111111111111111` |
| Airdrop | `mythic_airdrop.so` | `MythDrop11111111111111111111111111111111111` |

### Step 4: Generate Validator Identity

```bash
# Generate a new validator keypair
solana-keygen new -o ./keys/validator-identity.json

# Save your pubkey — you will need it for staking registration
solana-keygen pubkey ./keys/validator-identity.json
```

> **Important:** Back up `./keys/validator-identity.json` securely. This is your validator's identity. Losing it means losing your staking position and accumulated rewards.

### Step 5: Configure

```bash
cp .env.example .env
```

Edit `.env` with your preferred settings:

```bash
# Required
VALIDATOR_IDENTITY=./keys/validator-identity.json

# Optional — defaults are fine for most setups
LEDGER_DIR=./ledger
PROGRAMS_DIR=./programs
RPC_PORT=8899
WS_PORT=8900
GOSSIP_PORT=9900
```

### Step 6: Configure Firewall

```bash
sudo ufw allow 8899/tcp   # RPC
sudo ufw allow 8900/tcp   # WebSocket
sudo ufw allow 9900/tcp   # Gossip
sudo ufw allow 10000/tcp  # TPU
sudo ufw enable
```

### Step 7: Start the Validator

```bash
# Foreground (for initial testing)
./start-mainnet.sh

# Or run with PM2 for production uptime
pm2 start start-mainnet.sh --name mythic-validator
pm2 save
pm2 startup
```

### Step 8: Verify Your Node

```bash
# Check if RPC is responding
curl -s http://localhost:8899 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .

# Check slot height
solana slot --url http://localhost:8899

# Run the health check script
./scripts/health-check.sh
```

---

## Register for Staking Rewards

After your validator is running and synced, register it with the Mythic staking program to begin earning MYTH rewards.

### Requirements

- Validator must be online and producing blocks
- Minimum stake: **10,000 MYTH**
- MYTH tokens in your validator wallet

### Register

```bash
./scripts/register-validator.sh
```

This script will:
1. Derive your validator's staking PDA
2. Submit a `RegisterValidator` transaction to the staking program
3. Confirm registration on-chain

### Staking Rewards Breakdown

All MYTH fees collected by the network are distributed as follows:

| Recipient | Share | Description |
|-----------|-------|-------------|
| **Validators** | 50% | Split proportionally by stake weight |
| **Burn** | 40% | Permanently removed from supply (deflationary) |
| **Foundation** | 10% | Protocol development and grants |

- **Epoch length:** 432,000 slots (~5 days at 400ms/slot)
- **AI multiplier:** Validators with `ai_capable=true` earn **2x** the base rate
- Fee types: gas, compute, inference, bridge, and subnet fees

---

## AI Validator Setup

AI-capable validators run GPU inference workloads for the network and earn a 2x reward multiplier.

### Additional Requirements

- NVIDIA GPU with 40GB+ VRAM (A100, H100, or equivalent)
- CUDA Toolkit 12.0+
- 128 GB+ system RAM

### Install CUDA Toolkit

```bash
# Add NVIDIA repository
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

# Install CUDA toolkit
sudo apt install -y cuda-toolkit-12-4

# Add to PATH
echo export PATH=/usr/local/cuda/bin:/Users/raphaelcardona/.opencode/bin:/Users/raphaelcardona/.local/bin:/opt/homebrew/opt/postgresql@14/bin:/Users/raphaelcardona/.nvm/versions/node/v25.2.1/bin:/Users/raphaelcardona/.local/share/solana/install/active_release/bin:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/debugCommand:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/copilotCli:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pmk/env/global/bin:/opt/homebrew/bin:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/debugCommand:/Users/raphaelcardona/Library/Application Support/Code/User/globalStorage/github.copilot-chat/copilotCli:/Users/raphaelcardona/.opencode/bin:/Users/raphaelcardona/.local/bin:/Users/raphaelcardona/.deno/bin:/opt/homebrew/opt/postgresql@14/bin:/Users/raphaelcardona/.nvm/versions/node/v25.2.1/bin:/Users/raphaelcardona/.local/share/solana/install/active_release/bin:/Users/raphaelcardona/.cargo/bin:/Users/raphaelcardona/.lmstudio/bin:/Users/raphaelcardona/Library/Python/3.9/bin:/Users/raphaelcardona/.vscode/extensions/ms-python.debugpy-2025.18.0-darwin-arm64/bundled/scripts/noConfigScripts:/Users/raphaelcardona/.lmstudio/bin:/Users/raphaelcardona/Library/Python/3.9/bin >> ~/.bashrc
echo export LD_LIBRARY_PATH=/usr/local/cuda/lib64: >> ~/.bashrc
source ~/.bashrc

# Verify
nvidia-smi
nvcc --version
```

### Enable AI Mode

In your `.env` file:

```bash
AI_CAPABLE=true
GPU_DEVICE=0          # GPU device index
GPU_MEMORY_LIMIT=38   # GB of VRAM to allocate
```

When your validator registers with `AI_CAPABLE=true`, the staking program sets `ai_capable=true` on your validator PDA, which activates the 2x reward multiplier.

### Verify AI Registration

```bash
# Check your validator PDA for ai_capable flag
solana account $(./scripts/register-validator.sh --derive-pda) \
  --url http://localhost:8899 \
  --output json | jq .
```

---

## Testnet

Run a local testnet node for development and testing:

```bash
./start-testnet.sh
```

Testnet differences:
- **Port:** 8999 (RPC), 9100 (Gossip), 9901 (Faucet)
- **Faucet:** Enabled — request up to 1,000,000 SOL
- **Tick rate:** 8 ticks/slot (faster block times for testing)
- **Same programs:** All 11 programs loaded at genesis

Request testnet SOL:

```bash
solana airdrop 100 --url http://localhost:8999
```

---

## Network Information

| Property | Value |
|----------|-------|
| **Network** | Mythic L2 (Solana-based) |
| **Consensus** | Proof of Stake with AI multiplier |
| **Block time** | ~400ms (64 ticks/slot) |
| **Epoch length** | 432,000 slots (~5 days) |
| **Native token** | SOL (gas) + MYTH (governance/staking) |
| **RPC endpoint** | `https://mythic.sh` (public) |
| **Explorer** | [mythic.sh](https://mythic.sh) |
| **DEX** | [mythicswap.app](https://mythicswap.app) |
| **Launchpad** | [mythic.money](https://mythic.money) |
| **Governance** | [mythic.foundation](https://mythic.foundation) |

### Program Addresses

```
MythBrdg11111111111111111111111111111111111   Bridge (L1)
MythBrdgL2111111111111111111111111111111111   Bridge (L2)
CT1yUSX8n5uid5PyrPYnoG5H6Pp2GoqYGEKmMehq3uWJ   AI Precompiles
AVWSp12ji5yoiLeC9whJv5i34RGF5LZozQin6T58vaEh   Compute Market
MythSett1ement11111111111111111111111111111   Settlement
MythToken1111111111111111111111111111111111   MYTH Token
MythPad111111111111111111111111111111111111   Launchpad
MythSwap11111111111111111111111111111111111   Swap
MythStak11111111111111111111111111111111111   Staking
MythGov111111111111111111111111111111111111   Governance
MythDrop11111111111111111111111111111111111   Airdrop
```

### Token Mints (L2)

```
7sfazeMxmuoDkuU5fHkDGin8uYuaTkZrRSwJM1CHXvDq   MYTH (6 decimals)
FEJa8wGyhXu9Hic1jNTg76Atb57C7jFkmDyDTQZkVwy3   wSOL (9 decimals)
6QTVHn4TUPQSpCH1uGmAK1Vd6JhuSEeKMKSi1F1SZMN   USDC (6 decimals)
8Go32n5Pv4HYdML9DNr8ePh4UHunqS9ZgjKMurz1vPSw   wBTC (8 decimals)
4zmzPzkexJRCVKSrYCHpmP8TVX6kMobjiFu8dVKtuXGT   wETH (8 decimals)
```

---

## Monitoring & Health

### Health Check Script

```bash
./scripts/health-check.sh
```

This checks:
- RPC endpoint responsiveness
- Current slot height and progress
- Transaction throughput
- Program deployment status (all 11 programs)
- Disk usage and system resources

### Manual Checks

```bash
# Current slot
solana slot --url http://localhost:8899

# Cluster info
solana cluster-version --url http://localhost:8899

# Transaction count
solana transaction-count --url http://localhost:8899

# Check a specific program
solana program show MythToken1111111111111111111111111111111111 --url http://localhost:8899
```

### Log Monitoring

```bash
# If running with PM2
pm2 logs mythic-validator

# Or tail the log file directly
tail -f ./ledger/validator.log
```

---

## Troubleshooting

### Validator won't start

**Problem:** `Error: failed to start validator`
```bash
# Check if port is already in use
sudo lsof -i :8899
# Kill existing process if needed
kill -9 <PID>

# Or check if another validator is running
pgrep -f solana-test-validator
```

**Problem:** `Error: BPF program file not found`
```bash
# Rebuild programs
./scripts/build-programs.sh

# Verify all .so files exist
ls -la ./programs/*.so
```

### Node falls behind

```bash
# Check sync status
solana catchup --url http://localhost:8899

# If severely behind, consider resetting ledger
rm -rf ./ledger
./start-mainnet.sh
```

### Out of disk space

```bash
# Check disk usage
df -h

# The ledger is limited to 50M shreds by default
# Reduce if needed in .env:
# LEDGER_SIZE=25000000
```

### Build failures

**Problem:** `cargo build-sbf` fails with blake3 errors
```bash
# Pin blake3 version in Cargo.toml
# [workspace.dependencies]
# blake3 = ">=1.3, <1.8"
```

**Problem:** `getrandom` compilation error
```bash
# Add to workspace Cargo.toml:
# getrandom = { version = "0.2", features = ["custom"] }
```

### RPC not accessible remotely

```bash
# Check firewall
sudo ufw status

# Ensure ports are open
sudo ufw allow 8899/tcp
sudo ufw allow 8900/tcp
sudo ufw allow 9900/tcp
```

---

## Running with systemd

For production deployments, you can use systemd instead of PM2:

```bash
sudo tee /etc/systemd/system/mythic-validator.service > /dev/null << EOF
[Unit]
Description=Mythic L2 Validator
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/start-mainnet.sh
Restart=always
RestartSec=10
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mythic-validator
sudo systemctl start mythic-validator

# Check status
sudo systemctl status mythic-validator
journalctl -u mythic-validator -f
```

---

## Directory Structure

```
mythic-validator/
├── README.md               # This file
├── LICENSE                  # BUSL-1.1 license
├── .env.example             # Configuration template
├── .gitignore               # Git ignore rules
├── setup.sh                 # One-click setup script
├── start-mainnet.sh         # Production validator launcher
├── start-testnet.sh         # Testnet validator launcher
├── scripts/
│   ├── build-programs.sh    # Build all 11 BPF programs from source
│   ├── health-check.sh      # Validator health monitoring
│   └── register-validator.sh # Register for staking rewards
├── keys/                    # Validator keypairs (gitignored)
├── ledger/                  # Validator ledger data (gitignored)
└── programs/                # Compiled .so files (gitignored)
```

---

## Contributing

Mythic is built by the community, for the community. We welcome contributions:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m "Add improvement"`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

For protocol-level changes, please discuss in [Discord](https://discord.gg/mythic) first.

---

## License

This project is licensed under the [Business Source License 1.1](LICENSE).

The licensed work is the Mythic L2 validator software. The licensor is Mythic Labs.
The change date is February 25, 2030. On the change date, the software will convert
to the Apache 2.0 license.

---

<p align="center">
  Built by <a href="https://mythiclabs.io">Mythic Labs</a> &middot;
  <a href="https://mythic.sh">mythic.sh</a> &middot;
  <a href="https://x.com/MythicL2">@MythicL2</a>
</p>
