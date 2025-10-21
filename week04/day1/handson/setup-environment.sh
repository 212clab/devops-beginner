#!/bin/bash

# Week 4 Day 1 Hands-on 1: Kubernetes Native 환경 설정
# 사용법: ./setup-environment.sh

echo "=== Week 4 Day 1 Hands-on 1 환경 설정 시작 ==="

# 에러 발생 시 스크립트 중단
set -e

# 진행 상황 표시 함수
show_progress() {
    echo ""
    echo "🔄 $1"
    echo "----------------------------------------"
}

# 네임스페이스 확인 및 생성
show_progress "1/6 네임스페이스 설정"
if kubectl get namespace ecommerce-advanced >/dev/null 2>&1; then
    echo "✅ ecommerce-advanced 네임스페이스 이미 존재"
else
    kubectl create namespace ecommerce-advanced
    echo "✅ ecommerce-advanced 네임스페이스 생성 완료"
fi

if kubectl get namespace testing >/dev/null 2>&1; then
    echo "✅ testing 네임스페이스 이미 존재"
else
    kubectl create namespace testing
    echo "✅ testing 네임스페이스 생성 완료"
fi

# Nginx Ingress Controller 설치 확인
show_progress "2/6 Nginx Ingress Controller 설정"
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    echo "✅ Nginx Ingress Controller 이미 설치됨"
else
    echo "📦 Nginx Ingress Controller 설치 중..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    echo "⏳ Ingress Controller 준비 대기 중..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    echo "✅ Nginx Ingress Controller 설치 완료"
fi

# Load Tester 배포 (테스트용)
show_progress "3/6 Load Tester 배포"
if kubectl get deployment load-tester -n testing >/dev/null 2>&1; then
    echo "✅ Load Tester 이미 배포됨"
else
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-tester
  namespace: testing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-tester
  template:
    metadata:
      labels:
        app: load-tester
    spec:
      containers:
      - name: load-tester
        image: curlimages/curl:latest
        command: ['sleep', '3600']
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
EOF
    
    echo "⏳ Load Tester 준비 대기 중..."
    kubectl wait --for=condition=available --timeout=300s deployment/load-tester -n testing
    echo "✅ Load Tester 배포 완료"
fi

# User Service 배포 (Lab 1에서 이미 있다면 스킵)
show_progress "4/6 기본 User Service 확인"
if kubectl get deployment user-service -n ecommerce-advanced >/dev/null 2>&1; then
    echo "✅ User Service 이미 배포됨"
else
    echo "📦 기본 User Service 배포 중..."
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: ecommerce-advanced
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
        image: nginx:1.25
        ports:
        - containerPort: 80
        volumeMounts:
        - name: user-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: user-config
        configMap:
          name: user-service-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: ecommerce-advanced
data:
  default.conf: |
    server {
        listen 80;
        location /api/users {
            return 200 '{"service": "user-service", "users": [{"id": 1, "name": "John Doe"}], "total": 1}';
            add_header Content-Type application/json;
        }
        location /health {
            return 200 '{"service": "user-service", "status": "healthy"}';
            add_header Content-Type application/json;
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: ecommerce-advanced
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 80
EOF
    echo "✅ User Service 배포 완료"
fi

# 기본 Ingress 설정
show_progress "5/6 기본 Ingress 설정"
if kubectl get ingress ecommerce-ingress -n ecommerce-advanced >/dev/null 2>&1; then
    echo "✅ Ingress 이미 설정됨"
else
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce-advanced
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: api.local
    http:
      paths:
      - path: /api/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
EOF
    echo "✅ 기본 Ingress 설정 완료"
fi

# 환경 검증
show_progress "6/6 환경 검증"
echo "🔍 배포된 리소스 확인:"
echo ""
echo "📦 Pods:"
kubectl get pods -n ecommerce-advanced
echo ""
echo "🌐 Services:"
kubectl get svc -n ecommerce-advanced
echo ""
echo "🚪 Ingress:"
kubectl get ingress -n ecommerce-advanced
echo ""

# 연결 테스트
echo "🧪 연결 테스트:"
if kubectl exec -n testing deployment/load-tester -- curl -s http://user-service.ecommerce-advanced.svc.cluster.local/health >/dev/null 2>&1; then
    echo "✅ 서비스 간 통신 정상"
else
    echo "⚠️  서비스 간 통신 확인 필요"
fi

echo ""
echo "=== Week 4 Day 1 Hands-on 1 환경 설정 완료 ==="
echo ""
echo "🎯 준비된 환경:"
echo "- ✅ Kubernetes Native 네트워킹 (Nginx Ingress)"
echo "- ✅ 기본 마이크로서비스 (User Service)"
echo "- ✅ 테스트 환경 (Load Tester)"
echo "- ✅ 네임스페이스 분리 (ecommerce-advanced, testing)"
echo ""
echo "🚀 이제 Hands-on 1 실습을 시작할 수 있습니다!"
echo ""
