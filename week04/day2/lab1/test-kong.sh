#!/bin/bash

# Lab 1: Kong API Gateway - 라우팅 테스트

echo "=== Kong 라우팅 테스트 시작 ==="
echo ""

# 1. User Service 테스트 (Rate Limiting 적용)
echo "1. User Service 테스트 (Rate Limiting: 10 req/min):"
echo ""
for i in {1..3}; do
  echo "   Request $i:"
  curl -s http://localhost:8000/users
  echo ""
done

# 2. Product Service 테스트 (Key Auth 필요)
echo ""
echo "2. Product Service 테스트 (Key Authentication):"
echo ""
echo "   인증 없이 호출 (실패 예상):"
curl -i http://localhost:8000/products 2>&1 | grep -E "HTTP|message"
echo ""

echo "   API Key로 호출 (성공 예상):"
curl -s -H "apikey: my-secret-key" http://localhost:8000/products
echo ""

# 3. Order Service 테스트 (CORS 적용)
echo ""
echo "3. Order Service 테스트 (CORS):"
echo ""
curl -s http://localhost:8000/orders
echo ""

echo ""
echo "=== 테스트 완료 ==="
echo ""
echo "📍 테스트 URL:"
echo "   - User Service: http://localhost:8000/users"
echo "   - Product Service: http://localhost:8000/products (API Key 필요)"
echo "   - Order Service: http://localhost:8000/orders"
