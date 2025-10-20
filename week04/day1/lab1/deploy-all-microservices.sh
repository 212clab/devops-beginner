#!/bin/bash

# Week 4 Day 1 Lab 1: 완전한 마이크로서비스 아키텍처 배포
# 사용법: ./deploy-all-microservices.sh

echo "=== 완전한 마이크로서비스 아키텍처 배포 시작 ==="
echo ""

set -e
trap 'echo "❌ 스크립트 실행 중 오류 발생"' ERR

echo "1/3 상품 서비스 배포 중..."
echo "2/3 주문 서비스 배포 중..."
kubectl apply -f manifests/microservices/all-services.yaml

echo "3/3 완전한 마이크로서비스 Ingress 설정 중..."
# 기존 하이브리드 Ingress 삭제 (있는 경우에만)
kubectl delete ingress ecommerce-hybrid-ingress -n ecommerce-advanced --ignore-not-found=true

kubectl apply -f manifests/microservices/full-ingress.yaml

# 기존 하이브리드 Ingress 삭제 (있는 경우에만)
kubectl delete ingress ecommerce-hybrid-ingress -n ecommerce-advanced --ignore-not-found=true

# 💡 모놀리스는 유지 (비교 목적)
echo "💡 모놀리스 애플리케이션은 비교를 위해 유지됩니다"

echo "배포 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=product-service -n ecommerce-advanced --timeout=60s
kubectl wait --for=condition=ready pod -l app=order-service -n ecommerce-advanced --timeout=60s

echo ""
echo "=== 완전한 마이크로서비스 아키텍처 배포 완료 ==="
echo ""
echo "배포된 마이크로서비스:"
echo "- 사용자 서비스: user-service (2 replicas)"
echo "- 상품 서비스: product-service (2 replicas)"
echo "- 주문 서비스: order-service (2 replicas)"
echo "- 모놀리스: 유지됨 (비교 목적)"
echo ""
echo "라우팅 규칙:"
echo "- /api/users → user-service"
echo "- /api/products → product-service"
echo "- /api/orders → order-service"
echo "- / → user-service (기본)"
echo ""
echo "상태 확인:"
kubectl get pods -n ecommerce-advanced
echo ""
echo "서비스 확인:"
kubectl get svc -n ecommerce-advanced
echo ""
echo "✅ 완전한 마이크로서비스 아키텍처 배포 성공!"
