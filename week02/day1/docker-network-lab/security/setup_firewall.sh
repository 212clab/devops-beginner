#!/bin/bash

# Week 2 Day 1 Lab 2: 방화벽 규칙 설정 스크립트
# 사용법: sudo ./setup_firewall.sh

echo "=== Docker 방화벽 규칙 설정 시작 ==="

# 기본 정책: 모든 접근 차단
echo "1. 기본 방화벽 정책 설정 중..."
iptables -P FORWARD DROP

# Docker 사용자 정의 체인 생성 (없는 경우)
echo "2. Docker 사용자 정의 체인 생성 중..."
iptables -N DOCKER-USER 2>/dev/null || true

# 기존 DOCKER-USER 규칙 초기화
echo "3. 기존 규칙 초기화 중..."
iptables -F DOCKER-USER

# 1. 로컬호스트 통신 허용
echo "4. 로컬호스트 통신 허용 규칙 추가..."
iptables -A DOCKER-USER -i lo -j ACCEPT

# 2. 기존 연결 유지
echo "5. 기존 연결 유지 규칙 추가..."
iptables -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# 3. DMZ 네트워크 (frontend-net) 규칙
echo "6. DMZ 네트워크 접근 규칙 설정..."
# 외부에서 웹 서버(80, 443)와 로드 밸런서 접근 허용
iptables -A DOCKER-USER -p tcp --dport 80 -j ACCEPT
iptables -A DOCKER-USER -p tcp --dport 443 -j ACCEPT
iptables -A DOCKER-USER -p tcp --dport 8404 -s 172.20.1.0/24 -j ACCEPT

# 4. 백엔드 네트워크 (backend-net) 보호
echo "7. 백엔드 네트워크 보호 규칙 설정..."
# DMZ에서만 백엔드 접근 허용
iptables -A DOCKER-USER -s 172.20.1.0/24 -d 172.20.2.0/24 -p tcp --dport 3000 -j ACCEPT
iptables -A DOCKER-USER -s 172.20.1.0/24 -d 172.20.2.0/24 -p tcp --dport 6379 -j ACCEPT

# 5. 데이터베이스 네트워크 (database-net) 최고 보안
echo "8. 데이터베이스 네트워크 최고 보안 규칙 설정..."
# 백엔드에서만 데이터베이스 접근 허용
iptables -A DOCKER-USER -s 172.20.2.0/24 -d 172.20.3.0/24 -p tcp --dport 3306 -j ACCEPT

# 6. 공격 패턴 차단
echo "9. 공격 패턴 차단 규칙 설정..."

# 포트 스캔 차단
iptables -A DOCKER-USER -p tcp --tcp-flags ALL NONE -j DROP
iptables -A DOCKER-USER -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A DOCKER-USER -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# SYN Flood 공격 방지
iptables -A DOCKER-USER -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A DOCKER-USER -p tcp --syn -j DROP

# 과도한 연결 시도 차단
iptables -A DOCKER-USER -p tcp --dport 22 -m connlimit --connlimit-above 3 -j DROP
iptables -A DOCKER-USER -p tcp --dport 3306 -m connlimit --connlimit-above 10 -j DROP

# 7. 로깅 (의심스러운 활동)
echo "10. 보안 로깅 규칙 설정..."
iptables -A DOCKER-USER -m limit --limit 5/min -j LOG --log-prefix "DOCKER-FIREWALL: "

# 8. 기본 거부
echo "11. 기본 거부 정책 적용..."
iptables -A DOCKER-USER -j DROP

# 규칙 확인
echo ""
echo "=== 현재 방화벽 규칙 ==="
iptables -L DOCKER-USER -n -v

echo ""
echo "=== 방화벽 설정 완료 ==="
echo ""
echo "적용된 보안 정책:"
echo "✅ DMZ 네트워크: 웹 트래픽만 허용 (80, 443)"
echo "✅ 백엔드 네트워크: DMZ에서만 접근 허용"
echo "✅ 데이터베이스 네트워크: 백엔드에서만 접근 허용"
echo "✅ 공격 패턴 차단: 포트 스캔, SYN Flood 방지"
echo "✅ 연결 제한: 과도한 연결 시도 차단"
echo "✅ 보안 로깅: 의심스러운 활동 기록"
echo ""
echo "🔍 로그 확인: sudo dmesg | grep DOCKER-FIREWALL"