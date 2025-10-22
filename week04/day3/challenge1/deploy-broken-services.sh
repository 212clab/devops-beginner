#!/bin/bash

# Week 4 Day 3 Challenge 1: 문제 시스템 배포
# 설명: 4가지 보안 오류가 포함된 시스템 배포

set -e

echo "=== Challenge 문제 시스템 배포 시작 ==="

# 1. 시나리오 1: mTLS PERMISSIVE 오류
echo "1/4 시나리오 1 배포 중 (mTLS 설정 오류)..."
kubectl apply -f broken-scenario1.yaml

# 2. 시나리오 2: JWT 잘못된 issuer
echo "2/4 시나리오 2 배포 중 (JWT 검증 오류)..."
kubectl apply -f broken-scenario2.yaml

# 3. 시나리오 3: OPA 리소스 제한 누락
echo "3/4 시나리오 3 배포 중 (리소스 제한 오류)..."
kubectl apply -f broken-scenario3.yaml

# ConstraintTemplate CRD 등록 대기
echo "   ConstraintTemplate CRD 등록 대기 중..."
sleep 5
kubectl wait --for condition=established --timeout=60s crd/k8scontainerresourcelimits.constraints.gatekeeper.sh 2>/dev/null || true
sleep 3

# 4. 시나리오 4: Service 연결 오류
echo "4/4 시나리오 4 배포 중 (네트워크 오류)..."
kubectl apply -f broken-scenario4.yaml

echo ""
echo "=== Challenge 문제 시스템 배포 완료 ==="
echo ""
echo "배포된 문제 시나리오:"
echo "- 시나리오 1: mTLS PERMISSIVE 설정 오류"
echo "- 시나리오 2: JWT issuer 불일치"
echo "- 시나리오 3: OPA 리소스 제한 누락"
echo "- 시나리오 4: Service 연결 실패"
echo ""
echo "💡 힌트: kubectl get pods -A 로 전체 상태 확인"
echo "💡 문제 해결 후: ./verify-solution.sh 로 검증"
