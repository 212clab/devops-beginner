#!/bin/bash

# Week 2 Day 2 Lab 1: MariaDB 데이터베이스 구축 스크립트 (MySQL 호환)
# 사용법: ./setup_database.sh

echo "=== MariaDB 데이터베이스 구축 시작 ==="

# 기존 컨테이너 및 손상된 볼륨 완전 정리
echo "0. 기존 컨테이너 및 볼륨 정리 중..."
docker stop mysql-wordpress 2>/dev/null || true
docker rm mysql-wordpress 2>/dev/null || true
# 손상된 볼륨 제거
docker volume rm mysql-data mysql-config 2>/dev/null || true

# 네트워크 생성
echo "1. WordPress 네트워크 생성 중..."
docker network create wordpress-net 2>/dev/null || echo "네트워크 이미 존재"

# MariaDB 데이터 볼륨 생성
echo "2. MariaDB 볼륨 생성 중..."
docker volume create mysql-data
docker volume create mysql-config

# 간단한 설정으로 시작 (복잡한 설정 파일 제거)
echo "3. 간단한 MariaDB 설정으로 시작..."

# MariaDB 컨테이너 실행 (MySQL 완전 호환)
echo "4. MariaDB 컨테이너 실행 중..."
docker run -d \
  --name mysql-wordpress \
  --network wordpress-net \
  --restart=unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wppassword \
  -v mysql-data:/var/lib/mysql \
  --memory=256m \
  --health-cmd="mysqladmin ping -h localhost -u root -prootpassword" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  mariadb:10.6

# 컨테이너 상태 확인 및 대기
echo "5. 컨테이너 상태 확인 중..."
for i in {1..20}; do
  container_status=$(docker inspect mysql-wordpress --format='{{.State.Status}}' 2>/dev/null)
  echo "⏳ 컨테이너 상태 확인 ($i/20): $container_status"
  
  if [ "$container_status" = "running" ]; then
    echo "✅ 컨테이너 실행 중"
    break
  elif [ "$container_status" = "restarting" ]; then
    echo "🔄 컨테이너 재시작 중, 10초 대기..."
    sleep 10
  elif [ "$container_status" = "exited" ]; then
    echo "❌ 컨테이너 종료됨, 로그 확인:"
    docker logs mysql-wordpress --tail 30
    exit 1
  else
    echo "⏳ 컨테이너 시작 대기 중..."
    sleep 5
  fi
  
  if [ $i -eq 20 ]; then
    echo "❌ 컨테이너 시작 시간 초과"
    echo "최종 상태: $container_status"
    echo "컨테이너 로그:"
    docker logs mysql-wordpress --tail 30
    exit 1
  fi
done

# MariaDB 서비스 준비 대기
echo "6. MariaDB 서비스 준비 대기 중..."
for i in {1..15}; do
  echo "⏳ MariaDB 연결 시도 ($i/15)..."
  connection_result=$(docker exec mysql-wordpress mysql -u root -prootpassword -e "SELECT 1;" 2>&1)
  if [ $? -eq 0 ]; then
    echo "✅ MariaDB Root 연결 성공"
    break
  else
    echo "❌ 연결 실패: $connection_result"
    echo "5초 후 재시도..."
    sleep 5
  fi
  
  if [ $i -eq 15 ]; then
    echo "❌ MariaDB 연결 최종 실패"
    echo "컨테이너 로그 확인:"
    docker logs mysql-wordpress --tail 30
    exit 1
  fi
done

# MariaDB에서는 환경변수로 사용자가 자동 생성됨
echo "7. 자동 생성된 wpuser 확인 중..."
user_check=$(docker exec mysql-wordpress mysql -u root -prootpassword -e "SELECT User FROM mysql.user WHERE User='wpuser';" 2>&1)
if echo "$user_check" | grep -q wpuser; then
    echo "✅ wpuser 자동 생성 확인"
else
    echo "⚠️ wpuser 수동 생성 중..."
    echo "사용자 확인 결과: $user_check"
    create_result=$(docker exec mysql-wordpress mysql -u root -prootpassword -e "
    CREATE USER 'wpuser'@'%' IDENTIFIED BY 'wppassword';
    GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
    FLUSH PRIVILEGES;
    " 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ wpuser 수동 생성 완료"
    else
        echo "❌ wpuser 생성 실패: $create_result"
        exit 1
    fi
fi

# wpuser 연결 테스트
echo "8. wpuser 데이터베이스 연결 테스트..."
wpuser_test=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword -e "SHOW DATABASES;" 2>&1)
if [ $? -eq 0 ]; then
    echo "✅ wpuser 데이터베이스 연결 성공"
    echo "사용 가능한 데이터베이스:"
    echo "$wpuser_test"
else
    echo "❌ wpuser 데이터베이스 연결 실패"
    echo "에러 내용: $wpuser_test"
    echo "사용자 목록 확인:"
    docker exec mysql-wordpress mysql -u root -prootpassword -e "SELECT User, Host FROM mysql.user;"
    exit 1
fi

# 성능 설정 확인
echo "9. MariaDB 성능 설정 확인..."
docker exec mysql-wordpress mysql -u root -prootpassword -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

echo ""
echo "=== MariaDB 데이터베이스 구축 완료 ==="
echo ""
echo "MariaDB 데이터베이스 정보 (MySQL 완전 호환):"
echo "- 컨테이너명: mysql-wordpress"
echo "- 네트워크: wordpress-net"
echo "- 데이터베이스: wordpress"
echo "- 사용자: wpuser / 비밀번호: wppassword"
echo "- 루트 비밀번호: rootpassword"
echo "- 볼륨: mysql-data (데이터), mysql-config (설정)"
echo "- MariaDB 버전: 10.6 (MySQL 완전 호환)"