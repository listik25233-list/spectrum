require('dotenv').config();
const express = require('express');
const cors = require('cors');
const isrcRoutes = require('./routes/isrc');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use('/api/isrc', isrcRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`Spectrum backend running on port ${PORT}`);
});
