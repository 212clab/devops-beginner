#!/bin/bash

echo "=== CloudMart 네트워크 연결 테스트 ==="

# 1. 네임스페이스 확인
echo "1. 네임스페이스 상태 확인"
kubectl get namespaces

# 2. 서비스 상태 확인
echo "2. 서비스 상태 확인"
kubectl get services --all-namespaces

# 3. Ingress 상태 확인
echo "3. Ingress 상태 확인"
kubectl get ingress --all-namespaces

# 4. 데이터베이스 연결 테스트
echo "4. 데이터베이스 연결 테스트"
kubectl exec -n backend deployment/user-service -- nc -zv postgres-user-service.data.svc.cluster.local 5432

# 5. API 서비스 간 통신 테스트
echo "5. API 서비스 간 통신 테스트"
kubectl exec -n frontend deployment/web-frontend -- curl -s user-service.backend.svc.cluster.local:8080/health

# 6. 외부 접근 테스트
echo "6. 외부 접근 테스트"
curl -H "Host: shop.example.com" http://$(minikube ip)/

echo "=== 테스트 완료 ==="