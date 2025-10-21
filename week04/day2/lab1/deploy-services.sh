#!/bin/bash

# Lab 1: Kong API Gateway - 백엔드 서비스 배포

echo "=== 백엔드 마이크로서비스 배포 시작 ==="
echo ""

# 0. backend 네임스페이스 생성
echo "0. backend 네임스페이스 생성 중..."
kubectl create namespace backend 2>/dev/null || echo "   ⚠️  backend 네임스페이스 이미 존재"
echo "   ✅ backend 네임스페이스 준비 완료"

# 1. User Service 배포
echo ""
echo "1. User Service 배포 중..."
kubectl apply -n backend -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: hashicorp/http-echo:latest
        args:
        - "-text=User Service Response"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
EOF
echo "   ✅ User Service 배포 완료"

# 2. Product Service 배포
echo ""
echo "2. Product Service 배포 중..."
kubectl apply -n backend -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: hashicorp/http-echo:latest
        args:
        - "-text=Product Service Response"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
spec:
  selector:
    app: product-service
  ports:
  - port: 80
    targetPort: 8080
EOF
echo "   ✅ Product Service 배포 완료"

# 3. Order Service 배포
echo ""
echo "3. Order Service 배포 중..."
kubectl apply -n backend -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: hashicorp/http-echo:latest
        args:
        - "-text=Order Service Response"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
  - port: 80
    targetPort: 8080
EOF
echo "   ✅ Order Service 배포 완료"

# 4. Pod 준비 대기
echo ""
echo "4. Pod 준비 대기 중..."
kubectl wait --for=condition=ready pod -l app=user-service -n backend --timeout=60s
kubectl wait --for=condition=ready pod -l app=product-service -n backend --timeout=60s
kubectl wait --for=condition=ready pod -l app=order-service -n backend --timeout=60s

# 5. 서비스 상태 확인
echo ""
echo "5. 서비스 상태 확인 중..."
kubectl get pods -n backend
echo ""
kubectl get svc -n backend

echo ""
echo "=== 백엔드 서비스 배포 완료 ==="
echo ""
echo "배포된 서비스 (backend 네임스페이스):"
echo "   - user-service (2 replicas)"
echo "   - product-service (2 replicas)"
echo "   - order-service (2 replicas)"
echo ""
echo "다음 단계: ./configure-kong.sh"
