#!/bin/bash

# Week 4 Day 5 Hands-on 1: 포트포워딩 자동 시작
# 설명: CloudMart, Jaeger 포트포워딩 자동 실행 (Grafana는 이미 NodePort 30091)

set -e

echo "=== 포트포워딩 시작 ==="

# CloudMart 서비스 포트포워딩
echo "1/4 User Service 포트포워딩 (8080 → 80)..."
kubectl port-forward -n cloudmart svc/user-service 8080:80 > /dev/null 2>&1 &

echo "2/4 Product Service 포트포워딩 (8081 → 80)..."
kubectl port-forward -n cloudmart svc/product-service 8081:80 > /dev/null 2>&1 &

echo "3/4 Order Service 포트포워딩 (8082 → 80)..."
kubectl port-forward -n cloudmart svc/order-service 8082:80 > /dev/null 2>&1 &

# Jaeger 포트포워딩
echo "4/4 Jaeger 포트포워딩 (16686 → 16686)..."
kubectl port-forward -n tracing svc/jaeger-query 16686:16686 > /dev/null 2>&1 &

# 잠시 대기
sleep 2

echo ""
echo "=== 포트포워딩 완료 ==="
echo ""
echo "접속 정보:"
echo "- User Service: http://localhost:8080"
echo "- Product Service: http://localhost:8081"
echo "- Order Service: http://localhost:8082"
echo "- Grafana: http://localhost:30091 (admin/admin) - NodePort"
echo "- Jaeger UI: http://localhost:16686"
echo ""
echo "포트포워딩 중지: pkill -f port-forward"


