import { FastifyInstance } from "fastify";
import { PublicKey } from "@solana/web3.js";
import { connection } from "../rpc";
import { cacheGet, cacheSet } from "../cache";

/**
 * Alias routes so the explorer frontend can use /blocks, /blocks/:slot,
 * /transactions/:signature, /accounts/:address, and /supply
 * without breaking the existing /slots, /slot/:slot, /tx/:sig, /account/:addr endpoints.
 */
export async function aliasRoutes(app: FastifyInstance) {

  // ───────────────────────────────────────────────
  //  GET /blocks  →  same logic as /slots
  // ───────────────────────────────────────────────
  app.get<{
    Querystring: { limit?: string; before?: string };
  }>("/blocks", async (req, reply) => {
    const limit = Math.min(parseInt(req.query.limit || "20", 10), 100);
    const beforeSlot = req.query.before
      ? parseInt(req.query.before, 10)
      : undefined;

    try {
      const currentSlot = beforeSlot ?? (await connection.getSlot());
      const startSlot = Math.max(0, currentSlot - limit + 1);
      const cacheKey = `blocks:${startSlot}:${currentSlot}`;

      const cached = cacheGet<unknown[]>(cacheKey);
      if (cached) return reply.send(cached);

      const blocks: unknown[] = [];

      for (let s = currentSlot; s >= startSlot && blocks.length < limit; s--) {
        try {
          const block = await connection.getBlock(s, {
            maxSupportedTransactionVersion: 0,
            transactionDetails: "full",
            rewards: false,
          });
          if (block) {
            blocks.push({
              slot: s,
              blockTime: block.blockTime,
              txCount: block.transactions.length,
              leader: null,
              hash: block.blockhash,
            });
          }
        } catch {
          // Slot may be skipped
        }
      }

      cacheSet(cacheKey, blocks);
      return reply.send(blocks);
    } catch (err) {
      app.log.error(err, "Failed to fetch blocks");
      return reply.status(500).send({ error: "Failed to fetch blocks" });
    }
  });

  // ───────────────────────────────────────────────
  //  GET /blocks/:slot  →  same logic as /slot/:slot
  // ───────────────────────────────────────────────
  app.get<{ Params: { slot: string } }>("/blocks/:slot", async (req, reply) => {
    const slot = parseInt(req.params.slot, 10);
    if (isNaN(slot)) {
      return reply.status(400).send({ error: "Invalid slot number" });
    }

    const cacheKey = `slot:${slot}`;
    const cached = cacheGet<unknown>(cacheKey);
    if (cached) return reply.send(cached);

    try {
      const block = await connection.getBlock(slot, {
        maxSupportedTransactionVersion: 0,
        transactionDetails: "full",
        rewards: false,
      });

      if (!block) {
        return reply.status(404).send({ error: "Block not found or skipped" });
      }

      const transactions = block.transactions.map((tx) => {
        const sig = tx.transaction.signatures[0];
        return {
          signature: sig,
          fee: tx.meta?.fee ?? 0,
          status: tx.meta?.err ? "failed" : "success",
          accounts: tx.transaction.message.getAccountKeys().staticAccountKeys.map(
            (k) => k.toBase58()
          ),
        };
      });

      const result = {
        slot,
        blockTime: block.blockTime,
        transactions,
        parentSlot: block.parentSlot,
        blockhash: block.blockhash,
      };

      cacheSet(cacheKey, result);
      return reply.send(result);
    } catch (err) {
      app.log.error(err, "Failed to fetch block");
      return reply.status(500).send({ error: "Failed to fetch block" });
    }
  });

  // ───────────────────────────────────────────────
  //  GET /transactions/:signature  →  same logic as /tx/:signature
  // ───────────────────────────────────────────────
  app.get<{ Params: { signature: string } }>(
    "/transactions/:signature",
    async (req, reply) => {
      const { signature } = req.params;

      const cacheKey = `tx:${signature}`;
      const cached = cacheGet<unknown>(cacheKey);
      if (cached) return reply.send(cached);

      try {
        const tx = await connection.getTransaction(signature, {
          maxSupportedTransactionVersion: 0,
        });

        if (!tx) {
          return reply.status(404).send({ error: "Transaction not found" });
        }

        const accounts = tx.transaction.message
          .getAccountKeys()
          .staticAccountKeys.map((k) => k.toBase58());

        const instructions = tx.transaction.message.compiledInstructions.map(
          (ix) => ({
            programId: accounts[ix.programIdIndex] || "unknown",
            accounts: ix.accountKeyIndexes.map((i) => accounts[i] || "unknown"),
            data: Buffer.from(ix.data).toString("base64"),
          })
        );

        const result = {
          signature,
          slot: tx.slot,
          blockTime: tx.blockTime,
          status: tx.meta?.err ? "failed" : "success",
          fee: tx.meta?.fee ?? 0,
          instructions,
          accounts,
          logs: tx.meta?.logMessages ?? [],
        };

        cacheSet(cacheKey, result, 60_000);
        return reply.send(result);
      } catch (err) {
        app.log.error(err, "Failed to fetch transaction");
        return reply.status(500).send({ error: "Failed to fetch transaction" });
      }
    }
  );

  // ───────────────────────────────────────────────
  //  GET /accounts/:address  →  same logic as /account/:address
  // ───────────────────────────────────────────────
  app.get<{ Params: { address: string } }>(
    "/accounts/:address",
    async (req, reply) => {
      const { address } = req.params;

      let pubkey: PublicKey;
      try {
        pubkey = new PublicKey(address);
      } catch {
        return reply.status(400).send({ error: "Invalid address" });
      }

      const cacheKey = `account:${address}`;
      const cached = cacheGet<unknown>(cacheKey);
      if (cached) return reply.send(cached);

      try {
        const info = await connection.getAccountInfo(pubkey);
        if (!info) {
          // Return a useful response for empty accounts (0 balance, system-owned)
          return reply.send({
            address,
            lamports: 0,
            owner: "11111111111111111111111111111111",
            executable: false,
            data: "",
            tokenAccounts: [],
          });
        }

        let tokenAccounts: unknown[] = [];
        try {
          const tokenProgramId = new PublicKey(
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
          );
          const tokens = await connection.getTokenAccountsByOwner(pubkey, {
            programId: tokenProgramId,
          });
          tokenAccounts = tokens.value.map((ta) => ({
            address: ta.pubkey.toBase58(),
            lamports: ta.account.lamports,
          }));
        } catch {
          // Token program may not exist on L2
        }

        const result = {
          address,
          lamports: info.lamports,
          owner: info.owner.toBase58(),
          executable: info.executable,
          data: info.data.length > 1024
            ? `<${info.data.length} bytes>`
            : info.data.toString("base64"),
          tokenAccounts,
        };

        cacheSet(cacheKey, result);
        return reply.send(result);
      } catch (err) {
        app.log.error(err, "Failed to fetch account");
        return reply.status(500).send({ error: "Failed to fetch account" });
      }
    }
  );

  // ───────────────────────────────────────────────
  //  GET /accounts/:address/transactions  →  alias
  // ───────────────────────────────────────────────
  app.get<{
    Params: { address: string };
    Querystring: { limit?: string; before?: string };
  }>("/accounts/:address/transactions", async (req, reply) => {
    const { address } = req.params;
    const limit = Math.min(parseInt(req.query.limit || "20", 10), 100);
    const before = req.query.before || undefined;

    let pubkey: PublicKey;
    try {
      pubkey = new PublicKey(address);
    } catch {
      return reply.status(400).send({ error: "Invalid address" });
    }

    const cacheKey = `account-txs:${address}:${limit}:${before || "latest"}`;
    const cached = cacheGet<unknown>(cacheKey);
    if (cached) return reply.send(cached);

    try {
      const sigs = await connection.getSignaturesForAddress(pubkey, {
        limit,
        before: before || undefined,
      });

      const txs = sigs.map((sig) => ({
        signature: sig.signature,
        slot: sig.slot,
        blockTime: sig.blockTime ?? null,
        status: sig.err ? "failed" : "success",
      }));

      cacheSet(cacheKey, txs);
      return reply.send(txs);
    } catch (err) {
      app.log.error(err, "Failed to fetch account transactions");
      return reply
        .status(500)
        .send({ error: "Failed to fetch account transactions" });
    }
  });

  // ───────────────────────────────────────────────
  //  GET /supply  →  MYTH token supply info
  // ───────────────────────────────────────────────
  app.get("/supply", async (_req, reply) => {
    const cached = cacheGet<unknown>("supply");
    if (cached) return reply.send(cached);

    try {
      // Get native (MYTH) supply
      const solSupply = await connection.getSupply();

      // Try to get MYTH token supply
      let mythSupply = {
        total: "0",
        circulating: "0",
        decimals: 9,
        mint: "7Hmyi9v4itEt49xo1fpTgHk1ytb8MZft7RBATBgb1pnf",
      };

      try {
        const mythMint = new PublicKey(
          "7Hmyi9v4itEt49xo1fpTgHk1ytb8MZft7RBATBgb1pnf"
        );
        const mintInfo = await connection.getAccountInfo(mythMint);
        if (mintInfo && mintInfo.data.length >= 82) {
          const supply = mintInfo.data.readBigUInt64LE(36);
          mythSupply.total = supply.toString();
          mythSupply.circulating = supply.toString();
        }
      } catch {
        // MYTH token may not be initialized
      }

      const result = {
        nativeSupply: {
          total: solSupply.value.total,
          circulating: solSupply.value.circulating,
          nonCirculating: solSupply.value.nonCirculating,
        },
        myth: mythSupply,
      };

      cacheSet("supply", result, 30_000);
      return reply.send(result);
    } catch (err) {
      app.log.error(err, "Failed to fetch supply");
      return reply.status(500).send({ error: "Failed to fetch supply" });
    }
  });
}
