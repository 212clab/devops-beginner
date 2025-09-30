#!/bin/bash

# Week 2 Day 1 Lab 2: 보안 테스트 및 검증 스크립트
# 사용법: ./security_test.sh

echo "=== 보안 테스트 및 검증 시작 ==="

# 테스트 결과 저장
TEST_RESULTS="security_test_results.txt"
echo "보안 테스트 결과 - $(date)" > $TEST_RESULTS
echo "=================================" >> $TEST_RESULTS

# 1. 포트 스캔 테스트
echo "1. 포트 스캔 테스트 실행 중..."
echo "" | tee -a $TEST_RESULTS
echo "1. 포트 스캔 테스트" | tee -a $TEST_RESULTS
echo "===================" | tee -a $TEST_RESULTS

# nmap을 사용한 포트 스캔 (설치되어 있는 경우)
if command -v nmap &> /dev/null; then
    echo "🔍 Nmap 포트 스캔 결과:" | tee -a $TEST_RESULTS
    nmap -sS -O localhost 2>/dev/null | grep -E "(open|filtered|closed)" | tee -a $TEST_RESULTS
else
    echo "⚠️ Nmap이 설치되지 않음. 기본 포트 테스트 실행..." | tee -a $TEST_RESULTS
    
    # 기본 포트 연결 테스트
    for port in 22 80 443 3306 6379 8080 8404 8888; do
        if timeout 3 nc -zv localhost $port 2>&1 | grep -q "succeeded"; then
            echo "포트 $port: 열림" | tee -a $TEST_RESULTS
        else
            echo "포트 $port: 닫힘/필터링됨" | tee -a $TEST_RESULTS
        fi
    done
fi

# 2. 웹 애플리케이션 보안 테스트
echo ""
echo "2. 웹 애플리케이션 보안 테스트 실행 중..."
echo "" | tee -a $TEST_RESULTS
echo "2. 웹 애플리케이션 보안 테스트" | tee -a $TEST_RESULTS
echo "===============================" | tee -a $TEST_RESULTS

