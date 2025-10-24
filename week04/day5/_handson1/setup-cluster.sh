#!/bin/bash

# Week 4 Day 5 Hands-on 1: 클러스터 초기화
# 설명: 기존 클러스터 삭제 및 새 클러스터 생성 (CloudMart + 모니터링용)

set -e

echo "=== Hands-on 클러스터 초기화 시작 ==="

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
  # CloudMart 서비스 포트
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30081
    hostPort: 30081
    protocol: TCP
  - containerPort: 30082
    hostPort: 30082
    protocol: TCP
  # 기본 웹 포트
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  # 모니터링 도구 포트
  - containerPort: 30090
    hostPort: 30090
    protocol: TCP  # Kubecost
  - containerPort: 30091
    hostPort: 30091
    protocol: TCP  # Grafana
  - containerPort: 30092
    hostPort: 30092
    protocol: TCP  # Jaeger UI
- role: worker
- role: worker
EOF

# 3. 클러스터 확인
echo "3/3 클러스터 상태 확인 중..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "=== Hands-on 클러스터 초기화 완료 ==="
echo ""
echo "클러스터 정보:"
echo "- 이름: lab-cluster"
echo "- Control Plane: 1개"
echo "- Worker Node: 2개"
echo "- 오픈 포트:"
echo "  * 30080-30082: CloudMart 서비스"
echo "  * 30090: Kubecost"
echo "  * 30091: Grafana"
echo "  * 30092: Jaeger UI"
