#!/bin/bash

# Week 4 Day 3 Lab 1: Istio 설치
# 설명: Istio 다운로드 및 설치, 네임스페이스 설정

set -e

echo "=== Istio 설치 시작 ==="

# 1. Istio 다운로드
echo "1/4 Istio 다운로드 중..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -

# 2. istioctl PATH 추가
export PATH=$PWD/istio-1.20.0/bin:$PATH

# 3. Istio 설치
echo "2/4 Istio 설치 중..."
istioctl install --set profile=demo -y

# 4. 네임스페이스 생성 및 자동 주입 활성화
echo "3/4 네임스페이스 설정 중..."
kubectl create namespace secure-app
kubectl label namespace secure-app istio-injection=enabled

# 5. 설치 확인
echo "4/4 설치 확인 중..."
kubectl get pods -n istio-system
kubectl get namespace secure-app --show-labels

echo ""
echo "=== Istio 설치 완료 ==="
echo ""
echo "설치된 컴포넌트:"
echo "- Istiod (Control Plane)"
echo "- Istio Ingress Gateway"
echo "- Istio Egress Gateway"
echo ""
echo "네임스페이스:"
echo "- secure-app (istio-injection=enabled)"
