#!/bin/bash

# Week 2 Day 1 Lab 1: 데이터베이스 계층 구축 스크립트
# 사용법: ./deploy_database.sh

echo "=== 데이터베이스 계층 구축 시작 ==="

# MySQL 데이터베이스 배포
echo "1. MySQL 컨테이너 실행 중..."
docker run -d \
  --name mysql-db \
  --network database-net \
  --ip 172.20.3.10 \
  -e MYSQL_ROOT_PASSWORD=secretpassword \
  -e MYSQL_DATABASE=webapp \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppass \
  mysql:8.0

# 데이터베이스 초기화 대기
echo "2. 데이터베이스 초기화 대기 중... (30초)"
sleep 30

# 데이터베이스 연결 테스트
echo "3. 데이터베이스 연결 테스트..."
docker exec mysql-db mysql -u root -psecretpassword -e "SHOW DATABASES;"

# 샘플 데이터 생성
echo "4. 샘플 데이터 생성 중..."
docker exec mysql-db mysql -u root -psecretpassword webapp << 'EOF'
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
('Alice', 'alice@example.com'),
('Bob', 'bob@example.com'),
('Charlie', 'charlie@example.com');

SELECT * FROM users;
EOF

echo "=== 데이터베이스 계층 구축 완료 ==="
echo ""
echo "MySQL 데이터베이스 정보:"
echo "- 컨테이너명: mysql-db"
echo "- IP 주소: 172.20.3.10"
echo "- 데이터베이스: webapp"
echo "- 사용자: appuser / 비밀번호: apppass"