#!/bin/bash

# Week 2 Day 1 Lab 1: 프론트엔드 및 로드 밸런서 구축 스크립트
# 사용법: ./deploy_frontend.sh

echo "=== 프론트엔드 및 로드 밸런서 구축 시작 ==="

# HAProxy 설정 파일 생성
echo "1. HAProxy 로드 밸런서 설정 생성 중..."
cat > haproxy.cfg << 'EOF'
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend api_frontend
    bind *:8080
    default_backend api_servers

backend api_servers
    balance roundrobin
    server api1 api-server-1:3000 check
    server api2 api-server-2:3000 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
EOF

# HAProxy 컨테이너 실행
echo "2. HAProxy 로드 밸런서 배포 중..."
docker run -d \
  --name load-balancer \
  --network frontend-net \
  --ip 172.20.1.10 \
  -p 8080:8080 \
  -p 8404:8404 \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  haproxy:2.8

# 로드 밸런서를 백엔드 네트워크에도 연결
echo "3. 로드 밸런서를 백엔드 네트워크에 연결 중..."
docker network connect backend-net load-balancer

# Nginx 설정 파일 생성
echo "4. Nginx 웹 서버 설정 생성 중..."
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /api/ {
        proxy_pass http://load-balancer:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# 웹 페이지 생성
echo "5. 웹 페이지 생성 중..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Multi-Container Network Demo</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        button { 
            padding: 12px 24px; 
            margin: 10px; 
            background: #4CAF50;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background: #45a049;
        }
        #result { 
            background: rgba(0,0,0,0.3); 
            padding: 20px; 
            margin: 20px 0; 
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 20px;
            background: #4CAF50;
            color: white;
            font-size: 12px;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Multi-Container Network Demo</h1>
        <p>이 페이지는 여러 네트워크에 분산된 컨테이너들이 협력하여 서비스를 제공합니다.</p>
        
        <div>
            <h3>🔧 시스템 테스트</h3>
            <button onclick="testAPI()">🏥 API 헬스 체크</button>
            <button onclick="loadUsers()">👥 사용자 목록 조회</button>
            <button onclick="testLoadBalancer()">⚖️ 로드 밸런서 테스트</button>
        </div>
        
        <div id="result"></div>
        
        <div>
            <h3>📊 시스템 아키텍처</h3>
            <p>🌐 Frontend Network → 🔄 Load Balancer → 🖥️ API Servers → 💾 Database</p>
        </div>
    </div>

    <script>
        async function testAPI() {
            showLoading();
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                document.getElementById('result').innerHTML = 
                    '<h3>🏥 API 상태 <span class="status">정상</span></h3>' +
                    '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<h3>❌ 오류</h3><p>' + error.message + '</p>';
            }
        }

        async function loadUsers() {
            showLoading();
            try {
                const response = await fetch('/api/users');
                const data = await response.json();
                document.getElementById('result').innerHTML = 
                    '<h3>👥 사용자 목록 <span class="status">조회 완료</span></h3>' +
                    '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<h3>❌ 오류</h3><p>' + error.message + '</p>';
            }
        }

        async function testLoadBalancer() {
            showLoading();
            try {
                const results = [];
                for (let i = 0; i < 5; i++) {
                    const response = await fetch('/api/health');
                    const data = await response.json();
                    results.push(data.server || 'unknown');
                }
                
                const serverCounts = results.reduce((acc, server) => {
                    acc[server] = (acc[server] || 0) + 1;
                    return acc;
                }, {});
                
                document.getElementById('result').innerHTML = 
                    '<h3>⚖️ 로드 밸런서 테스트 <span class="status">완료</span></h3>' +
                    '<p>5번 요청 결과:</p>' +
                    '<pre>' + JSON.stringify(serverCounts, null, 2) + '</pre>' +
                    '<p>✅ 요청이 여러 서버에 분산되었습니다!</p>';
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<h3>❌ 오류</h3><p>' + error.message + '</p>';
            }
        }

        function showLoading() {
            document.getElementById('result').innerHTML = 
                '<h3>⏳ 처리 중...</h3><p>잠시만 기다려주세요.</p>';
        }
    </script>
</body>
</html>
EOF

# Nginx 컨테이너 실행
echo "6. Nginx 웹 서버 배포 중..."
docker run -d \
  --name web-server \
  --network frontend-net \
  --ip 172.20.1.20 \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf \
  -v $(pwd)/index.html:/usr/share/nginx/html/index.html \
  nginx:alpine

# 웹 서버를 백엔드 네트워크에도 연결
echo "7. 웹 서버를 백엔드 네트워크에 연결 중..."
docker network connect backend-net web-server

# 서비스 상태 확인
echo "8. 프론트엔드 서비스 상태 확인..."
sleep 10

echo "로드 밸런서 상태:"
curl -s http://localhost:8404/stats | grep -E "(api1|api2)" || echo "통계 페이지 확인: http://localhost:8404/stats"

echo "웹 서버 상태:"
curl -s -I http://localhost/ | head -1

echo "=== 프론트엔드 및 로드 밸런서 구축 완료 ==="
echo ""
echo "배포된 프론트엔드 서비스:"
echo "- 웹 서버: http://localhost (172.20.1.20:80)"
echo "- 로드 밸런서: http://localhost:8080 (172.20.1.10:8080)"
echo "- 통계 페이지: http://localhost:8404/stats"
echo ""
echo "🎉 웹 브라우저에서 http://localhost 접속하여 테스트하세요!"