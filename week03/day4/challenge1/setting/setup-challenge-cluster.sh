#!/bin/bash

# Week 3 Day 4 Challenge 1: Challenge 클러스터 설정
# 사용법: ./setup-challenge-cluster.sh

set -e

CLUSTER_NAME="day4-challenge"

echo "=== Challenge 클러스터 설정 시작 ==="

# 기존 클러스터 확인
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "기존 ${CLUSTER_NAME} 클러스터 발견"
    read -p "기존 클러스터를 삭제하고 새로 생성하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "기존 클러스터 삭제 중..."
        kind delete cluster --name ${CLUSTER_NAME}
    else
        echo "기존 클러스터 사용"
        kubectl cluster-info --context kind-${CLUSTER_NAME}
        exit 0
    fi
fi

# Kind 클러스터 생성
echo "1/3 Kind 클러스터 생성 중..."
cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF

# 클러스터 상태 확인
echo "2/3 클러스터 상태 확인 중..."
kubectl cluster-info --context kind-${CLUSTER_NAME}
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Calico 설치 (Network Policy 지원)
echo "3/3 Calico CNI 설치 중..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=180s

echo ""
echo "=== Challenge 클러스터 설정 완료 ==="
echo ""
echo "클러스터 정보:"
echo "- 이름: ${CLUSTER_NAME}"
echo "- 노드: 1 control-plane + 2 workers"
echo "- CNI: Calico (Network Policy 지원)"
echo ""
echo "다음 단계: ./deploy-broken-system.sh 실행"
