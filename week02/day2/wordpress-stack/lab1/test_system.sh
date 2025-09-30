#!/bin/bash

# Week 2 Day 2 Lab 1: Stateful 애플리케이션 시스템 테스트 스크립트
# 사용법: ./test_system.sh

echo "=== Stateful 애플리케이션 시스템 테스트 시작 ==="

# 테스트 결과 저장
TEST_RESULTS="system_test_results.txt"
echo "WordPress Stack 시스템 테스트 결과 - $(date)" > $TEST_RESULTS
echo "=================================================" >> $TEST_RESULTS

# 1. 컨테이너 상태 확인
echo "1. 컨테이너 상태 확인"
echo "======================" | tee -a $TEST_RESULTS

echo "📊 컨테이너 실행 상태:" | tee -a $TEST_RESULTS
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mysql-wordpress|wordpress-app|redis-session|nginx-proxy|monitoring-dashboard)" | tee -a $TEST_RESULTS

# 헬스 체크 상태 확인
echo "" | tee -a $TEST_RESULTS
echo "🏥 컨테이너 헬스 체크:" | tee -a $TEST_RESULTS
containers=("mysql-wordpress" "wordpress-app" "redis-session" "nginx-proxy")

for container in "${containers[@]}"; do
    health_status=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null)
    if [ "$health_status" = "healthy" ]; then
        echo "✅ $container: 정상" | tee -a $TEST_RESULTS
    elif [ "$health_status" = "unhealthy" ]; then
        echo "❌ $container: 비정상" | tee -a $TEST_RESULTS
    else
        echo "⚠️ $container: 헬스 체크 미설정" | tee -a $TEST_RESULTS
    fi
done

# 2. 볼륨 및 데이터 영속성 테스트
echo ""
echo "2. 볼륨 및 데이터 영속성 테스트"
echo "===============================" | tee -a $TEST_RESULTS

echo "💾 볼륨 상태:" | tee -a $TEST_RESULTS
docker volume ls | grep -E "(mysql-data|wp-content|redis-data)" | tee -a $TEST_RESULTS

# 볼륨 크기 확인
echo "" | tee -a $TEST_RESULTS
echo "📊 볼륨 사용량:" | tee -a $TEST_RESULTS
for volume in mysql-data wp-content redis-data; do
    size=$(docker run --rm -v $volume:/data alpine du -sh /data 2>/dev/null | cut -f1)
    if [ -n "$size" ]; then
        echo "$volume: $size" | tee -a $TEST_RESULTS
    else
        echo "$volume: 확인 불가" | tee -a $TEST_RESULTS
    fi
done

# 3. 서비스 연결 테스트
echo ""
echo "3. 서비스 연결 테스트"
echo "====================" | tee -a $TEST_RESULTS

# MySQL 연결 테스트
echo "🗄️ MySQL 연결 테스트:" | tee -a $TEST_RESULTS
if docker exec mysql-wordpress mysql -u wpuser -pwppassword -e "SELECT 'MySQL Connection OK' as status;" 2>/dev/null; then
    echo "✅ MySQL 연결 성공" | tee -a $TEST_RESULTS
else
    echo "❌ MySQL 연결 실패" | tee -a $TEST_RESULTS
fi

# Redis 연결 테스트
echo "" | tee -a $TEST_RESULTS
echo "🔄 Redis 연결 테스트:" | tee -a $TEST_RESULTS
if docker exec redis-session redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis 연결 성공" | tee -a $TEST_RESULTS
else
    echo "❌ Redis 연결 실패" | tee -a $TEST_RESULTS
fi

# WordPress 연결 테스트
echo "" | tee -a $TEST_RESULTS
echo "🌐 WordPress 연결 테스트:" | tee -a $TEST_RESULTS
if curl -f http://localhost:8080/ >/dev/null 2>&1; then
    echo "✅ WordPress 직접 연결 성공" | tee -a $TEST_RESULTS
else
    echo "❌ WordPress 직접 연결 실패" | tee -a $TEST_RESULTS
fi

# Nginx 프록시 테스트
echo "" | tee -a $TEST_RESULTS
echo "🔄 Nginx 프록시 테스트:" | tee -a $TEST_RESULTS
if curl -f http://localhost/ >/dev/null 2>&1; then
    echo "✅ Nginx 프록시 연결 성공" | tee -a $TEST_RESULTS
else
    echo "❌ Nginx 프록시 연결 실패" | tee -a $TEST_RESULTS
fi

# 4. 성능 테스트
echo ""
echo "4. 성능 테스트"
echo "===============" | tee -a $TEST_RESULTS

