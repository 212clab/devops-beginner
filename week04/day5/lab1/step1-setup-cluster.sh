#!/bin/bash

# Week 4 Day 5 Lab 1: 클러스터 초기화
# 설명: 기존 클러스터 삭제 및 새로운 lab-cluster 생성
# 사용법: ./step1-setup-cluster.sh

set -e

echo "=== Lab 클러스터 초기화 시작 ==="

# 1. 기존 클러스터 삭제
echo "1/3 기존 lab-cluster 삭제 중..."
kind delete cluster --name lab-cluster 2>/dev/null || true

# 2. 새 클러스터 생성
echo "2/3 새 lab-cluster 생성 중..."
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
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 80
    hostPort: 80
    protocol: TCP
- role: worker
- role: worker
EOF

# 3. 클러스터 확인
echo "3/3 클러스터 상태 확인 중..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "=== Lab 클러스터 초기화 완료 ==="
echo ""
echo "클러스터 정보:"
echo "- 이름: lab-cluster"
echo "- Control Plane: 1개"
echo "- Worker Node: 2개"
echo "- 오픈 포트: 30080-30081, 443, 80"
echo ""
echo "다음 단계: ./step2-install-metrics-server.sh"
