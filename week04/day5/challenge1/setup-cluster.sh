#!/bin/bash

# Week 4 Day 5 Challenge 1: 클러스터 및 모니터링 설치
# 설명: Kind 클러스터 + Metrics Server + Prometheus + Kubecost

set -e

echo "=== Challenge 환경 설치 시작 ==="

# 1. 기존 클러스터 삭제
echo "1/6 기존 lab-cluster 삭제 중..."
kind delete cluster --name lab-cluster 2>/dev/null || true

# 2. 새 클러스터 생성
echo "2/6 새 lab-cluster 생성 중..."
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: lab-cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30081
    hostPort: 30081
    protocol: TCP
  - containerPort: 30082
    hostPort: 30082
    protocol: TCP
  - containerPort: 30090
    hostPort: 30090
    protocol: TCP  # Kubecost
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 80
    hostPort: 80
    protocol: TCP
- role: worker
- role: worker
EOF

# 3. Metrics Server 설치
echo "3/6 Metrics Server 설치 중..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "Metrics Server 준비 대기 중..."
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

# 4. Prometheus 설치
echo "4/6 Prometheus 설치 중..."
kubectl create namespace monitoring

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
EOF

# 5. Kubecost 설치
echo "5/6 Kubecost 설치 중..."
kubectl create namespace kubecost

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubecost
  namespace: kubecost
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubecost
  template:
    metadata:
      labels:
        app: kubecost
    spec:
      containers:
      - name: kubecost
        image: gcr.io/kubecost1/cost-model:latest
        ports:
        - containerPort: 9090
        env:
        - name: PROMETHEUS_SERVER_ENDPOINT
          value: "http://prometheus.monitoring:9090"
---
apiVersion: v1
kind: Service
metadata:
  name: kubecost
  namespace: kubecost
spec:
  type: NodePort
  selector:
    app: kubecost
  ports:
  - port: 9090
    targetPort: 9090
    nodePort: 30090
EOF

# 6. 네임스페이스 생성
echo "6/6 네임스페이스 생성 중..."
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace development

# 네임스페이스 라벨 추가 (비용 추적용)
kubectl label namespace production env=production team=platform cost-center=CC-1001
kubectl label namespace staging env=staging team=qa cost-center=CC-1002
kubectl label namespace development env=development team=dev cost-center=CC-1003

echo ""
echo "=== Challenge 환경 설치 완료 ==="
echo ""
echo "설치된 컴포넌트:"
echo "- Kind 클러스터 (1 control-plane + 2 worker)"
echo "- Metrics Server"
echo "- Prometheus (monitoring namespace)"
echo "- Kubecost (http://localhost:30090)"
echo ""
echo "생성된 네임스페이스:"
echo "- production (CC-1001)"
echo "- staging (CC-1002)"
echo "- development (CC-1003)"
echo ""
echo "다음 단계:"
echo "kubectl apply -f broken-scenario1.yaml"
echo "kubectl apply -f broken-scenario2.yaml"
echo "kubectl apply -f broken-scenario3.yaml"
echo "kubectl apply -f broken-scenario4.yaml"
