#!/bin/bash

# Hands-on 1: Istio Service Mesh - 환경 정리

echo "=== Istio 환경 정리 시작 ==="
echo ""

# 1. Istio 리소스 삭제
echo "1. Istio 리소스 삭제 중..."
kubectl delete gateway app-gateway -n backend 2>/dev/null
kubectl delete virtualservice --all -n backend 2>/dev/null
kubectl delete destinationrule --all -n backend 2>/dev/null
echo "   ✅ Istio 리소스 삭제 완료"

# 2. Istio 배포 Deployment 삭제
echo ""
echo "2. Istio 배포 Deployment 삭제 중..."
kubectl delete deployment user-service-v1 user-service-v2 product-service order-service -n backend 2>/dev/null
echo "   ✅ Istio 배포 Deployment 삭제 완료"

# 3. Lab 1용 Deployment 재배포 (version 라벨 없이)
echo ""
echo "3. Lab 1용 Deployment 재배포 중..."
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
EOF
echo "   ✅ Lab 1용 Deployment 재배포 완료"

# 4. Istio 언인스톨
echo ""
echo "4. Istio 언인스톨 중..."
cd /tmp/istio-1.20.0 2>/dev/null
export PATH=$PWD/bin:$PATH
istioctl uninstall --purge -y
echo "   ✅ Istio 언인스톨 완료"

# 5. Istio 네임스페이스 삭제
echo ""
echo "5. Istio 네임스페이스 삭제 중..."
kubectl delete namespace istio-system
echo "   ✅ Istio 네임스페이스 삭제 완료"

# 6. Sidecar 주입 비활성화
echo ""
echo "6. Sidecar 주입 비활성화 중..."
kubectl label namespace backend istio-injection-
echo "   ✅ Sidecar 주입 비활성화 완료"

# 7. Pod 재시작 대기 (Sidecar 제거)
echo ""
echo "7. Pod 재시작 대기 중 (Sidecar 제거)..."
kubectl wait --for=condition=ready pod -l app=user-service -n backend --timeout=120s
kubectl wait --for=condition=ready pod -l app=product-service -n backend --timeout=120s
kubectl wait --for=condition=ready pod -l app=order-service -n backend --timeout=120s
echo "   ✅ Pod 재시작 완료"

echo ""
echo "=== Istio 환경 정리 완료 ==="
echo ""
echo "💡 백엔드 서비스는 유지됩니다 (backend 네임스페이스)."
echo "   Kong Lab을 다시 실행할 수 있습니다."
echo ""
echo "💡 백엔드 서비스 삭제가 필요한 경우:"
echo "   kubectl delete namespace backend"
echo ""
echo "💡 클러스터 삭제가 필요한 경우:"
echo "   kind delete cluster --name lab-cluster"
