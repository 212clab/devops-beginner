#!/bin/bash

# Week 2 Day 2 Lab 1: Nginx 리버스 프록시 설정 스크립트
# 사용법: ./setup_nginx.sh

echo "=== Nginx 리버스 프록시 설정 시작 ==="

# 기존 컨테이너 정리
echo "0. 기존 컨테이너 정리 중..."
docker stop nginx-proxy 2>/dev/null || true
docker rm nginx-proxy 2>/dev/null || true

# Nginx 설정 디렉토리 생성
echo "1. Nginx 설정 파일 생성 중..."
mkdir -p config/nginx

# Nginx 설정 파일 생성
cat > config/nginx/nginx.conf << 'EOF'
upstream wordpress {
    server wordpress-app:80 max_fails=3 fail_timeout=30s;
}

# 캐시 설정
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=wordpress_cache:10m max_size=1g inactive=60m use_temp_path=off;

server {
    listen 80;
    server_name localhost;
    
    # 로그 설정
    access_log /var/log/nginx/wordpress.access.log;
    error_log /var/log/nginx/wordpress.error.log;
    
    # 보안 헤더
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip 압축
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # 정적 파일 캐싱 및 최적화
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        
        proxy_pass http://wordpress;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 캐시 설정
        proxy_cache wordpress_cache;
        proxy_cache_valid 200 1y;
        proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
    }
    
    # CSS, JS 파일 캐싱
    location ~* \.(css|js)$ {
        expires 1M;
        add_header Cache-Control "public";
        add_header Vary Accept-Encoding;
        
        proxy_pass http://wordpress;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 캐시 설정
        proxy_cache wordpress_cache;
        proxy_cache_valid 200 1M;
        proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
    }
    
    # WordPress 관리자 페이지 (캐시 제외)
    location ~* /wp-admin/ {
        proxy_pass http://wordpress;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 버퍼링 설정
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 타임아웃 설정
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # 동적 콘텐츠 (기본)
    location / {
        proxy_pass http://wordpress;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 버퍼링 설정
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 타임아웃 설정
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 페이지 캐시 (짧은 시간)
        proxy_cache wordpress_cache;
        proxy_cache_valid 200 5m;
        proxy_cache_bypass $http_pragma $http_authorization;
        proxy_no_cache $http_pragma $http_authorization;
        proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
        
        # 캐시 상태 헤더 추가
        add_header X-Cache-Status $upstream_cache_status;
    }
    
    # 헬스 체크
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Nginx 상태 페이지
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 172.0.0.0/8;
        deny all;
    }
    
    # 보안: 숨겨진 파일 접근 차단
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 보안: WordPress 설정 파일 접근 차단
    location ~* wp-config\.php {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Nginx 볼륨 생성
echo "2. Nginx 볼륨 생성 중..."
docker volume create nginx-logs
docker volume create nginx-cache

# Nginx 컨테이너 실행
echo "3. Nginx 리버스 프록시 실행 중..."
docker run -d \
  --name nginx-proxy \
  --network wordpress-net \
  --restart=unless-stopped \
  -p 80:80 \
  -v $(pwd)/config/nginx/nginx.conf:/etc/nginx/conf.d/default.conf \
  -v nginx-logs:/var/log/nginx \
  -v nginx-cache:/var/cache/nginx \
  --memory=128m \
  --health-cmd="curl -f http://localhost/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  nginx:alpine

# 서비스 시작 대기
echo "4. Nginx 서비스 시작 대기 중... (10초)"
sleep 10

# Nginx 연결 테스트
echo "5. Nginx 프록시 연결 테스트..."
if curl -f http://localhost/health >/dev/null 2>&1; then
    echo "✅ Nginx 리버스 프록시 정상 동작"
else
    echo "❌ Nginx 리버스 프록시 연결 실패"
fi

# WordPress 프록시 테스트
echo "6. WordPress 프록시 테스트..."
if curl -f http://localhost/ >/dev/null 2>&1; then
    echo "✅ WordPress 프록시 정상 동작"
else
    echo "❌ WordPress 프록시 연결 실패"
fi

echo ""
echo "=== Nginx 리버스 프록시 설정 완료 ==="
echo ""
echo "Nginx 프록시 정보:"
echo "- 메인 사이트: http://localhost"
echo "- 헬스 체크: http://localhost/health"
echo "- Nginx 상태: http://localhost/nginx_status"
echo ""
echo "성능 최적화 기능:"
echo "✅ 정적 파일 캐싱 (이미지: 1년, CSS/JS: 1개월)"
echo "✅ Gzip 압축 활성화"
echo "✅ 보안 헤더 적용"
echo "✅ 프록시 캐시 (페이지: 5분)"
echo ""
echo "🌐 브라우저에서 http://localhost 접속하여 확인하세요!"