#!/bin/bash

# Week 3 Day 5 Lab 1: ArgoCD 설치
# 사용법: ./05-install-argocd.sh

set -e

echo "=== ArgoCD 설치 시작 ==="
echo ""

# Namespace 생성
echo "1. argocd Namespace 생성 중..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace 생성 완료"

# ArgoCD 설치
echo ""
echo "2. ArgoCD 설치 중..."
echo "   (약 2-3분 소요됩니다)"

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "✅ ArgoCD 설치 완료"

# Pod 준비 대기
echo ""
echo "3. ArgoCD Pod 준비 대기 중..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# 설치 확인
echo ""
echo "4. 설치 확인 중..."
echo ""

echo "🔍 Pod 상태:"
kubectl get pods -n argocd

echo ""
echo "🌐 Service 목록:"
kubectl get svc -n argocd

# 초기 admin 비밀번호 확인
echo ""
echo "5. 초기 admin 비밀번호 확인 중..."
echo ""

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "=== ArgoCD 설치 완료 ==="
echo ""
echo "📊 ArgoCD 접속 정보:"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "💡 포트포워딩 명령어:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "💡 ArgoCD CLI 로그인:"
echo "   argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure"
