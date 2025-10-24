#!/bin/bash

# Week 4 Day 5 Hands-on 1: CloudMart 통합 검증
# 설명: CloudMart 전체 시스템 상태 및 Grafana FinOps 검증

echo "=== CloudMart 통합 검증 ==="
echo ""

echo "1. CloudMart 서비스 확인"
kubectl get pods -n cloudmart -o wide

echo ""
echo "2. HPA 동작 확인"
kubectl get hpa -n cloudmart

echo ""
echo "3. Grafana 상태"
kubectl get pods -n monitoring -l app=grafana

echo ""
echo "4. 전체 리소스 사용량"
kubectl top nodes
echo ""
kubectl top pods -n cloudmart

echo ""
echo "5. Grafana FinOps 대시보드 접속 확인"
echo "Grafana URL: http://localhost:30091"
echo "ID: admin / PW: admin"
echo "대시보드: FinOps Cost Analysis"

echo ""
echo "6. 포트포워딩 상태 확인"
echo "User Service: http://localhost:8080"
echo "Product Service: http://localhost:8081"
echo "Order Service: http://localhost:8082"
echo "Jaeger UI: http://localhost:16686"

echo ""
echo "=== 검증 완료 ==="
echo ""
echo "다음 단계:"
echo "1. Grafana 접속: http://localhost:30091"
echo "2. FinOps Cost Analysis 대시보드 확인"
echo "3. CloudMart 네임스페이스 선택하여 비용 효율성 분석"

