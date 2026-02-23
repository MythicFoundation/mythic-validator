import dotenv from "dotenv";
dotenv.config();

export const config = {
  rpcUrl: process.env.L2_RPC_URL || "http://127.0.0.1:8899",
  port: parseInt(process.env.PORT || "4000", 10),
  cacheTtlMs: parseInt(process.env.CACHE_TTL_MS || "5000", 10),
  logLevel: process.env.LOG_LEVEL || "info",
  dbPath: process.env.DB_PATH || "./data/explorer-cache.db",
};

export const KNOWN_PROGRAMS: Record<string, string> = {
  // Bridge
  "oEQfREm4FQkaVeRoxJHkJLB1feHprrntY6eJuW2zbqQ": "Mythic Bridge L1",
  "3HsETxbcFZ5DnGiLWy3fEvpwQFzb2ThqLXY1eWQjjMLS": "Mythic Bridge L2",
  // DEX
  "HAqTmZbovDrPJP7Ry2httL9rL7hWE2GvJqjMUuxXfy1x": "MythicSwap AMM",
  // AI & Compute
  "Bs3NHs5ya2QDKtjKUqNoNjn1ggkJCxkccgbyPuRB1RQ2": "AI Precompiles",
  "F5DxeFteE3hfo8tMUysuTqvKe8HHTSNttSXZiao8uYc2": "Compute Market",
  // Settlement & Token
  "4TrowzShv4CrsuqZeUdLLVMdnDDkqkmnER1MZ5NsSaav": "Settlement",
  "7Hmyi9v4itEt49xo1fpTgHk1ytb8MZft7RBATBgb1pnf": "MYTH Token",
  // Launchpad
  "62dVNKTPhChmGVzQu7YzK19vVtTk371Zg7iHfNzk635c": "MythicPad Launchpad",
  // Governance
  "DMfUmyF8q3d7fC5D2S8wGqLy42fKvQPxmxFdosni1b5C": "Governance",
  // Staking
  "3J5rESPt79TyqkQ3cjBZCKNmVqBRYNHWEPKWg3dmW2wL": "Staking",
  // Airdrop
  "122JWwzZPxHHT4Argsfpbu8oKY1G62sYp57njywsaD5r": "Airdrop",
  // System Programs
  "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA": "SPL Token",
  "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL": "Associated Token Account",
};
