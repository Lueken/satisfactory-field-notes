import express from "express";
import pg from "pg";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

// Postgres — Railway sets DATABASE_URL automatically
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

// Create table on startup
await pool.query(`
  CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY DEFAULT 1,
    data JSONB NOT NULL DEFAULT '{}'::jsonb
  )
`);

app.use(express.json());
app.use(express.static(join(__dirname, "dist")));

app.get("/api/notes", async (_req, res) => {
  const { rows } = await pool.query("SELECT data FROM notes WHERE id = 1");
  res.json(rows[0]?.data ?? null);
});

app.put("/api/notes", async (req, res) => {
  await pool.query(
    `INSERT INTO notes (id, data) VALUES (1, $1)
     ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data`,
    [req.body]
  );
  res.sendStatus(200);
});

// SPA fallback
app.get("*", (_req, res) => {
  res.sendFile(join(__dirname, "dist", "index.html"));
});

app.listen(PORT, () => {
  console.log(`listening on port ${PORT}`);
});
