#!/bin/bash

echo "=== Docker Lab 환경 완전 초기화 ==="

# 완전한 환경 초기화
echo "1. 모든 컨테이너 중지..."
docker stop $(docker ps -aq) 2>/dev/null || true

echo "2. 실습 관련 컨테이너 제거..."
docker rm -f mysql-db redis-cache api-server-1 api-server-2 load-balancer web-server 2>/dev/null || true

echo "3. 실습 관련 네트워크 제거..."
docker network rm frontend-net backend-net database-net 2>/dev/null || true

echo "4. 사용하지 않는 리소스 정리..."
docker container prune -f
docker network prune -f
docker image prune -f

echo "5. 현재 상태 확인..."
echo "=== 실행 중인 컨테이너 ==="
docker ps

echo "=== 사용 가능한 네트워크 ==="
docker network ls

echo "=== 초기화 완료 ==="