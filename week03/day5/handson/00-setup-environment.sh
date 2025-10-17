#!/bin/bash

# Week 3 Day 5 Hands-on 1: 환경 설정 스크립트

echo "=== Hands-on 1 환경 설정 시작 ==="

# 1. 클러스터 확인 및 생성
echo "1. Kubernetes 클러스터 확인 중..."
if ! kind get clusters | grep -q "challenge-cluster"; then
    echo "클러스터가 없습니다. 생성 중..."
    kind create cluster --name challenge-cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
else
    echo "✅ 클러스터 이미 존재"
fi

# 2. Namespace 생성
echo "2. Namespace 생성 중..."
kubectl create namespace day5-handson --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace 생성 완료"

# 3. Helm 저장소 추가
echo "3. Helm 저장소 설정 중..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
echo "✅ Helm 저장소 추가 완료"

# 4. Prometheus Operator 설치
echo "4. Prometheus Operator 설치 중..."
if ! kubectl get crd servicemonitors.monitoring.coreos.com &> /dev/null; then
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
    echo "✅ Prometheus Operator 설치 완료"
else
    echo "✅ Prometheus Operator 이미 설치됨"
fi

# 5. Metrics Server 설치
echo "5. Metrics Server 설치 중..."
if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    echo "✅ Metrics Server 설치 완료"
else
    echo "✅ Metrics Server 이미 설치됨"
fi

echo ""
echo "=== 환경 설정 완료 ==="
echo ""
echo "설치된 구성 요소:"
echo "- Kubernetes 클러스터: challenge-cluster"
echo "- Namespace: day5-handson, monitoring"
echo "- Helm 저장소: prometheus-community, bitnami"
echo "- Prometheus Operator (ServiceMonitor CRD 포함)"
echo "- Metrics Server"
echo ""
echo "다음 명령어로 확인:"
echo "  kubectl get nodes"
echo "  kubectl get namespace"
echo "  helm repo list"
echo "  kubectl get crd | grep monitoring"
