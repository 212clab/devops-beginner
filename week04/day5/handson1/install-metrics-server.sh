#!/bin/bash

# Week 4 Day 5 Hands-on 1: Metrics Server 설치

set -e

echo "=== Metrics Server 설치 시작 ==="

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Kind 환경용 패치
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "Metrics Server 준비 대기 중..."
kubectl wait --for=condition=available --timeout=120s deployment/metrics-server -n kube-system

echo ""
echo "=== Metrics Server 설치 완료 ==="
echo ""
echo "확인: kubectl top nodes"
