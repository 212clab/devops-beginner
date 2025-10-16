#!/bin/bash

# Week 3 Day 4 Lab 1: Network Policy 보안 강화
# 사용법: ./setup-network-policies.sh

set -e

echo "=== Network Policy 보안 강화 시작 ==="

# 네임스페이스 간 격리 정책
echo "1/3 네임스페이스 간 격리 정책 생성 중..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: development
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
EOF

# 데이터베이스 접근 제한 정책
echo "2/3 데이터베이스 접근 제한 정책 생성 중..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
      tier: data
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
          tier: api
    ports:
    - protocol: TCP
      port: 5432
EOF

# API 서버 접근 제한 정책
echo "3/3 API 서버 접근 제한 정책 생성 중..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
      tier: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
          tier: web
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF

echo ""
echo "=== Network Policy 보안 강화 완료 ==="
echo ""
echo "생성된 Network Policy:"
echo "- deny-from-other-namespaces (development)"
echo "- deny-from-other-namespaces (production)"
echo "- database-policy (production)"
echo "- backend-policy (production)"
echo ""
echo "Network Policy 확인:"
kubectl get networkpolicy -n development
kubectl get networkpolicy -n production
