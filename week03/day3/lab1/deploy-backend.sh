#!/bin/bash

# Lab 1 Step 3-1: Node.js API 서버 배포

echo "🚀 Lab 1 Step 3-1: 백엔드 API 서버 배포 시작..."

echo "🔧 Backend Deployment 및 Service 생성 중..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: day3-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: DATABASE_URL
          value: "postgresql://shopuser:shoppass@database-service:5432/shopdb"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: day3-lab
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 80
EOF

echo "⏳ Backend Pod 시작 대기 중..."
kubectl wait --for=condition=Ready pod -l app=backend --timeout=60s

echo "✅ 백엔드 API 서버 배포 완료!"
echo ""
echo "📊 백엔드 상태:"
kubectl get pods -l app=backend
kubectl get svc backend-service
echo ""
echo "🔍 Endpoint 확인:"
kubectl get endpoints backend-service
echo ""
echo "🎯 다음 단계: 프론트엔드 애플리케이션 배포"
