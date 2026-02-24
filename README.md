# Mythic Explorer API

REST API backend for the Mythic L2 block explorer. Indexes blocks, transactions, and accounts from the Mythic L2 validator and serves them via a fast HTTP API.

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/blocks` | Recent blocks |
| `GET /api/blocks/:slot` | Block detail by slot |
| `GET /api/transactions` | Recent transactions |
| `GET /api/transactions/:sig` | Transaction detail by signature |
| `GET /api/accounts/:address` | Account info and token balances |
| `GET /api/stats` | Network statistics (TPS, slot, supply) |
| `GET /api/validators` | Active validator list |

## Tech Stack

- **Runtime**: Node.js + TypeScript + Express
- **Data Source**: Solana web3.js direct RPC calls to Mythic L2 validator

## Live

- **API**: `https://api.mythic.sh` (port 4000)

## Setup

```bash
npm install
npm run build
npm start
```

## License

Proprietary - Mythic Labs
