const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 5000;

// 미들웨어
app.use(cors());
app.use(express.json());

// 데이터베이스 연결
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Redis 연결
const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});
redisClient.connect();

// 라우트
app.get('/api/health', async (req, res) => {
  try {
    const dbResult = await pool.query('SELECT NOW()');
    const redisResult = await redisClient.ping();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || '1.0.0',
      database: dbResult.rows[0].now,
      cache: redisResult === 'PONG' ? 'connected' : 'disconnected'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/users', async (req, res) => {
  try {
    // Redis 캐시 확인
    const cached = await redisClient.get('users');
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    // 데이터베이스에서 조회
    const result = await pool.query('SELECT * FROM users ORDER BY id');
    
    // Redis에 캐시 저장 (5분)
    await redisClient.setEx('users', 300, JSON.stringify(result.rows));
    
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});