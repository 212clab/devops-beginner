#!/bin/bash

# Kind 클러스터 생성 스크립트

echo "=== Creating Kind Cluster ==="

# 클러스터 생성
kind create cluster --config kind-config.yaml

# 클러스터 상태 확인
echo "Checking cluster status..."
kubectl cluster-info
kubectl get nodes -o wide

# 클러스터 정보 수집
echo "Collecting cluster information..."
kubectl cluster-info dump > cluster-info.txt

# 노드 상세 정보
kubectl describe nodes > nodes-detail.txt

# 시스템 네임스페이스 확인
kubectl get all -n kube-system > system-resources.txt

echo "Cluster creation completed!"
echo "Files created:"
echo "- cluster-info.txt"
echo "- nodes-detail.txt" 
echo "- system-resources.txt"