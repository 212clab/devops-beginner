#!/bin/bash

# Week 3 Day 5 Lab 1: 테스트 애플리케이션 배포
# 사용법: ./03-deploy-app.sh

set -e

NAMESPACE="day5-lab"

echo "=== 테스트 애플리케이션 배포 시작 ==="
echo ""

# Namespace 확인
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "❌ Namespace '$NAMESPACE'가 존재하지 않습니다."
    echo "먼저 ./00-setup-cluster.sh를 실행하세요."
    exit 1
fi

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Deployment 생성
echo "1. Deployment 생성 중..."
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: nginxinc/nginx-unprivileged:1.25
        ports:
        - containerPort: 8080
          name: http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF

echo "✅ Deployment 생성 완료"

# Service 생성
echo ""
echo "2. Service 생성 중..."
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
  type: ClusterIP
EOF

echo "✅ Service 생성 완료"

# ServiceMonitor 생성
echo ""
echo "3. ServiceMonitor 생성 중..."
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  selector:
    matchLabels:
      app: web-app
  endpoints:
  - port: http
    interval: 30s
EOF

echo "✅ ServiceMonitor 생성 완료"

# Pod 준비 대기
echo ""
echo "4. Pod 준비 대기 중..."
kubectl wait --for=condition=ready pod -l app=web-app -n $NAMESPACE --timeout=120s || true

# 배포 확인
echo ""
echo "5. 배포 상태 확인 중..."
echo ""

echo "🔍 Pod 상태:"
kubectl get pods -n $NAMESPACE -l app=web-app

echo ""
echo "🌐 Service 상태:"
kubectl get svc -n $NAMESPACE web-app

echo ""
echo "📊 ServiceMonitor 상태:"
kubectl get servicemonitor -n $NAMESPACE web-app

echo ""
echo "=== 배포 완료 ==="
echo ""
echo "💡 애플리케이션 접속:"
echo "   kubectl port-forward -n $NAMESPACE svc/web-app 8080:80"
echo "   http://localhost:8080"

# 임시 디렉토리 정리
cd - > /dev/null
rm -rf "$TEMP_DIR"
