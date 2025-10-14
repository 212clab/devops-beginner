#!/bin/bash

# Lab 1 Step 1-2: ReplicaSet 생성 스크립트

echo "🚀 Lab 1 Step 1-2: ReplicaSet 생성 시작..."

echo "📦 ReplicaSet 생성 중..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-replicaset
  namespace: lab2-workloads
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: v1
  template:
    metadata:
      labels:
        app: web
        version: v1
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

echo "⏳ ReplicaSet Pod 생성 대기 중..."
kubectl wait --for=condition=Ready pod -l app=web,version=v1 --timeout=120s

echo "✅ ReplicaSet 생성 완료!"
echo ""
echo "📊 ReplicaSet 상태:"
kubectl get rs web-replicaset
echo ""
echo "📊 생성된 Pod들:"
kubectl get pods -l app=web,version=v1 -o wide
echo ""
echo "🔍 라벨 확인:"
kubectl get pods --show-labels -l app=web
echo ""
echo "🎯 자동 복구 테스트:"
echo "  다음 명령어로 Pod 하나를 삭제해보세요:"
echo "  kubectl delete pod \$(kubectl get pods -l app=web,version=v1 -o jsonpath='{.items[0].metadata.name}')"
echo "  그리고 즉시 'kubectl get pods -l app=web,version=v1'로 확인해보세요!"
