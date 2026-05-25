const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

const pool = new Pool({
  host:     process.env.DB_HOST     || 'db',
  user:     process.env.DB_USER     || 'postgres',
  database: process.env.DB_NAME     || 'assofacdb',
  password: process.env.DB_PASSWORD || 'postgres',
  port:     5432,
});

app.get('/', (req, res) => {
  res.send('<h1>AssofacCloud App</h1><p>Node.js running in Docker!</p><a href="/test-db">Test DB</a>');
});

app.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time');
    res.send('<h1>Base de donnees connectee!</h1><p>Heure : ' + result.rows[0].current_time + '</p>');
  } catch (err) {
    res.status(500).send('Erreur DB : ' + err.message);
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', service: 'assofac-app' });
});

app.listen(port, () => {
  console.log('AssofacCloud App sur le port ' + port);
});