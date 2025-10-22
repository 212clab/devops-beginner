#!/bin/bash

# Week 4 Day 3 Lab 1: 인증 시스템 테스트
# 설명: JWT 발급 및 인증 테스트

set -e

echo "=== 인증 시스템 테스트 시작 ==="

# 1. Auth Service Pod 찾기
AUTH_POD=$(kubectl get pod -n secure-app -l app=auth-service -o jsonpath='{.items[0].metadata.name}')

# 2. JWT 토큰 발급 테스트
echo "1/4 JWT 토큰 발급 테스트..."
TOKEN=$(kubectl exec -n secure-app $AUTH_POD -c auth -- python3 -c "
import urllib.request
import json

data = json.dumps({'username':'admin','password':'admin123'}).encode('utf-8')
req = urllib.request.Request('http://localhost:8080/login', data=data, headers={'Content-Type': 'application/json'})
response = urllib.request.urlopen(req)
result = json.loads(response.read().decode('utf-8'))
print(result['token'])
")

if [ -n "$TOKEN" ]; then
  echo "✅ JWT 토큰 발급 성공"
  echo "Token: ${TOKEN:0:50}..."
else
  echo "❌ JWT 토큰 발급 실패"
  exit 1
fi

# 3. JWT 검증 테스트
echo ""
echo "2/4 JWT 검증 테스트..."
VERIFY_RESULT=$(kubectl exec -n secure-app $AUTH_POD -c auth -- python3 -c "
import urllib.request
import json

req = urllib.request.Request('http://localhost:8080/verify', method='POST', headers={'Authorization': 'Bearer $TOKEN'})
response = urllib.request.urlopen(req)
result = response.read().decode('utf-8')
print(result)
")

if echo "$VERIFY_RESULT" | grep -q '"valid":true'; then
  echo "✅ JWT 검증 성공"
  echo "$VERIFY_RESULT"
else
  echo "❌ JWT 검증 실패"
  exit 1
fi

# 4. 잘못된 토큰 테스트
echo ""
echo "3/4 잘못된 토큰 테스트..."
INVALID_RESULT=$(kubectl exec -n secure-app $AUTH_POD -c auth -- python3 -c "
import urllib.request
import json

try:
    req = urllib.request.Request('http://localhost:8080/verify', method='POST', headers={'Authorization': 'Bearer invalid-token'})
    response = urllib.request.urlopen(req)
    result = response.read().decode('utf-8')
    print(result)
except urllib.error.HTTPError as e:
    print(e.read().decode('utf-8'))
" 2>&1)

if echo "$INVALID_RESULT" | grep -q '"valid":false'; then
  echo "✅ 잘못된 토큰 차단 성공"
else
  echo "❌ 잘못된 토큰 차단 실패"
  exit 1
fi

# 5. mTLS 통신 확인
echo ""
echo "4/4 mTLS 통신 확인..."
FRONTEND_POD=$(kubectl get pod -n secure-app -l app=frontend -o jsonpath='{.items[0].metadata.name}')
MTLS_TEST=$(kubectl exec -n secure-app $FRONTEND_POD -c frontend -- curl -s http://backend.secure-app.svc.cluster.local:8080/api/data)

if echo "$MTLS_TEST" | grep -q "Secure data"; then
  echo "✅ mTLS 통신 성공"
  echo "$MTLS_TEST"
else
  echo "❌ mTLS 통신 실패"
  exit 1
fi

echo ""
echo "=== 인증 시스템 테스트 완료 ==="
echo ""
echo "테스트 결과:"
echo "✅ JWT 토큰 발급"
echo "✅ JWT 토큰 검증"
echo "✅ 잘못된 토큰 차단"
echo "✅ mTLS 서비스 간 통신"
