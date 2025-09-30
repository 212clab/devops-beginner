#!/bin/bash

# Week 2 Day 2 Lab 1: WordPress 애플리케이션 배포 스크립트
# 사용법: ./deploy_wordpress.sh

echo "=== WordPress 애플리케이션 배포 시작 ==="

# 기존 컨테이너 정리
echo "0. 기존 WordPress 컨테이너 정리 중..."
docker stop wordpress-app redis-session 2>/dev/null || true
docker rm wordpress-app redis-session 2>/dev/null || true

# WordPress 데이터 볼륨 생성
echo "1. WordPress 볼륨 생성 중..."
docker volume create wp-content
docker volume create redis-data

# Redis 세션 스토어 실행
echo "2. Redis 세션 스토어 실행 중..."
docker run -d \
  --name redis-session \
  --network wordpress-net \
  --restart=unless-stopped \
  -v redis-data:/data \
  --memory=128m \
  --health-cmd="redis-cli ping" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  redis:7-alpine redis-server --appendonly yes --maxmemory 100mb --maxmemory-policy allkeys-lru

# WordPress 컨테이너 실행
echo "3. WordPress 컨테이너 실행 중..."
docker run -d \
  --name wordpress-app \
  --network wordpress-net \
  --restart=unless-stopped \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=mysql-wordpress:3306 \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppassword \
  -v wp-content:/var/www/html/wp-content \
  --memory=256m \
  --health-cmd="curl -f http://localhost/ || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  wordpress:latest

# 서비스 시작 대기
echo "4. WordPress 서비스 시작 대기 중... (30초)"
sleep 30

# WordPress 연결 테스트
echo "5. WordPress 연결 테스트..."
for i in {1..10}; do
  if curl -f http://localhost:8080/ >/dev/null 2>&1; then
    echo "✅ WordPress 애플리케이션 정상 동작"
    break
  fi
  echo "⏳ WordPress 연결 시도 ($i/10)..."
  sleep 5
done

# Redis 연결 테스트
echo "6. Redis 세션 스토어 테스트..."
if docker exec redis-session redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis 세션 스토어 정상 동작"
else
    echo "❌ Redis 세션 스토어 연결 실패"
fi

echo ""
echo "=== WordPress 애플리케이션 배포 완료 ==="
echo ""
echo "배포된 서비스:"
echo "- WordPress: http://localhost:8080"
echo "- Redis 세션 스토어: redis-session:6379"
echo ""
echo "볼륨 정보:"
echo "- wp-content: WordPress 콘텐츠 파일"
echo "- redis-data: Redis 데이터"
echo ""
echo "🌐 브라우저에서 http://localhost:8080 접속하여 WordPress 설치를 완료하세요!"