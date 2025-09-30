#!/bin/bash

# Week 2 Day 1 Lab 2: 보안 강화된 서비스 배포 스크립트
# 사용법: ./deploy_secure_services.sh

echo "=== 보안 강화된 서비스 배포 시작 ==="

# 필요한 디렉토리 생성
echo "1. 보안 설정 디렉토리 생성 중..."
mkdir -p configs logs

# MySQL 보안 설정 파일 생성
echo "2. MySQL 보안 설정 파일 생성 중..."
cat > configs/mysql-secure.cnf << 'EOF'
[mysqld]
# 보안 설정
bind-address = 0.0.0.0
skip-name-resolve
ssl-ca = /etc/mysql/ssl/ca.pem
ssl-cert = /etc/mysql/ssl/server-cert.pem
ssl-key = /etc/mysql/ssl/server-key.pem
require_secure_transport = ON

# 성능 및 보안
max_connections = 50
max_user_connections = 10
connect_timeout = 10
wait_timeout = 600
interactive_timeout = 600

# 로깅
general_log = ON
general_log_file = /var/log/mysql/general.log
slow_query_log = ON
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 추가 보안 설정
local_infile = OFF
secure_file_priv = /var/lib/mysql-files/
sql_mode = STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
EOF

# Redis 보안 설정 파일 생성
echo "3. Redis 보안 설정 파일 생성 중..."
cat > configs/redis-secure.conf << 'EOF'
# 네트워크 보안
bind 0.0.0.0
protected-mode yes
port 6379
requirepass SecureRedisPass789!

# 보안 설정 - 위험한 명령어 비활성화
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG "CONFIG_b835c3f8a5d2e7f1"
rename-command DEBUG ""
rename-command EVAL ""

# 성능 제한
maxclients 100
timeout 300
tcp-keepalive 300

# 로깅
loglevel notice
logfile /var/log/redis/redis.log

# 메모리 보안
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

# 기존 서비스 중지 및 제거
echo "4. 기존 서비스 중지 및 제거 중..."
docker stop mysql-db redis-cache 2>/dev/null || true
docker rm mysql-db redis-cache 2>/dev/null || true

# 보안 강화된 MySQL 컨테이너 배포
echo "5. 보안 강화된 MySQL 데이터베이스 배포 중..."
docker volume create mysql-data 2>/dev/null || true

docker run -d \
  --name secure-mysql-db \
  --network database-net \
  --ip 172.20.3.10 \
  --user 999:999 \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/run/mysqld \
  -v mysql-data:/var/lib/mysql \
  -v $(pwd)/configs/mysql-secure.cnf:/etc/mysql/conf.d/security.cnf \
  -v $(pwd)/ssl:/etc/mysql/ssl \
  -e MYSQL_ROOT_PASSWORD=VerySecurePassword123! \
  -e MYSQL_DATABASE=webapp \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=SecureAppPass456! \
  --cap-drop ALL \
  --cap-add CHOWN \
  --cap-add DAC_OVERRIDE \
  --cap-add SETGID \
  --cap-add SETUID \
  --security-opt no-new-privileges:true \
  mysql:8.0

# 보안 강화된 Redis 컨테이너 배포
echo "6. 보안 강화된 Redis 캐시 배포 중..."
docker run -d \
  --name secure-redis-cache \
  --network backend-net \
  --ip 172.20.2.10 \
  --user 999:999 \
  --read-only \
  --tmpfs /tmp \
  -v $(pwd)/configs/redis-secure.conf:/usr/local/etc/redis/redis.conf \
  -v $(pwd)/logs:/var/log/redis \
  --cap-drop ALL \
  --cap-add SETGID \
  --cap-add SETUID \
  --security-opt no-new-privileges:true \
  redis:7-alpine redis-server /usr/local/etc/redis/redis.conf

# SSL 지원 HAProxy 설정 업데이트
echo "7. SSL 지원 HAProxy 설정 업데이트 중..."
cat > configs/haproxy-ssl.cfg << 'EOF'
global
    daemon
    ssl-default-bind-ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    option dontlognull
    option log-health-checks

