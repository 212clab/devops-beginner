#!/bin/bash

# Week 4 Day 3 Lab 1: 환경 정리
# 설명: 모든 실습 리소스 삭제

echo "=== Lab 환경 정리 시작 ==="

# 1. 네임스페이스 삭제
echo "1/2 네임스페이스 삭제 중..."
kubectl delete namespace secure-app --ignore-not-found=true

# 2. Istio 삭제 (선택사항)
echo "2/2 Istio 삭제 여부 확인..."
read -p "Istio를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    istioctl uninstall --purge -y
    kubectl delete namespace istio-system --ignore-not-found=true
    echo "✅ Istio 삭제 완료"
else
    echo "ℹ️  Istio 유지"
fi

echo ""
echo "=== Lab 환경 정리 완료 ==="
