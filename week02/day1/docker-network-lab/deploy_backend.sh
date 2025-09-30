#!/bin/bash

# Week 2 Day 1 Lab 1: 백엔드 서비스 구축 스크립트
# 사용법: ./deploy_backend.sh

echo "=== 백엔드 서비스 구축 시작 ==="

# Redis 캐시 서버 배포
echo "1. Redis 캐시 서버 배포 중..."
docker run -d \
  --name redis-cache \
  --network backend-net \
  --ip 172.20.2.10 \
  redis:7-alpine

# Redis 연결 테스트
echo "2. Redis 연결 테스트..."
sleep 5
docker exec redis-cache redis-cli ping
docker exec redis-cache redis-cli set test-key "Hello Redis"
docker exec redis-cache redis-cli get test-key

# API 서버 소스 코드 생성
echo "3. API 서버 소스 코드 생성 중..."

# Dockerfile 생성
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF

# package.json 생성
cat > package.json << 'EOF'
{
  "name": "api-server",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "mysql2": "^3.6.0",
    "redis": "^4.6.0"
  }
}
EOF

# API 서버 코드 생성
cat > server.js << 'EOF'
const express = require('express');
const mysql = require('mysql2/promise');
const redis = require('redis');

const app = express();
const port = 3000;

// Redis 클라이언트 설정
const redisClient = redis.createClient({
  host: 'redis-cache',
  port: 6379
});

// MySQL 연결 설정
const dbConfig = {
  host: 'mysql-db',
  user: 'appuser',
  password: 'apppass',
  database: 'webapp'
};

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    server: process.env.HOSTNAME || 'unknown'
  });
});

app.get('/users', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute('SELECT * FROM users');
    await connection.end();
    
    res.json({ 
      users: rows, 
      source: 'database',
      server: process.env.HOSTNAME || 'unknown'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`API server running on port ${port}`);
});
EOF

# API 서버 이미지 빌드
echo "4. API 서버 이미지 빌드 중..."
docker build -t api-server:latest .

# API 서버 인스턴스 2개 실행
echo "5. API 서버 인스턴스 배포 중..."
docker run -d \
  --name api-server-1 \
  --network backend-net \
  --ip 172.20.2.20 \
  api-server:latest

docker run -d \
  --name api-server-2 \
  --network backend-net \
  --ip 172.20.2.21 \
  api-server:latest

# API 서버들을 데이터베이스 네트워크에도 연결
echo "6. API 서버를 데이터베이스 네트워크에 연결 중..."
docker network connect database-net api-server-1
docker network connect database-net api-server-2

# 서비스 상태 확인
echo "7. 백엔드 서비스 상태 확인..."
sleep 10
echo "Redis 상태:"
docker exec redis-cache redis-cli ping

echo "API 서버 1 상태:"
docker exec api-server-1 curl -s http://localhost:3000/health

echo "API 서버 2 상태:"
docker exec api-server-2 curl -s http://localhost:3000/health

echo "=== 백엔드 서비스 구축 완료 ==="
echo ""
echo "배포된 백엔드 서비스:"
echo "- Redis 캐시: redis-cache (172.20.2.10:6379)"
echo "- API 서버 1: api-server-1 (172.20.2.20:3000)"
echo "- API 서버 2: api-server-2 (172.20.2.21:3000)"