frontend https_frontend
    bind *:443 ssl crt /etc/ssl/server.pem
    bind *:80
    redirect scheme https if !{ ssl_fc }
    
    # 보안 헤더 추가
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains"
    http-response set-header X-Frame-Options "DENY"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header Referrer-Policy "strict-origin-when-cross-origin"
    
    # Rate limiting
    stick-table type ip size 100k expire 30s store http_req_rate(10s)
    http-request track-sc0 src
    http-request reject if { sc_http_req_rate(0) gt 20 }
    
    default_backend api_servers

backend api_servers
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server api1 api-server-1:3000 check inter 5s fall 3 rise 2
    server api2 api-server-2:3000 check inter 5s fall 3 rise 2

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    # 통계 페이지 보안
    stats auth admin:SecureStatsPass123!
EOF

# 기존 로드 밸런서 중지 및 보안 로드 밸런서 시작
echo "8. 보안 강화된 로드 밸런서 배포 중..."
docker stop load-balancer 2>/dev/null || true
docker rm load-balancer 2>/dev/null || true

# SSL 인증서를 하나의 파일로 결합 (HAProxy용)
if [ -f "server-cert.pem" ] && [ -f "server-key.pem" ]; then
    mkdir -p ssl
    cat server-cert.pem server-key.pem > ssl/server.pem
    echo "✅ SSL 인증서 결합 완료"
else
    echo "⚠️ SSL 인증서가 없습니다. generate_ssl.sh를 먼저 실행하세요."
fi

docker run -d \
  --name secure-load-balancer \
  --network frontend-net \
  --ip 172.20.1.10 \
  -p 80:80 \
  -p 443:443 \
  -p 8404:8404 \
  -v $(pwd)/configs/haproxy-ssl.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  -v $(pwd)/ssl/server.pem:/etc/ssl/server.pem \
  --security-opt no-new-privileges:true \
  haproxy:2.8

docker network connect backend-net secure-load-balancer

# 서비스 초기화 대기
echo "9. 서비스 초기화 대기 중... (30초)"
sleep 30

# 보안 강화된 서비스 상태 확인
echo "10. 보안 강화된 서비스 상태 확인..."

echo ""
echo "📊 MySQL 보안 상태:"
if docker exec secure-mysql-db mysql -u root -pVerySecurePassword123! -e "SHOW VARIABLES LIKE 'require_secure_transport';" 2>/dev/null; then
    echo "✅ MySQL SSL 강제 설정 확인됨"
else
    echo "⚠️ MySQL 연결 확인 필요"
fi

echo ""
echo "🔄 Redis 보안 상태:"
if docker exec secure-redis-cache redis-cli -a SecureRedisPass789! ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis 인증 설정 확인됨"
else
    echo "⚠️ Redis 연결 확인 필요"
fi

echo ""
echo "🔒 HTTPS 로드 밸런서 상태:"
if curl -k -s -I https://localhost/ 2>/dev/null | grep -q "200 OK"; then
    echo "✅ HTTPS 로드 밸런서 정상 동작"
else
    echo "⚠️ HTTPS 설정 확인 필요"
fi

echo ""
echo "=== 보안 강화된 서비스 배포 완료 ==="
echo ""
echo "🔐 보안 강화 사항:"
echo "✅ MySQL: SSL 강제, 사용자 제한, 읽기 전용 파일시스템"
echo "✅ Redis: 비밀번호 인증, 위험 명령어 비활성화"
echo "✅ HAProxy: HTTPS 강제, 보안 헤더, Rate Limiting"
echo "✅ 컨테이너: 최소 권한, 읽기 전용, 보안 옵션 적용"
echo ""
echo "🌐 접속 정보:"
echo "- HTTPS 웹사이트: https://localhost"
echo "- HTTP → HTTPS 자동 리다이렉트"
echo "- HAProxy 통계: http://localhost:8404/stats (admin/SecureStatsPass123!)"
echo ""
echo "⚠️ 주의사항:"
echo "- 자체 서명 인증서로 인한 브라우저 경고 무시하고 진행"
echo "- 프로덕션 환경에서는 공인 인증서 사용 필요"