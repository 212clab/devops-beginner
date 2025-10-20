#!/bin/bash

# Week 4 Day 1 Lab 1: 모놀리스 애플리케이션 설정
# 사용법: ./setup-monolith.sh

echo "=== 모놀리스 E-Commerce 애플리케이션 배포 시작 ==="

# 에러 발생 시 스크립트 중단
set -e
trap 'echo "❌ 스크립트 실행 중 오류 발생"' ERR

echo "1/4 네임스페이스 생성 중..."
kubectl create namespace ecommerce-advanced --dry-run=client -o yaml | kubectl apply -f -

echo "2/4 PostgreSQL 데이터베이스 배포 중..."
kubectl apply -f manifests/monolith/postgres.yaml

echo "3/4 모놀리스 애플리케이션 배포 중..."
kubectl apply -f manifests/monolith/ecommerce-app.yaml

echo "4/4 Ingress 설정 중..."
kubectl apply -f manifests/monolith/ingress.yaml

# Pod 시작 대기
echo "Pod 시작 대기 중..."
kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce-advanced --timeout=60s
kubectl wait --for=condition=ready pod -l app=ecommerce-monolith -n ecommerce-advanced --timeout=60s

# /etc/hosts 설정 (sudo 권한 필요)
if ! grep -q "ecommerce.local" /etc/hosts; then
    echo "127.0.0.1 ecommerce.local" | sudo tee -a /etc/hosts
    echo "✅ /etc/hosts 파일에 ecommerce.local 추가됨"
fi

echo ""
echo "=== 모놀리스 애플리케이션 배포 완료 ==="
echo ""
echo "배포된 리소스:"
echo "- Namespace: ecommerce"
echo "- Database: PostgreSQL (postgres-service)"
echo "- Application: E-Commerce Monolith (2 replicas)"
echo "- Ingress: ecommerce.local"
echo ""
echo "접속 정보:"
echo "- 웹 브라우저: http://ecommerce.local"
echo "- curl 테스트: curl -H 'Host: ecommerce.local' http://localhost/"
echo ""
echo "상태 확인:"
kubectl get pods -n ecommerce-advanced
echo ""
echo "✅ 모놀리스 배포 성공!"
