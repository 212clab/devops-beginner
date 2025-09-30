#!/bin/bash

echo "🚀 === Week 2 Day 2 Lab 1 전체 실행 ==="
echo "Stateful 애플리케이션 스택 구축 (MariaDB + WordPress + Nginx + 모니터링)"
echo ""

# 실행 순서와 예상 시간
echo "📋 실행 계획:"
echo "1. MariaDB 데이터베이스 구축 (2-3분)"
echo "2. WordPress 애플리케이션 배포 (2-3분)"  
echo "3. Nginx 리버스 프록시 설정 (1-2분)"
echo "4. 모니터링 시스템 구축 (1-2분)"
echo "5. 전체 시스템 테스트 (1분)"
echo "총 예상 시간: 7-11분"
echo ""

read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "실행을 취소했습니다."
    exit 1
fi

echo ""
echo "🔥 Lab 1 시작!"
echo ""

# 1단계: MariaDB 구축
echo "📊 1/5 단계: MariaDB 데이터베이스 구축"
echo "----------------------------------------"
if ./setup_database.sh; then
    echo "✅ MariaDB 구축 완료"
else
    echo "❌ MariaDB 구축 실패"
    exit 1
fi

echo ""
echo "📊 2/5 단계: WordPress 애플리케이션 배포"
echo "----------------------------------------"
if ./deploy_wordpress.sh; then
    echo "✅ WordPress 배포 완료"
else
    echo "❌ WordPress 배포 실패"
    exit 1
fi

echo ""
echo "📊 3/5 단계: Nginx 리버스 프록시 설정"
echo "----------------------------------------"
if ./setup_nginx.sh; then
    echo "✅ Nginx 설정 완료"
else
    echo "❌ Nginx 설정 실패"
    exit 1
fi

echo ""
echo "📊 4/5 단계: 모니터링 시스템 구축"
echo "----------------------------------------"
if ./setup_monitoring.sh; then
    echo "✅ 모니터링 시스템 구축 완료"
else
    echo "❌ 모니터링 시스템 구축 실패"
    exit 1
fi

echo ""
echo "📊 5/5 단계: 전체 시스템 테스트"
echo "----------------------------------------"
if ./test_system.sh; then
    echo "✅ 시스템 테스트 완료"
else
    echo "⚠️ 시스템 테스트에서 일부 문제 발견"
fi

echo ""
echo "🎉 === Lab 1 완료! ==="
echo ""
echo "🌐 접속 정보:"
echo "- WordPress 사이트: http://localhost"
echo "- WordPress 관리자: http://localhost/wp-admin"
echo "- 모니터링 대시보드: http://localhost:9090"
echo "- Nginx 상태: http://localhost/nginx_status"
echo ""
echo "📋 구축된 서비스:"
echo "✅ MariaDB (MySQL 호환) - 데이터베이스"
echo "✅ WordPress - 웹 애플리케이션"
echo "✅ Redis - 세션 스토어"
echo "✅ Nginx - 리버스 프록시 & 로드밸런서"
echo "✅ 모니터링 대시보드 - 시스템 관리"
echo ""
echo "🔧 관리 명령어:"
echo "- 백업 실행: ./scripts/backup.sh"
echo "- 헬스 체크: ./scripts/health-check.sh"
echo "- 시스템 정보: ./scripts/system-info.sh"
echo ""
echo "🎯 Lab 1 학습 목표 달성!"
echo "- Stateful 애플리케이션 이해"
echo "- 데이터 영속성 구현"
echo "- 멀티 컨테이너 네트워킹"
echo "- 리버스 프록시 설정"
echo "- 모니터링 시스템 구축"