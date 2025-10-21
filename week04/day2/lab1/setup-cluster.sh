#!/bin/bash

# Lab 1: Kong API Gateway - 클러스터 생성

echo "=== Kong API Gateway Lab - 클러스터 생성 시작 ==="
echo ""

# 1. 기존 클러스터 확인 및 삭제
echo "1. 기존 클러스터 확인 중..."
if kind get clusters | grep -q "lab-cluster"; then
    echo "   ⚠️  기존 lab-cluster 발견"
    echo "   🗑️  기존 클러스터 삭제 중..."
    kind delete cluster --name lab-cluster
    echo "   ✅ 기존 클러스터 삭제 완료"
fi

# 2. Kind 클러스터 생성 (포트 매핑)
echo ""
echo "2. Kind 클러스터 생성 중 (포트 8000, 8001 매핑)..."
cat <<YAML | kind create cluster --name lab-cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8000
    protocol: TCP
  - containerPort: 30081
    hostPort: 8001
    protocol: TCP
  - containerPort: 30082
    hostPort: 8080
    protocol: TCP
YAML

echo "   ✅ 클러스터 생성 완료"

# 3. kubectl 컨텍스트 설정
echo ""
echo "3. kubectl 컨텍스트 설정 중..."
kubectl config use-context kind-lab-cluster
echo "   ✅ 컨텍스트 설정 완료"

# 4. Metrics Server 설치 (non-TLS 모드)
echo ""
echo "4. Metrics Server 설치 중 (non-TLS 모드)..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Metrics Server non-TLS 설정
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

echo "   ⏳ Metrics Server 준비 대기 중..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s
echo "   ✅ Metrics Server 설치 완료"

# 5. Kubernetes Dashboard 설치
echo ""
echo "5. Kubernetes Dashboard 설치 중..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

echo "   ⏳ Dashboard 준비 대기 중..."
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s
echo "   ✅ Kubernetes Dashboard 설치 완료"

# 6. 클러스터 상태 확인
echo ""
echo "6. 클러스터 상태 확인 중..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "=== 클러스터 생성 완료 ==="
echo ""
echo "📍 포트 매핑:"
echo "   - Kong Proxy: localhost:8000 → NodePort 30080"
echo "   - Kong Admin: localhost:8001 → NodePort 30081"
echo ""
echo "📊 설치된 컴포넌트:"
echo "   - Metrics Server (non-TLS 모드)"
echo "   - Kubernetes Dashboard"
echo ""
echo "💡 Dashboard 접근:"
echo "   kubectl proxy"
echo "   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "다음 단계: ./install-kong.sh"
