#!/bin/bash

# Week 4 Day 1 Challenge 1: 환경 정리
# 사용법: ./cleanup.sh

echo "=== Challenge 1 환경 정리 시작 ==="

# 에러가 발생해도 계속 진행
set +e

# 확인 함수
confirm_cleanup() {
    echo "⚠️  다음 Challenge 리소스들이 삭제됩니다:"
    echo "   - 모든 마이크로서비스 (order, payment, command, query, user, event-store)"
    echo "   - Jobs 및 CronJobs"
    echo "   - ConfigMaps 및 Services"
    echo "   - Ingress 설정"
    echo ""
    read -p "Challenge 환경을 정리하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 정리 작업이 취소되었습니다."
        exit 1
    fi
}

# 사용자 확인
confirm_cleanup

echo ""
echo "🧹 Challenge 1 리소스 정리 중..."

# Jobs 정리
echo "🗑️  Jobs 정리 중..."
kubectl delete jobs --all -n microservices-challenge 2>/dev/null || true

# CronJobs 정리
echo "🗑️  CronJobs 정리 중..."
kubectl delete cronjobs --all -n microservices-challenge 2>/dev/null || true

# Deployments 정리
echo "🗑️  Deployments 정리 중..."
kubectl delete deployments --all -n microservices-challenge 2>/dev/null || true

# Services 정리
echo "🗑️  Services 정리 중..."
kubectl delete services --all -n microservices-challenge 2>/dev/null || true

# ConfigMaps 정리
echo "🗑️  ConfigMaps 정리 중..."
kubectl delete configmaps --all -n microservices-challenge 2>/dev/null || true

# Ingress 정리
echo "🗑️  Ingress 정리 중..."
kubectl delete ingress --all -n microservices-challenge 2>/dev/null || true

# 네임스페이스 정리 (선택사항)
echo ""
read -p "microservices-challenge 네임스페이스도 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  microservices-challenge 네임스페이스 삭제 중..."
    kubectl delete namespace microservices-challenge
    echo "✅ 네임스페이스 삭제 완료"
else
    echo "ℹ️  네임스페이스는 유지됩니다"
fi

# 최종 확인
echo ""
echo "🔍 정리 결과 확인:"
if kubectl get namespace microservices-challenge >/dev/null 2>&1; then
    echo "📦 microservices-challenge 네임스페이스 리소스:"
    kubectl get all -n microservices-challenge 2>/dev/null || echo "   (리소스 없음)"
else
    echo "📦 microservices-challenge 네임스페이스: 삭제됨"
fi

echo ""
echo "=== Challenge 1 환경 정리 완료 ==="
echo ""
echo "🎯 정리된 내용:"
echo "- ✅ 모든 Challenge 리소스 삭제"
echo "- ✅ Jobs, CronJobs, Deployments 정리"
echo "- ✅ Services, ConfigMaps, Ingress 정리"
echo ""
echo "💡 다시 Challenge를 시도하려면:"
echo "   ./deploy-broken-system.sh 실행"
echo ""
