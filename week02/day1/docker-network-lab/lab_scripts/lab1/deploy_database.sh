# MySQL 컨테이너 실행
docker run -d \
  --name mysql-db \
  --network database-net \
  --ip 172.20.3.10 \
  -e MYSQL_ROOT_PASSWORD=secretpassword \
  -e MYSQL_DATABASE=webapp \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppass \
  mysql:8.0

# 데이터베이스 연결 테스트
sleep 30
docker exec mysql-db mysql -u root -psecretpassword -e "SHOW DATABASES;"