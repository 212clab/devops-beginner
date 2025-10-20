#!/bin/bash

# Week 4 Day 1 Lab 1: 클러스터 환경 설정
# 사용법: ./setup-cluster.sh

echo "=== Kubernetes 클러스터 환경 설정 시작 ==="
echo ""

set -e
trap 'echo "❌ 스크립트 실행 중 오류 발생"' ERR

echo "1/3 Kind 클러스터 생성 중..."
kind create cluster --name lab-cluster --config manifests/cluster/kind-config.yaml

echo "2/3 Nginx Ingress Controller 설치 중..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "3/3 Ingress Controller 준비 대기 중..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo ""
echo "=== 클러스터 환경 설정 완료 ==="
echo ""
echo "클러스터 정보:"
kubectl cluster-info
echo ""
echo "노드 상태:"
kubectl get nodes
echo ""
echo "✅ 실습 환경 준비 완료!"
