# Redis 컨테이너 실행
docker run -d \
  --name redis-cache \
  --network backend-net \
  --ip 172.20.2.10 \
  redis:7-alpine

# Redis 연결 테스트
docker exec redis-cache redis-cli ping
docker exec redis-cache redis-cli set test-key "Hello Redis"
docker exec redis-cache redis-cli get test-key


# 간단한 API 서버 Dockerfile 생성
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
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/users', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute('SELECT * FROM users');
    await connection.end();
    
    res.json({ users: rows, source: 'database' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`API server running on port ${port}`);
});
EOF

# API 서버 이미지 빌드
docker build -t api-server:latest .

# API 서버 인스턴스 2개 실행 (충돌 방지)
echo "=== API 서버 실행 ==="

# 기존 API 서버 컨테이너 제거 (충돌 방지)
docker rm -f api-server-1 api-server-2 2>/dev/null || true

docker run -d \
  --name api-server-1 \
  --network backend-net \
  --ip 172.20.2.20 \
  api-server:latest

if [ $? -eq 0 ]; then
    echo "✓ api-server-1 실행 성공"
else
    echo "✗ api-server-1 실행 실패"
    exit 1
fi

docker run -d \
  --name api-server-2 \
  --network backend-net \
  --ip 172.20.2.21 \
  api-server:latest

if [ $? -eq 0 ]; then
    echo "✓ api-server-2 실행 성공"
else
    echo "✗ api-server-2 실행 실패"
    exit 1
fi

# API 서버들을 데이터베이스 네트워크에도 연결
docker network connect database-net api-server-1
docker network connect database-net api-server-2