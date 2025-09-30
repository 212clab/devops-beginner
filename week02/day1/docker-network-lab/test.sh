#!/bin/bash

# Week 2 Day 1 Lab 1: 전체 시스템 테스트 스크립트
# 사용법: ./test_system.sh

echo "=== 멀티 컨테이너 네트워크 시스템 테스트 시작 ==="

# 컨테이너 상태 확인
echo "1. 컨테이너 상태 확인"
echo "=================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mysql-db|redis-cache|api-server|load-balancer|web-server)"

echo ""
echo "2. 네트워크 연결 상태 확인"
echo "=================================="

echo "Frontend Network (172.20.1.0/24):"
docker network inspect frontend-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "네트워크를 찾을 수 없습니다."

echo ""
echo "Backend Network (172.20.2.0/24):"
docker network inspect backend-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "네트워크를 찾을 수 없습니다."

echo ""
echo "Database Network (172.20.3.0/24):"
docker network inspect database-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "네트워크를 찾을 수 없습니다."

echo ""
echo "3. 서비스 연결 테스트"
echo "=================================="

# 데이터베이스 연결 테스트
echo "📊 데이터베이스 연결 테스트:"
if docker exec mysql-db mysql -u root -psecretpassword -e "SELECT 'DB Connection OK' as status;" 2>/dev/null; then
    echo "✅ MySQL 데이터베이스 연결 성공"
else
    echo "❌ MySQL 데이터베이스 연결 실패"
fi

# Redis 연결 테스트
echo ""
echo "🔄 Redis 캐시 연결 테스트:"
if docker exec redis-cache redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis 캐시 연결 성공"
else
    echo "❌ Redis 캐시 연결 실패"
fi

# API 서버 연결 테스트
echo ""
echo "🖥️ API 서버 연결 테스트:"
for server in api-server-1 api-server-2; do
    if docker exec $server curl -s http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ $server 연결 성공"
    else
        echo "❌ $server 연결 실패"
    fi
done

# 네트워크 간 통신 테스트
echo ""
echo "🌐 네트워크 간 통신 테스트:"

# 웹 서버에서 API 서버로 연결
echo "Frontend → Backend 통신:"
if docker exec web-server curl -s http://api-server-1:3000/health >/dev/null 2>&1; then
    echo "✅ 웹 서버 → API 서버 통신 성공"
else
    echo "❌ 웹 서버 → API 서버 통신 실패"
fi

# API 서버에서 데이터베이스로 연결
echo "Backend → Database 통신:"
if docker exec api-server-1 nc -zv mysql-db 3306 2>&1 | grep -q "succeeded"; then
    echo "✅ API 서버 → 데이터베이스 통신 성공"
else
    echo "❌ API 서버 → 데이터베이스 통신 실패"
fi

echo ""
echo "4. 로드 밸런서 테스트"
echo "=================================="

# HAProxy 통계 확인
echo "⚖️ 로드 밸런서 상태:"
if curl -s http://localhost:8404/stats | grep -q "api-server"; then
    echo "✅ HAProxy 로드 밸런서 정상 동작"
    echo "📊 통계 페이지: http://localhost:8404/stats"
else
    echo "❌ HAProxy 로드 밸런서 오류"
fi

# 로드 밸런싱 테스트
echo ""
echo "🔄 로드 밸런싱 동작 테스트 (5회 요청):"
for i in {1..5}; do
    response=$(curl -s http://localhost:8080/health 2>/dev/null)
    if echo "$response" | grep -q "healthy"; then
        server=$(echo "$response" | grep -o '"server":"[^"]*"' | cut -d'"' -f4)
        echo "요청 $i: ✅ 성공 (서버: ${server:-unknown})"
    else
        echo "요청 $i: ❌ 실패"
    fi
done

echo ""
echo "5. 웹 애플리케이션 테스트"
echo "=================================="

# 웹 서버 접근 테스트
echo "🌐 웹 서버 접근 테스트:"
if curl -s -I http://localhost/ | grep -q "200 OK"; then
    echo "✅ 웹 서버 접근 성공"
    echo "🌍 브라우저 접속: http://localhost"
else
    echo "❌ 웹 서버 접근 실패"
fi

# API 엔드포인트 테스트
echo ""
echo "🔌 API 엔드포인트 테스트:"

# Health check
if curl -s http://localhost/api/health | grep -q "healthy"; then
    echo "✅ /api/health 엔드포인트 정상"
else
    echo "❌ /api/health 엔드포인트 오류"
fi

# Users endpoint
if curl -s http://localhost/api/users | grep -q "users"; then
    echo "✅ /api/users 엔드포인트 정상"
else
    echo "❌ /api/users 엔드포인트 오류"
fi

echo ""
echo "6. 성능 및 리소스 사용량"
echo "=================================="

# 컨테이너 리소스 사용량
echo "💻 컨테이너 리소스 사용량:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6

echo ""
echo "7. 테스트 결과 요약"
echo "=================================="

# 전체 테스트 결과 요약
total_containers=$(docker ps | grep -E "(mysql-db|redis-cache|api-server|load-balancer|web-server)" | wc -l)
expected_containers=5

if [ "$total_containers" -eq "$expected_containers" ]; then
    echo "✅ 모든 컨테이너 정상 실행 ($total_containers/$expected_containers)"
else
    echo "⚠️ 일부 컨테이너 누락 ($total_containers/$expected_containers)"
fi

# 네트워크 테스트 결과
if curl -s http://localhost/api/health >/dev/null 2>&1; then
    echo "✅ 전체 시스템 통신 정상"
else
    echo "❌ 시스템 통신 오류 발생"
fi

echo ""
echo "🎉 시스템 테스트 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. 웹 브라우저에서 http://localhost 접속"
echo "2. HAProxy 통계 페이지 확인: http://localhost:8404/stats"
echo "3. API 직접 테스트: curl http://localhost/api/users"
echo ""
echo "🔧 문제 발생 시 확인사항:"
echo "- docker ps: 모든 컨테이너 실행 상태 확인"
echo "- docker logs [컨테이너명]: 개별 컨테이너 로그 확인"
echo "- docker network ls: 네트워크 생성 상태 확인"