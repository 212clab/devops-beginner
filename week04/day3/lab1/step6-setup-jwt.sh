#!/bin/bash

# Week 4 Day 3 Lab 1: JWT 인증 설정
# 설명: RequestAuthentication 및 AuthorizationPolicy 설정

set -e

echo "=== JWT 인증 설정 시작 ==="

# 1. RequestAuthentication 설정
echo "1/3 RequestAuthentication 설정 중..."
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: secure-app
spec:
  selector:
    matchLabels:
      app: frontend
  jwtRules:
  - issuer: "auth-service"
    jwksUri: "http://auth-service.secure-app.svc.cluster.local:8080/.well-known/jwks.json"
    forwardOriginalToken: true
EOF

# 2. AuthorizationPolicy - JWT 필수
echo "2/3 AuthorizationPolicy 설정 중..."
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: secure-app
spec:
  selector:
    matchLabels:
      app: frontend
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: backend-policy
  namespace: secure-app
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/secure-app/sa/frontend"]
EOF

# 3. 설정 확인
echo "3/3 설정 확인 중..."
kubectl get requestauthentication -n secure-app
kubectl get authorizationpolicy -n secure-app

echo ""
echo "=== JWT 인증 설정 완료 ==="
echo ""
echo "적용된 정책:"
echo "- RequestAuthentication: JWT 검증"
echo "- AuthorizationPolicy: JWT 필수 + 서비스 간 인가"
echo ""
echo "보안 효과:"
echo "- Frontend: JWT 토큰 필수"
echo "- Backend: Frontend 서비스만 접근 가능"
