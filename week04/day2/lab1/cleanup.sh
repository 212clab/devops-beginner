#!/bin/bash

# Lab 1: Kong API Gateway - 환경 정리

echo "=== Kong API Gateway Lab 환경 정리 시작 ==="
echo ""

# 1. Kong 네임스페이스 삭제
echo "1. Kong 네임스페이스 삭제 중..."
kubectl delete namespace kong
echo "   ✅ Kong 네임스페이스 삭제 완료"

echo ""
echo "=== 환경 정리 완료 ==="
echo ""
echo "💡 백엔드 서비스는 유지됩니다 (backend 네임스페이스)."
echo "   Hands-on 1 (Istio)에서 재사용 가능합니다."
echo ""
echo "💡 백엔드 서비스 삭제가 필요한 경우:"
echo "   kubectl delete namespace backend"
echo ""
echo "💡 클러스터 삭제가 필요한 경우:"
echo "   kind delete cluster --name lab-cluster"
