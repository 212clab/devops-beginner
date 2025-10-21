#!/bin/bash

# Week 4 Day 1 Challenge 1: 포트 포워딩 시작 스크립트
# 사용법: ./start-port-forward.sh

echo "=== 포트 포워딩 시작 ==="
echo ""

# 기존 포트 포워딩 프로세스 종료
echo "1. 기존 포트 포워딩 종료 중..."
pkill -f "kubectl port-forward.*microservices-challenge" 2>/dev/null
sleep 2

# 포트 포워딩 시작
echo "2. 새로운 포트 포워딩 설정 중..."

# User Service
kubectl port-forward -n microservices-challenge svc/user-service 8081:80 > /dev/null 2>&1 &
USER_PID=$!
sleep 1

# Command Service
kubectl port-forward -n microservices-challenge svc/command-service 8082:80 > /dev/null 2>&1 &
COMMAND_PID=$!
sleep 1

# Query Service
kubectl port-forward -n microservices-challenge svc/query-service 8083:80 > /dev/null 2>&1 &
QUERY_PID=$!
sleep 1

# Event Store API
kubectl port-forward -n microservices-challenge svc/event-store-api 8084:80 > /dev/null 2>&1 &
EVENT_PID=$!
sleep 1

# Order Service
kubectl port-forward -n microservices-challenge svc/order-service 8085:80 > /dev/null 2>&1 &
ORDER_PID=$!
sleep 1

# Payment Service
kubectl port-forward -n microservices-challenge svc/payment-service 8086:80 > /dev/null 2>&1 &
PAYMENT_PID=$!
sleep 1

echo ""
echo "=== 포트 포워딩 설정 완료 ==="
echo ""
echo "✅ 실행 중인 포트 포워딩:"
echo "   User Service (PID: $USER_PID)"
echo "   Command Service (PID: $COMMAND_PID)"
echo "   Query Service (PID: $QUERY_PID)"
echo "   Event Store API (PID: $EVENT_PID)"
echo "   Order Service (PID: $ORDER_PID)"
echo "   Payment Service (PID: $PAYMENT_PID)"
echo ""
echo "🌐 웹 브라우저에서 접속 가능한 URL:"
echo ""
echo "   📊 User Service:"
echo "      http://localhost:8081/api/users"
echo ""
echo "   ✍️  Command Service:"
echo "      http://localhost:8082/api/commands/create-user"
echo ""
echo "   📖 Query Service:"
echo "      http://localhost:8083/api/queries/users"
echo ""
echo "   📦 Event Store API:"
echo "      http://localhost:8084/api/events"
echo ""
echo "   🛒 Order Service:"
echo "      http://localhost:8085/api/orders"
echo ""
echo "   💳 Payment Service:"
echo "      http://localhost:8086/api/payments"
echo ""
echo "💡 팁:"
echo "   - 각 URL을 브라우저에서 열어 JSON 응답을 확인하세요"
echo "   - curl 명령어로도 테스트 가능합니다:"
echo "     curl http://localhost:8081/api/users"
echo ""
echo "🛑 종료하려면:"
echo "   ./stop-port-forward.sh"
echo ""
