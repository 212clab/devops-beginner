#!/bin/bash

# 필요 도구 설치 스크립트

echo "=== Installing Required Tools ==="

# Kind 설치 (로컬 클러스터)
echo "Installing Kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# kubectl 설치 확인
echo "Checking kubectl..."
kubectl version --client

# etcdctl 설치
echo "Installing etcdctl..."
ETCD_VER=v3.5.9
curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/

echo "Tool installation completed!"