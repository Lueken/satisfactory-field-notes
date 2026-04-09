import express from "express";
import pg from "pg";
import { OAuth2Client } from "google-auth-library";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

const GOOGLE_CLIENT_ID =
  process.env.GOOGLE_CLIENT_ID ||
  "361744710738-o407ujuace2vcef2lh0nvbqu9rq6n2jv.apps.googleusercontent.com";
const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

// Postgres — Railway sets DATABASE_URL automatically
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

// Migrate: add user_id column if it doesn't exist
await pool.query(`
  CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY DEFAULT 1,
    data JSONB NOT NULL DEFAULT '{}'::jsonb
  )
`);
// Add user_id-based table for per-user data
await pool.query(`
  CREATE TABLE IF NOT EXISTS user_notes (
    user_id TEXT PRIMARY KEY,
    email TEXT,
    name TEXT,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )
`);

app.use(express.json());
app.use(express.static(join(__dirname, "dist")));

// Verify Google ID token, return user info
async function verifyToken(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing authorization header" });
  }
  const token = auth.slice(7);
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken: token,
      audience: GOOGLE_CLIENT_ID,
    });
    req.user = ticket.getPayload();
    next();
  } catch (e) {
    return res.status(401).json({ error: "Invalid token" });
  }
}

// Authenticated routes
app.get("/api/notes", verifyToken, async (req, res) => {
  const userId = req.user.sub;
  const { rows } = await pool.query(
    "SELECT data FROM user_notes WHERE user_id = $1",
    [userId]
  );
  res.json(rows[0]?.data ?? null);
});

app.put("/api/notes", verifyToken, async (req, res) => {
  const { sub: userId, email, name } = req.user;
  await pool.query(
    `INSERT INTO user_notes (user_id, email, name, data, updated_at)
     VALUES ($1, $2, $3, $4, NOW())
     ON CONFLICT (user_id) DO UPDATE
     SET data = EXCLUDED.data, email = EXCLUDED.email,
         name = EXCLUDED.name, updated_at = NOW()`,
    [userId, email, name, req.body]
  );
  res.sendStatus(200);
});

// Legacy unauthenticated routes (keep old single-row table working for web app)
app.get("/api/notes/legacy", async (_req, res) => {
  const { rows } = await pool.query("SELECT data FROM notes WHERE id = 1");
  res.json(rows[0]?.data ?? null);
});

app.put("/api/notes/legacy", async (req, res) => {
  await pool.query(
    `INSERT INTO notes (id, data) VALUES (1, $1)
     ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data`,
    [req.body]
  );
  res.sendStatus(200);
});

// SPA fallback
app.get("/{*splat}", (_req, res) => {
  res.sendFile(join(__dirname, "dist", "index.html"));
});

app.listen(PORT, () => {
  console.log(`listening on port ${PORT}`);
});
