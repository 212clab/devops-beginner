#!/bin/bash

# Handson PostgreSQL 보안 정책 생성
echo "🛡️ 네트워크 정책 수정 중: frontend 접근 허용 추가"
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-security-policy
  namespace: day3-lab
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
  egress:
  - {}  # 모든 아웃바운드 허용 (DNS 등)
EOF

# 정책 확인
echo "📊 정책 확인..."
kubectl get networkpolicy postgres-security-policy