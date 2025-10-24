#!/bin/bash

# Week 4 Day 5 Hands-on 1: 모니터링 스택 통합 설치
# 설명: 개별 스크립트를 순차적으로 실행

set -e

echo "=== CloudMart 애플리케이션 통합 설치 시작 ==="
echo ""

echo "0. cloudmart 네임스페이스 생성..."
# Here Document 문법으로 수정
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: cloudmart
  labels:
    project: cloudmart      # 프로젝트 이름
    team: platform          # 담당 팀
    cost-center: CC-2001    # 비용 센터 (Grafana FinOps에서 추적용)
EOF
echo "네임스페이스 'cloudmart' 생성 완료."
echo ""

echo "1/3 user-service 배포..."
kubectl apply -f ./deploy-user.yaml -n cloudmart
echo ""

echo "2/3 product-service 배포..."
kubectl apply -f ./deploy-product.yaml -n cloudmart
echo ""

echo "3/3 order-service 배포..."
kubectl apply -f ./deploy-order.yaml -n cloudmart
echo ""

echo "모든 서비스 배포 완료. Pod가 준비될 때까지 대기 중..."
# 배포 완료 대기
kubectl wait --for=condition=ready pod \
  -l tier=backend \
  -n cloudmart \
  --timeout=120s
echo "모든 Pod가 성공적으로 시작되었습니다."
echo ""

# 최종 상태 확인
echo "배포 후 최종 상태:"
kubectl get pods,svc -n cloudmart

echo "=== CloudMart 애플리케이션 설치 성공 ==="

# CloudMart 서비스 포트포워딩
kubectl port-forward -n cloudmart svc/user-service 8080:80 &
kubectl port-forward -n cloudmart svc/product-service 8081:80 &
kubectl port-forward -n cloudmart svc/order-service 8082:80 &

# Jaeger 포트포워딩
kubectl port-forward -n tracing svc/jaeger-query 16686:16686 &