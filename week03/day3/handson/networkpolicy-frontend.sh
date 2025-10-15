#!/bin/bash

# Handson Frontend 보안 정책 생성
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: day3-lab
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []  # Ingress Controller에서만 접근
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 3000
  - to: # DNS 접근 허용
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF

# 정책 적용 확인
kubectl get networkpolicy
# 백엔드에서 데이터베이스 접근 테스트 (성공해야 함)
kubectl exec -it deployment/backend -- nc -zv database-service 5432
# -w 3: 3초 동안 연결이 성공하거나 실패하지 않으면 종료
# kubectl exec -it deployment/frontend -- nc -zw 3 database-service 5432