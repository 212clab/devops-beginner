#!/bin/bash

# Lab 1: Kong API Gateway - 플러그인 적용

echo "=== Kong 플러그인 적용 시작 ==="
echo ""

# 1. Rate Limiting 플러그인 (User Service)
echo "1. Rate Limiting 플러그인 적용 중 (User Service)..."
curl -s -X POST http://localhost:8001/services/user-service/plugins \
  --data name=rate-limiting \
  --data config.minute=10 \
  --data config.policy=local > /dev/null
echo "   ✅ Rate Limiting 적용 완료 (10 req/min)"

# 2. Key Authentication 플러그인 (Product Service)
echo ""
echo "2. Key Authentication 플러그인 적용 중 (Product Service)..."
curl -s -X POST http://localhost:8001/services/product-service/plugins \
  --data name=key-auth > /dev/null
echo "   ✅ Key Auth 플러그인 적용 완료"

# Consumer 생성
echo "   Consumer 생성 중..."
curl -s -X POST http://localhost:8001/consumers \
  --data username=testuser > /dev/null
echo "   ✅ Consumer 'testuser' 생성 완료"

# API Key 생성
echo "   API Key 생성 중..."
curl -s -X POST http://localhost:8001/consumers/testuser/key-auth \
  --data key=my-secret-key > /dev/null
echo "   ✅ API Key 'my-secret-key' 생성 완료"

# 3. CORS 플러그인 (Order Service)
echo ""
echo "3. CORS 플러그인 적용 중 (Order Service)..."
curl -s -X POST http://localhost:8001/services/order-service/plugins \
  --data name=cors \
  --data config.origins=* \
  --data config.methods=GET,POST,PUT,DELETE \
  --data config.headers=Accept,Content-Type,Authorization > /dev/null
echo "   ✅ CORS 플러그인 적용 완료"

# 4. 플러그인 확인
echo ""
echo "4. 적용된 플러그인 확인 중..."
echo ""
echo "📋 User Service 플러그인:"
curl -s http://localhost:8001/services/user-service/plugins | jq -r '.data[] | "   - \(.name)"'

echo ""
echo "📋 Product Service 플러그인:"
curl -s http://localhost:8001/services/product-service/plugins | jq -r '.data[] | "   - \(.name)"'

echo ""
echo "📋 Order Service 플러그인:"
curl -s http://localhost:8001/services/order-service/plugins | jq -r '.data[] | "   - \(.name)"'

# 5. 플러그인 테스트
echo ""
echo "5. 플러그인 테스트 중..."
echo ""

echo "🧪 Rate Limiting 테스트 (User Service):"
echo "   처음 10번은 성공, 11번째부터 429 에러 예상"
for i in {1..3}; do
  echo -n "   Request $i: "
  curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/users
  echo ""
done

echo ""
echo "🧪 Key Authentication 테스트 (Product Service):"
echo -n "   인증 없이 호출 (401 예상): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/products
echo ""
echo -n "   API Key로 호출 (200 예상): "
curl -s -o /dev/null -w "%{http_code}" -H "apikey: my-secret-key" http://localhost:8000/products
echo ""

echo ""
echo "🧪 CORS 테스트 (Order Service):"
echo "   CORS 헤더 확인:"
curl -s -I -X OPTIONS http://localhost:8000/orders \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: GET" | grep -i "access-control"

echo ""
echo "=== Kong 플러그인 적용 완료 ==="
echo ""
echo "📍 테스트 명령어:"
echo "   # Rate Limiting 테스트"
echo "   for i in {1..15}; do curl http://localhost:8000/users; done"
echo ""
echo "   # Key Auth 테스트"
echo "   curl http://localhost:8000/products  # 401 에러"
echo "   curl -H 'apikey: my-secret-key' http://localhost:8000/products  # 성공"
echo ""
echo "   # CORS 테스트"
echo "   curl -I -X OPTIONS http://localhost:8000/orders -H 'Origin: http://example.com'"
