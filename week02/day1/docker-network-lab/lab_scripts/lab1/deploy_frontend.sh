# HAProxy 설정 파일 생성
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
docker run -d \
  --name load-balancer \
  --network frontend-net \
  --ip 172.20.1.10 \
  -p 8080:8080 \
  -p 8404:8404 \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  haproxy:2.8

# 로드 밸런서를 백엔드 네트워크에도 연결
docker network connect backend-net load-balancer

# Nginx 설정 파일 생성
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    # 로그 설정 추가
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ =404;
    }

    location /api/ {
        # 로드 밸런서 IP 직접 사용 (WSL 환경에서 더 안정적)
        proxy_pass http://172.20.1.10:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 5s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
    }
    
    # 헬스 체크 엔드포인트
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# 간단한 웹 페이지 생성
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Multi-Container Network Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        button { padding: 10px 20px; margin: 10px; }
        #result { background: #f5f5f5; padding: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Multi-Container Network Demo</h1>
        <p>이 페이지는 여러 네트워크에 분산된 컨테이너들이 협력하여 서비스를 제공합니다.</p>
        
        <button onclick="testAPI()">API 테스트</button>
        <button onclick="loadUsers()">사용자 목록 조회</button>
        
        <div id="result"></div>
    </div>

    <script>
        async function testAPI() {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                document.getElementById('result').innerHTML = 
                    '<h3>API 상태</h3><pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<h3>오류</h3><p>' + error.message + '</p>';
            }
        }

        async function loadUsers() {
            try {
                const response = await fetch('/api/users');
                const data = await response.json();
                document.getElementById('result').innerHTML = 
                    '<h3>사용자 목록</h3><pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<h3>오류</h3><p>' + error.message + '</p>';
            }
        }
    </script>
</body>
</html>
EOF

# Nginx 컨테이너 실행
docker run -d \
  --name web-server \
  --network frontend-net \
  --ip 172.20.1.20 \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf \
  -v $(pwd)/index.html:/usr/share/nginx/html/index.html \
  nginx:alpine

# 웹 서버를 백엔드 네트워크에도 연결
docker network connect backend-net web-server

# 연결 확인 및 테스트
echo "=== 컨테이너 상태 확인 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "=== 네트워크 연결 확인 ==="
docker inspect web-server | grep -A 10 "Networks"

echo "=== 기본 연결 테스트 ==="
sleep 10  # 컨테이너 시작 대기 시간 증가

# 단계별 테스트
echo "1. Nginx 헬스 체크..."
curl -f http://localhost/health && echo "✓ Nginx 정상" || echo "✗ Nginx 연결 실패"

echo "2. 웹 페이지 로드..."
curl -f http://localhost/ > /dev/null && echo "✓ 웹 페이지 정상" || echo "✗ 웹 페이지 로드 실패"

echo "3. API 테스트..."
curl -f http://localhost/api/health && echo "✓ API 정상" || echo "✗ API 연결 실패"

echo "=== 전체 시스템 준비 완료 ==="
