#!/bin/bash

# Lab 1 Step 4-1: React 프론트엔드 배포

echo "🚀 Lab 1 Step 4-1: 프론트엔드 애플리케이션 배포 시작..."

echo "🎨 Frontend Deployment 및 Service 생성 중..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: day3-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: REACT_APP_API_URL
          value: "http://backend-service:3000"
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: day3-lab
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
  namespace: day3-lab
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

echo "⏳ Frontend Pod 시작 대기 중..."
kubectl wait --for=condition=Ready pod -l app=frontend --timeout=60s

echo "✅ 프론트엔드 애플리케이션 배포 완료!"
echo ""
echo "📊 프론트엔드 상태:"
kubectl get pods -l app=frontend
kubectl get svc frontend-service frontend-nodeport
echo ""
echo "🌐 외부 접근:"
echo "NodePort: http://localhost:30080"
echo ""
echo "🎯 다음 단계: Ingress 설정으로 도메인 기반 접근"
