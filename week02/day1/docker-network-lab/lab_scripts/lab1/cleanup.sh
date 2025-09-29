# 작업 디렉토리 생성
mkdir -p ~/docker-network-lab
cd ~/docker-network-lab

# 완전한 환경 초기화
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f mysql-db redis-cache api-server-1 api-server-2 load-balancer web-server 2>/dev/null || true
docker network rm frontend-net backend-net database-net 2>/dev/null || true
docker container prune -f
docker network prune -f
docker image prune -f

echo "=== 초기화 완료 ==="
docker ps
docker network ls