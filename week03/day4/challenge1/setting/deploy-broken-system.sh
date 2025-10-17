#!/bin/bash

# Week 3 Day 4 Challenge 1: 문제 시스템 배포
# 사용법: ./deploy-broken-system.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== SecureBank 문제 시스템 배포 시작 ==="

# 네임스페이스 생성
echo "1/6 네임스페이스 생성 중..."
kubectl create namespace securebank --dry-run=client -o yaml | kubectl apply -f -

# 문제 1: 잘못된 RBAC 설정
echo "2/6 RBAC 리소스 배포 중 (문제 포함)..."
kubectl apply -f "$SCRIPT_DIR/broken-rbac.yaml"

# 문제 2: 인증서 갱신 테스트 리소스
echo "3/6 인증서 테스트 리소스 배포 중..."
kubectl apply -f "$SCRIPT_DIR/cert-renewal-test.yaml"

# 문제 3: 잘못된 Network Policy
echo "4/6 Network Policy 배포 중 (문제 포함)..."
kubectl apply -f "$SCRIPT_DIR/broken-network-policy.yaml"

# 문제 4: Secret 노출
echo "5/6 애플리케이션 배포 중 (Secret 노출 문제 포함)..."
kubectl apply -f "$SCRIPT_DIR/exposed-secrets.yaml"

# 기본 애플리케이션 리소스
echo "6/6 기본 애플리케이션 리소스 배포 중..."
kubectl apply -f "$SCRIPT_DIR/app-resources.yaml"

# 상태 확인
echo ""
echo "배포 상태 확인 중..."
sleep 5
kubectl get all -n securebank

echo ""
echo "=== SecureBank 문제 시스템 배포 완료 ==="
echo ""
echo "🚨 발견된 보안 문제:"
echo "1. RBAC 권한 오류 - developer-sa가 Pod 생성 불가"
echo "   파일: broken-rbac.yaml"
echo ""
echo "2. 인증서 갱신 테스트 - 인증서 확인 및 갱신 프로세스"
echo "   파일: cert-renewal-test.yaml"
echo ""
echo "3. Network Policy 차단 - 잘못된 라벨과 포트"
echo "   파일: broken-network-policy.yaml"
echo ""
echo "4. Secret 노출 - 평문 비밀번호와 ConfigMap 오용"
echo "   파일: exposed-secrets.yaml"
echo ""
echo "Challenge 시작!"
