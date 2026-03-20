const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: false }
        : false,
});

const initDb = async () => {
    await pool.query(`
    CREATE TABLE IF NOT EXISTS isrc_mappings (
      isrc        VARCHAR(12) PRIMARY KEY,
      title       TEXT        NOT NULL,
      artist      TEXT        NOT NULL,
      spotify_id  VARCHAR(30),
      apple_id    VARCHAR(30),
      youtube_id  VARCHAR(30),
      deezer_id   VARCHAR(20),
      tidal_id    VARCHAR(20),
      hit_count   INTEGER     DEFAULT 1,
      verified_at TIMESTAMP   DEFAULT NOW()
    );
  `);
    console.log('Database initialized');
};

initDb().catch(console.error);

module.exports = pool;
