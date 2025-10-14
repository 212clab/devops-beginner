#!/bin/bash

# Lab 1 Step 1-3: Deployment 생성 스크립트

echo "🚀 Lab 1 Step 1-3: Deployment 생성 시작..."

echo "📦 Deployment 생성 중..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  namespace: lab2-workloads
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        tier: frontend
        created-by: lab1
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF

echo "⏳ Deployment 롤아웃 대기 중..."
kubectl rollout status deployment/web-deployment --timeout=120s

echo "✅ Deployment 생성 완료!"
echo ""
echo "📊 Deployment 상태:"
kubectl get deployment web-deployment
echo ""
echo "📊 ReplicaSet 상태:"
kubectl get rs -l app=web-app
echo ""
echo "📊 Pod 상태:"
kubectl get pods -l app=web-app -o wide
echo ""
echo "🎯 롤링 업데이트 테스트:"
echo "  kubectl set image deployment/web-deployment nginx=nginx:1.21"