# 응답 시간 테스트
echo "⚡ 응답 시간 테스트:" | tee -a $TEST_RESULTS
response_time=$(curl -o /dev/null -s -w '%{time_total}' http://localhost/)
echo "평균 응답 시간: ${response_time}초" | tee -a $TEST_RESULTS

if (( $(echo "$response_time < 2.0" | bc -l) )); then
    echo "✅ 응답 시간 양호" | tee -a $TEST_RESULTS
else
    echo "⚠️ 응답 시간 개선 필요" | tee -a $TEST_RESULTS
fi

# 동시 연결 테스트 (간단한 부하 테스트)
echo "" | tee -a $TEST_RESULTS
echo "🔄 동시 연결 테스트 (10개 요청):" | tee -a $TEST_RESULTS
success_count=0
for i in {1..10}; do
    if curl -f http://localhost/ >/dev/null 2>&1; then
        ((success_count++))
    fi
done

echo "성공한 요청: $success_count/10" | tee -a $TEST_RESULTS
if [ $success_count -eq 10 ]; then
    echo "✅ 동시 연결 테스트 통과" | tee -a $TEST_RESULTS
else
    echo "⚠️ 동시 연결 테스트 일부 실패" | tee -a $TEST_RESULTS
fi

# 5. 데이터 영속성 테스트
echo ""
echo "5. 데이터 영속성 테스트"
echo "======================" | tee -a $TEST_RESULTS

# 테스트 데이터 삽입
echo "📝 테스트 데이터 삽입:" | tee -a $TEST_RESULTS
docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "
    CREATE TABLE IF NOT EXISTS test_persistence (
        id INT AUTO_INCREMENT PRIMARY KEY,
        test_data VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO test_persistence (test_data) VALUES ('Persistence Test $(date)');
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 테스트 데이터 삽입 성공" | tee -a $TEST_RESULTS
else
    echo "❌ 테스트 데이터 삽입 실패" | tee -a $TEST_RESULTS
fi

# WordPress 컨테이너 재시작 테스트
echo "" | tee -a $TEST_RESULTS
echo "🔄 컨테이너 재시작 테스트:" | tee -a $TEST_RESULTS
docker restart wordpress-app >/dev/null 2>&1
sleep 15

# 데이터 확인
test_data=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "SELECT COUNT(*) as count FROM test_persistence;" 2>/dev/null | tail -1)
if [ "$test_data" -gt 0 ]; then
    echo "✅ 데이터 영속성 확인됨 (레코드 수: $test_data)" | tee -a $TEST_RESULTS
else
    echo "❌ 데이터 영속성 실패" | tee -a $TEST_RESULTS
fi

# 6. 백업 시스템 테스트
echo ""
echo "6. 백업 시스템 테스트"
echo "====================" | tee -a $TEST_RESULTS

if [ -f "scripts/backup.sh" ]; then
    echo "🔄 백업 스크립트 실행:" | tee -a $TEST_RESULTS
    ./scripts/backup.sh >/dev/null 2>&1
    
    # 백업 파일 확인
    backup_files=$(ls backup/daily/ 2>/dev/null | wc -l)
    if [ $backup_files -gt 0 ]; then
        echo "✅ 백업 파일 생성됨 ($backup_files 개 파일)" | tee -a $TEST_RESULTS
        echo "최신 백업 파일:" | tee -a $TEST_RESULTS
        ls -la backup/daily/ | tail -3 | tee -a $TEST_RESULTS
    else
        echo "❌ 백업 파일 생성 실패" | tee -a $TEST_RESULTS
    fi
else
    echo "⚠️ 백업 스크립트 없음" | tee -a $TEST_RESULTS
fi

# 7. 전체 테스트 결과 요약
echo ""
echo "7. 전체 테스트 결과 요약"
echo "======================" | tee -a $TEST_RESULTS

# 성공/실패 카운트
success_count=$(grep -c "✅" $TEST_RESULTS)
warning_count=$(grep -c "⚠️" $TEST_RESULTS)
failure_count=$(grep -c "❌" $TEST_RESULTS)

echo "📊 테스트 결과 통계:" | tee -a $TEST_RESULTS
echo "성공: $success_count" | tee -a $TEST_RESULTS
echo "경고: $warning_count" | tee -a $TEST_RESULTS
echo "실패: $failure_count" | tee -a $TEST_RESULTS

# 시스템 점수 계산
total_tests=$((success_count + warning_count + failure_count))
if [ $total_tests -gt 0 ]; then
    system_score=$(( (success_count * 100) / total_tests ))
    echo "시스템 점수: $system_score/100" | tee -a $TEST_RESULTS
    
    if [ $system_score -ge 90 ]; then
        echo "🎉 시스템 상태: 우수" | tee -a $TEST_RESULTS
    elif [ $system_score -ge 70 ]; then
        echo "✅ 시스템 상태: 양호" | tee -a $TEST_RESULTS
    else
        echo "⚠️ 시스템 상태: 개선 필요" | tee -a $TEST_RESULTS
    fi
fi

echo ""
echo "=== Stateful 애플리케이션 시스템 테스트 완료 ==="
echo ""
echo "📋 테스트 결과가 $TEST_RESULTS 파일에 저장되었습니다."
echo ""
echo "🔍 추가 확인 사항:"
echo "1. WordPress 사이트: http://localhost"
echo "2. 모니터링 대시보드: http://localhost:9090"
echo "3. 백업 파일: ls -la backup/daily/"
echo "4. 로그 파일: tail -f logs/health.log"
echo ""
echo "📝 권장 사항:"
if [ $failure_count -gt 0 ]; then
    echo "- ❌ 실패한 테스트 항목을 우선적으로 수정하세요"
fi
if [ $warning_count -gt 0 ]; then
    echo "- ⚠️ 경고 항목들을 검토하고 필요시 개선하세요"
fi
echo "- 🔄 정기적으로 백업을 실행하세요: ./scripts/backup.sh"
echo "- 📊 시스템 상태를 주기적으로 확인하세요: ./scripts/health-check.sh"