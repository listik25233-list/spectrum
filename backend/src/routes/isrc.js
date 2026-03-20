const express = require('express');
const pool = require('../db/postgres');
const router = express.Router();

// GET /api/isrc/:isrc — lookup mapping
router.get('/:isrc', async (req, res) => {
    const { isrc } = req.params;
    try {
        const result = await pool.query(
            'SELECT * FROM isrc_mappings WHERE isrc = $1',
            [isrc.toUpperCase()]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });

        // Increment hit_count asynchronously
        pool.query(
            'UPDATE isrc_mappings SET hit_count = hit_count + 1 WHERE isrc = $1',
            [isrc.toUpperCase()]
        );

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /api/isrc/:isrc — upsert a mapping
router.put('/:isrc', async (req, res) => {
    const { isrc } = req.params;
    const { title, artist, spotify_id, apple_id, youtube_id, deezer_id, tidal_id } = req.body;

    try {
        await pool.query(`
      INSERT INTO isrc_mappings (isrc, title, artist, spotify_id, apple_id, youtube_id, deezer_id, tidal_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ON CONFLICT (isrc) DO UPDATE SET
        spotify_id  = COALESCE($4, isrc_mappings.spotify_id),
        apple_id    = COALESCE($5, isrc_mappings.apple_id),
        youtube_id  = COALESCE($6, isrc_mappings.youtube_id),
        deezer_id   = COALESCE($7, isrc_mappings.deezer_id),
        tidal_id    = COALESCE($8, isrc_mappings.tidal_id),
        hit_count   = isrc_mappings.hit_count + 1,
        verified_at = NOW()
    `, [isrc.toUpperCase(), title, artist, spotify_id, apple_id, youtube_id, deezer_id, tidal_id]);

        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
