#!/bin/bash

# Week 4 Day 1 Challenge 1: 마이크로서비스 패턴 장애 복구 환경 설정
# 사용법: ./setup-environment.sh

echo "=== Week 4 Day 1 Challenge 1 환경 설정 시작 ==="

# 1. 네임스페이스 생성
echo "1. 네임스페이스 생성 중..."
kubectl create namespace microservices-challenge --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 2. 기본 리소스 확인
echo "2. 클러스터 상태 확인 중..."
kubectl get nodes
kubectl get namespaces

# 3. 필요한 도구 확인
echo "3. 필요한 도구 확인 중..."
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl이 설치되지 않았습니다"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes 클러스터에 연결할 수 없습니다"
    exit 1
fi

echo "✅ kubectl 및 클러스터 연결 확인됨"

# 4. 기본 ConfigMap 생성 (Challenge에서 사용)
echo "4. 기본 설정 생성 중..."
kubectl create configmap challenge-config \
  --from-literal=database-url="postgresql://localhost:5432/microservices" \
  --from-literal=redis-url="redis://localhost:6379" \
  --from-literal=message-queue="rabbitmq://localhost:5672" \
  -n microservices-challenge --dry-run=client -o yaml | kubectl apply -f -

# 5. 환경 설정 완료
echo ""
echo "=== Challenge 1 환경 설정 완료 ==="
echo ""
echo "생성된 리소스:"
echo "- 네임스페이스: microservices-challenge, monitoring"
echo "- ConfigMap: challenge-config"
echo ""
echo "다음 단계:"
echo "1. ./deploy-broken-system.sh - 문제 시스템 배포"
echo "2. 장애 상황 분석 및 해결"
echo "3. ./verify-solutions.sh - 해결 검증"
echo "4. ./cleanup.sh - 환경 정리"
echo ""
