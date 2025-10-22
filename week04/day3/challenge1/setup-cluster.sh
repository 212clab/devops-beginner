#!/bin/bash

# Week 4 Day 3 Challenge 1: 클러스터 및 모니터링 설치
# 설명: Kind 클러스터 + Metrics Server + Prometheus + Grafana + Istio + OPA Gatekeeper

set -e

echo "=== Challenge 환경 설치 시작 ==="

# 1. 기존 클러스터 삭제
echo "1/7 기존 클러스터 삭제 중..."
kind delete cluster --name lab-cluster 2>/dev/null || true

# 2. 새 클러스터 생성
echo "2/7 클러스터 생성 중..."
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: lab-cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
  - containerPort: 30081
    hostPort: 30081
  - containerPort: 30082
    hostPort: 30082
  - containerPort: 443
    hostPort: 443
  - containerPort: 80
    hostPort: 80
- role: worker
- role: worker
EOF

# 3. Metrics Server 설치
echo "3/7 Metrics Server 설치 중..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 4. Istio 설치
echo "4/7 Istio 설치 중..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
export PATH=$PWD/istio-1.20.0/bin:$PATH
istioctl install --set profile=demo -y

# 5. 네임스페이스 생성
echo "5/7 네임스페이스 생성 중..."
kubectl create namespace delivery-platform
kubectl label namespace delivery-platform istio-injection=enabled

# 6. OPA Gatekeeper 설치
echo "6/7 OPA Gatekeeper 설치 중..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Gatekeeper webhook 준비 대기
echo "   Gatekeeper webhook 준비 대기 중..."
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=120s
kubectl wait --for=condition=ready pod -l control-plane=audit-controller -n gatekeeper-system --timeout=120s
sleep 10  # webhook 등록 완료 대기

# 7. Prometheus & Grafana 설치 (간소화)
echo "7/7 모니터링 스택 설치 중..."
kubectl create namespace monitoring
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml

echo ""
echo "=== Challenge 환경 설치 완료 ==="
echo ""
echo "설치된 컴포넌트:"
echo "- Kind 클러스터 (1 control-plane + 2 worker)"
echo "- Metrics Server"
echo "- Istio Service Mesh"
echo "- OPA Gatekeeper"
echo "- Prometheus (모니터링)"
echo "- Grafana (시각화)"
echo ""
echo "네임스페이스:"
echo "- delivery-platform (istio-injection=enabled)"
echo ""
echo "다음 단계:"
echo "kubectl apply -f ./brokens/"
# echo "kubectl apply -f broken-scenario1.yaml"
# echo "kubectl apply -f broken-scenario2.yaml"
# echo "kubectl apply -f broken-scenario3.yaml"
# echo "kubectl apply -f broken-scenario4.yaml"
