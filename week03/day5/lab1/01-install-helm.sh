#!/bin/bash

# Week 3 Day 5 Lab 1: Helm 설치
# 사용법: ./01-install-helm.sh

set -e

echo "=== Helm 설치 시작 ==="
echo ""

# OS 감지
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "감지된 OS: ${MACHINE}"
echo ""

# Helm 설치
if command -v helm &> /dev/null; then
    echo "✅ Helm이 이미 설치되어 있습니다."
    helm version
else
    echo "📦 Helm 설치 중..."
    
    if [ "${MACHINE}" = "Mac" ]; then
        if command -v brew &> /dev/null; then
            brew install helm
        else
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        fi
    else
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    echo "✅ Helm 설치 완료"
    helm version
fi

echo ""
echo "=== Helm Repository 추가 ==="
echo ""

# Prometheus Community
echo "1. Prometheus Community Repository 추가 중..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Grafana
echo "2. Grafana Repository 추가 중..."
helm repo add grafana https://grafana.github.io/helm-charts

# ArgoCD
echo "3. ArgoCD Repository 추가 중..."
helm repo add argo https://argoproj.github.io/argo-helm

# Repository 업데이트
echo ""
echo "📦 Repository 업데이트 중..."
helm repo update

echo ""
echo "=== 추가된 Repository 목록 ==="
helm repo list

echo ""
echo "=== Helm 설치 완료 ==="
