#!/bin/bash

# Week 4 Day 5 Hands-on 1: Jaeger 설치
# 설명: Jaeger All-in-One 설치 및 외부 접근 설정

set -e

echo "=== Jaeger 설치 시작 ==="

# 1. Namespace 생성
echo "1/3 tracing 네임스페이스 생성 중..."
kubectl create namespace tracing --dry-run=client -o yaml | kubectl apply -f -

# 2. Jaeger 배포
echo "2/3 Jaeger 배포 중..."
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: tracing
  labels:
    app: jaeger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.50
        ports:
        - containerPort: 16686
          name: query
        - containerPort: 14268
          name: collector
        - containerPort: 6831
          name: agent-compact
          protocol: UDP
        env:
        - name: COLLECTOR_ZIPKIN_HOST_PORT
          value: ":9411"
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-query
  namespace: tracing
  labels:
    app: jaeger
spec:
  type: ClusterIP
  selector:
    app: jaeger
  ports:
  - port: 16686
    targetPort: 16686
    name: query
  - port: 14268
    targetPort: 14268
    name: collector
  - port: 6831
    targetPort: 6831
    protocol: UDP
    name: agent-compact
EOF

# 3. 배포 완료 대기
echo "3/3 Jaeger 배포 완료 대기 중..."
kubectl wait --for=condition=available deployment/jaeger -n tracing --timeout=120s

echo ""
echo "=== Jaeger 설치 완료 ==="
echo ""
echo "Jaeger 정보:"
echo "- Namespace: tracing"
echo "- Service: jaeger-query"
echo "- UI Port: 16686 (포트포워딩 필요)"
echo ""
echo "포트포워딩:"
echo "kubectl port-forward -n tracing svc/jaeger-query 16686:16686"
