#!/bin/bash

# Lab 1 Step 1-1: 기본 Pod 생성 스크립트

echo "🚀 Lab 1 Step 1-1: 기본 Pod 생성 시작..."

# 네임스페이스 확인
if ! kubectl get namespace lab2-workloads >/dev/null 2>&1; then
    echo "📦 네임스페이스 생성 중..."
    kubectl create namespace lab2-workloads
fi

kubectl config set-context --current --namespace=lab2-workloads

echo "📱 기본 Pod 생성 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  namespace: lab2-workloads
  labels:
    app: web
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

echo "⏳ Pod 시작 대기 중..."
kubectl wait --for=condition=Ready pod/web-pod --timeout=60s

echo "✅ 기본 Pod 생성 완료!"
echo ""
echo "📊 Pod 상태:"
kubectl get pods web-pod -o wide
echo ""
echo "🔍 Pod 상세 정보:"
kubectl describe pod web-pod | head -20
echo ""
echo "🎯 다음 단계: ReplicaSet 생성으로 복제본 관리 체험"
