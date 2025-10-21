#!/bin/bash

# Week 4 Day 1 Challenge 1: 문제 시스템 배포
# 사용법: ./deploy-broken-system.sh

echo "=== Challenge 1: 문제 시스템 배포 시작 ==="

# 에러 발생 시 스크립트 중단
set -e

# 진행 상황 표시 함수
show_progress() {
    echo ""
    echo "🚨 $1"
    echo "----------------------------------------"
}

# 네임스페이스 확인
show_progress "1/5 환경 준비"
if ! kubectl get namespace microservices-challenge >/dev/null 2>&1; then
    kubectl create namespace microservices-challenge
    echo "✅ microservices-challenge 네임스페이스 생성"
fi

if ! kubectl get namespace testing >/dev/null 2>&1; then
    kubectl create namespace testing
    echo "✅ testing 네임스페이스 생성"
fi

# Load Tester 배포 (없으면)
if ! kubectl get deployment load-tester -n testing >/dev/null 2>&1; then
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-tester
  namespace: testing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-tester
  template:
    metadata:
      labels:
        app: load-tester
    spec:
      containers:
      - name: load-tester
        image: curlimages/curl:latest
        command: ['sleep', '3600']
EOF
    echo "✅ Load Tester 배포 완료"
fi

# 문제 1: Saga 패턴 장애 배포
show_progress "2/5 Saga 패턴 장애 배포"
kubectl apply -f /brokens/broken-saga.yaml
echo "🚨 Saga 패턴 장애 배포 완료"

# 문제 2: CQRS 패턴 장애 배포
show_progress "3/5 CQRS 패턴 장애 배포"
kubectl apply -f /brokens/broken-cqrs.yaml
echo "🚨 CQRS 패턴 장애 배포 완료"

# 문제 3: Event Sourcing 장애 배포
show_progress "4/5 Event Sourcing 장애 배포"
kubectl apply -f/brokens/ broken-eventsourcing.yaml
echo "🚨 Event Sourcing 장애 배포 완료"

# 문제 4: 네트워킹 장애 배포
show_progress "5/5 네트워킹 장애 배포"
kubectl apply -f /brokens/broken-networking.yaml
echo "🚨 네트워킹 장애 배포 완료"

# 잠시 대기 (리소스 생성 시간)
echo ""
echo "⏳ 시스템 초기화 대기 중... (30초)"
sleep 30

# 장애 상황 확인
echo ""
echo "=== 🚨 장애 상황 확인 ==="
echo ""
echo "📦 배포된 리소스:"
kubectl get all -n microservices-challenge

echo ""
echo "🚨 예상 장애 상황:"
echo "- ❌ Saga Job 실행 실패"
echo "- ❌ Command/Query 서비스 응답 오류"
echo "- ❌ Event Processor 중단"
echo "- ❌ Ingress 라우팅 실패"

echo ""
echo "=== Challenge 1 문제 시스템 배포 완료 ==="
echo ""
echo "🎯 해결해야 할 문제들:"
echo "1. 🔄 Saga 패턴 트랜잭션 실패 (25분)"
echo "2. 📊 CQRS 패턴 읽기/쓰기 분리 오류 (25분)"
echo "3. 📝 Event Sourcing 이벤트 처리 중단 (20분)"
echo "4. 🌐 네트워킹 및 서비스 디스커버리 장애 (20분)"
echo ""
echo "⏰ 제한시간: 90분"
echo "🚀 지금부터 문제 해결을 시작하세요!"
echo ""