# HTTPS 강제 리다이렉트 테스트
echo "🔒 HTTPS 리다이렉트 테스트:" | tee -a $TEST_RESULTS
http_response=$(curl -s -I http://localhost/ | head -1)
if echo "$http_response" | grep -q "301\|302"; then
    echo "✅ HTTP → HTTPS 리다이렉트 정상 동작" | tee -a $TEST_RESULTS
else
    echo "❌ HTTPS 리다이렉트 실패: $http_response" | tee -a $TEST_RESULTS
fi

# 보안 헤더 테스트
echo "" | tee -a $TEST_RESULTS
echo "🛡️ 보안 헤더 테스트:" | tee -a $TEST_RESULTS
headers=$(curl -k -s -I https://localhost/ 2>/dev/null)

security_headers=("Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options" "X-XSS-Protection")
for header in "${security_headers[@]}"; do
    if echo "$headers" | grep -qi "$header"; then
        echo "✅ $header 헤더 존재" | tee -a $TEST_RESULTS
    else
        echo "❌ $header 헤더 누락" | tee -a $TEST_RESULTS
    fi
done

# SQL 인젝션 시도 테스트
echo "" | tee -a $TEST_RESULTS
echo "💉 SQL 인젝션 테스트:" | tee -a $TEST_RESULTS
sql_payloads=(
    "1' OR '1'='1"
    "'; DROP TABLE users; --"
    "1 UNION SELECT * FROM information_schema.tables"
)

for payload in "${sql_payloads[@]}"; do
    response=$(curl -k -s "https://localhost/api/users?id=$payload" 2>/dev/null)
    if echo "$response" | grep -qi "error\|syntax"; then
        echo "✅ SQL 인젝션 차단됨: $payload" | tee -a $TEST_RESULTS
    else
        echo "⚠️ SQL 인젝션 응답: $payload" | tee -a $TEST_RESULTS
    fi
done

# XSS 시도 테스트
echo "" | tee -a $TEST_RESULTS
echo "🚨 XSS 테스트:" | tee -a $TEST_RESULTS
xss_payloads=(
    "<script>alert('xss')</script>"
    "javascript:alert('xss')"
    "<img src=x onerror=alert('xss')>"
)

for payload in "${xss_payloads[@]}"; do
    response=$(curl -k -s "https://localhost/api/users?name=$payload" 2>/dev/null)
    if echo "$response" | grep -q "<script>\|javascript:\|onerror="; then
        echo "❌ XSS 취약점 발견: $payload" | tee -a $TEST_RESULTS
    else
        echo "✅ XSS 차단됨: $payload" | tee -a $TEST_RESULTS
    fi
done

# 3. 무차별 대입 공격 시뮬레이션
echo ""
echo "3. 무차별 대입 공격 시뮬레이션 실행 중..."
echo "" | tee -a $TEST_RESULTS
echo "3. 무차별 대입 공격 시뮬레이션" | tee -a $TEST_RESULTS
echo "=============================" | tee -a $TEST_RESULTS

echo "🔄 Rate Limiting 테스트 (25회 연속 요청):" | tee -a $TEST_RESULTS
success_count=0
blocked_count=0

for i in {1..25}; do
    response=$(curl -k -s -w "%{http_code}" -o /dev/null "https://localhost/api/health" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        ((success_count++))
    elif [ "$response" = "429" ] || [ "$response" = "503" ]; then
        ((blocked_count++))
    fi
    
    # 요청 간격을 짧게 하여 Rate Limiting 테스트
    sleep 0.1
done

echo "성공한 요청: $success_count" | tee -a $TEST_RESULTS
echo "차단된 요청: $blocked_count" | tee -a $TEST_RESULTS

if [ $blocked_count -gt 0 ]; then
    echo "✅ Rate Limiting 정상 동작" | tee -a $TEST_RESULTS
else
    echo "⚠️ Rate Limiting 확인 필요" | tee -a $TEST_RESULTS
fi

# 4. 데이터베이스 직접 접근 시도
echo ""
echo "4. 데이터베이스 직접 접근 테스트 실행 중..."
echo "" | tee -a $TEST_RESULTS
echo "4. 데이터베이스 보안 테스트" | tee -a $TEST_RESULTS
echo "=========================" | tee -a $TEST_RESULTS

echo "🔒 MySQL 직접 접근 테스트:" | tee -a $TEST_RESULTS
if timeout 5 nc -zv 172.20.3.10 3306 2>&1 | grep -q "succeeded"; then
    echo "⚠️ 외부에서 MySQL 접근 가능 (방화벽 확인 필요)" | tee -a $TEST_RESULTS
else
    echo "✅ MySQL 외부 접근 차단됨" | tee -a $TEST_RESULTS
fi

echo "" | tee -a $TEST_RESULTS
echo "🔄 Redis 직접 접근 테스트:" | tee -a $TEST_RESULTS
if timeout 5 nc -zv 172.20.2.10 6379 2>&1 | grep -q "succeeded"; then
    echo "⚠️ 외부에서 Redis 접근 가능 (방화벽 확인 필요)" | tee -a $TEST_RESULTS
else
    echo "✅ Redis 외부 접근 차단됨" | tee -a $TEST_RESULTS
fi

# 5. SSL/TLS 보안 테스트
echo ""
echo "5. SSL/TLS 보안 테스트 실행 중..."
echo "" | tee -a $TEST_RESULTS
echo "5. SSL/TLS 보안 테스트" | tee -a $TEST_RESULTS
echo "====================" | tee -a $TEST_RESULTS

# SSL Labs 스타일 테스트 (간단 버전)
echo "🔐 SSL/TLS 설정 테스트:" | tee -a $TEST_RESULTS

# TLS 버전 테스트
if command -v openssl &> /dev/null; then
    echo "TLS 1.2 지원:" | tee -a $TEST_RESULTS
    if echo | timeout 5 openssl s_client -connect localhost:443 -tls1_2 2>/dev/null | grep -q "Verify return code: 0"; then
        echo "✅ TLS 1.2 지원됨" | tee -a $TEST_RESULTS
    else
        echo "⚠️ TLS 1.2 확인 필요 (자체 서명 인증서)" | tee -a $TEST_RESULTS
    fi
    
    echo "약한 암호화 방식 테스트:" | tee -a $TEST_RESULTS
    if echo | timeout 5 openssl s_client -connect localhost:443 -cipher 'DES' 2>/dev/null | grep -q "Cipher is"; then
        echo "❌ 약한 암호화 방식 허용됨" | tee -a $TEST_RESULTS
    else
        echo "✅ 약한 암호화 방식 차단됨" | tee -a $TEST_RESULTS
    fi
else
    echo "⚠️ OpenSSL이 설치되지 않아 SSL 테스트 생략" | tee -a $TEST_RESULTS
fi

# 6. 방화벽 로그 확인
echo ""
echo "6. 방화벽 및 보안 로그 확인 중..."
echo "" | tee -a $TEST_RESULTS
echo "6. 방화벽 및 보안 로그" | tee -a $TEST_RESULTS
echo "===================" | tee -a $TEST_RESULTS

echo "🔥 방화벽 차단 로그:" | tee -a $TEST_RESULTS
firewall_logs=$(sudo dmesg | grep "DOCKER-FIREWALL" | tail -5 2>/dev/null)
if [ -n "$firewall_logs" ]; then
    echo "$firewall_logs" | tee -a $TEST_RESULTS
else
    echo "방화벽 차단 로그 없음" | tee -a $TEST_RESULTS
fi

echo "" | tee -a $TEST_RESULTS
echo "📊 보안 모니터링 상태:" | tee -a $TEST_RESULTS
if docker ps | grep -q "security-monitor"; then
    echo "✅ 보안 모니터링 시스템 실행 중" | tee -a $TEST_RESULTS
    
    # 보안 분석기 로그 확인
    analyzer_logs=$(docker logs security-analyzer 2>/dev/null | tail -3)
    if [ -n "$analyzer_logs" ]; then
        echo "최근 보안 분석 로그:" | tee -a $TEST_RESULTS
        echo "$analyzer_logs" | tee -a $TEST_RESULTS
    fi
else
    echo "❌ 보안 모니터링 시스템 미실행" | tee -a $TEST_RESULTS
fi

# 7. 컨테이너 보안 설정 확인
echo ""
echo "7. 컨테이너 보안 설정 확인 중..."
echo "" | tee -a $TEST_RESULTS
echo "7. 컨테이너 보안 설정" | tee -a $TEST_RESULTS
echo "===================" | tee -a $TEST_RESULTS

# 컨테이너 권한 확인
echo "🐳 컨테이너 보안 설정:" | tee -a $TEST_RESULTS
secure_containers=("secure-mysql-db" "secure-redis-cache" "secure-load-balancer")

for container in "${secure_containers[@]}"; do
    if docker ps | grep -q "$container"; then
        # 읽기 전용 파일시스템 확인
        readonly_check=$(docker inspect "$container" | grep -o '"ReadonlyRootfs":[^,]*' | cut -d: -f2)
        if [ "$readonly_check" = "true" ]; then
            echo "✅ $container: 읽기 전용 파일시스템" | tee -a $TEST_RESULTS
        else
            echo "⚠️ $container: 읽기 전용 파일시스템 미적용" | tee -a $TEST_RESULTS
        fi
        
        # 권한 확인
        user_check=$(docker inspect "$container" | grep -o '"User":[^,]*' | cut -d: -f2 | tr -d '"')
        if [ "$user_check" != "" ] && [ "$user_check" != "root" ]; then
            echo "✅ $container: 비root 사용자 ($user_check)" | tee -a $TEST_RESULTS
        else
            echo "⚠️ $container: root 사용자로 실행" | tee -a $TEST_RESULTS
        fi
    else
        echo "❌ $container: 컨테이너 미실행" | tee -a $TEST_RESULTS
    fi
done

# 8. 전체 테스트 결과 요약
echo ""
echo "8. 전체 테스트 결과 요약 생성 중..."
echo "" | tee -a $TEST_RESULTS
echo "8. 전체 테스트 결과 요약" | tee -a $TEST_RESULTS
echo "=====================" | tee -a $TEST_RESULTS

# 성공/실패 카운트
success_count=$(grep -c "✅" $TEST_RESULTS)
warning_count=$(grep -c "⚠️" $TEST_RESULTS)
failure_count=$(grep -c "❌" $TEST_RESULTS)

echo "📊 테스트 결과 통계:" | tee -a $TEST_RESULTS
echo "성공: $success_count" | tee -a $TEST_RESULTS
echo "경고: $warning_count" | tee -a $TEST_RESULTS
echo "실패: $failure_count" | tee -a $TEST_RESULTS

# 보안 점수 계산 (간단한 방식)
total_tests=$((success_count + warning_count + failure_count))
if [ $total_tests -gt 0 ]; then
    security_score=$(( (success_count * 100) / total_tests ))
    echo "보안 점수: $security_score/100" | tee -a $TEST_RESULTS
    
    if [ $security_score -ge 80 ]; then
        echo "🎉 보안 상태: 우수" | tee -a $TEST_RESULTS
    elif [ $security_score -ge 60 ]; then
        echo "⚠️ 보안 상태: 양호 (개선 권장)" | tee -a $TEST_RESULTS
    else
        echo "🚨 보안 상태: 취약 (즉시 개선 필요)" | tee -a $TEST_RESULTS
    fi
fi

echo "" | tee -a $TEST_RESULTS
echo "=== 보안 테스트 완료 ===" | tee -a $TEST_RESULTS
echo ""
echo "📋 테스트 결과가 $TEST_RESULTS 파일에 저장되었습니다."
echo ""
echo "🔍 추가 확인 사항:"
echo "1. 보안 대시보드: http://localhost:8888"
echo "2. HAProxy 통계: http://localhost:8404/stats"
echo "3. 방화벽 로그: sudo dmesg | grep DOCKER-FIREWALL"
echo "4. 보안 분석 로그: docker logs security-analyzer"
echo ""
echo "📝 권장 사항:"
if [ $failure_count -gt 0 ]; then
    echo "- ❌ 실패한 테스트 항목을 우선적으로 수정하세요"
fi
if [ $warning_count -gt 0 ]; then
    echo "- ⚠️ 경고 항목들을 검토하고 필요시 개선하세요"
fi
echo "- 🔄 정기적으로 보안 테스트를 실행하세요"
echo "- 📊 보안 모니터링 로그를 주기적으로 확인하세요"