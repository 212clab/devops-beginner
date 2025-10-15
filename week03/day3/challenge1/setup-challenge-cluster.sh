#!/bin/bash

# Challenge 3용 Kind 클러스터 생성 스크립트

echo "🚀 Challenge 3용 Kubernetes 클러스터 확인 중..."

# 기존 클러스터 확인
if kind get clusters 2>/dev/null | grep -q "challenge-cluster"; then
    echo "✅ 기존 challenge-cluster 발견. 재사용합니다."
    kubectl config use-context kind-challenge-cluster
    
    echo ""
    echo "🎯 클러스터 정보:"
    kubectl cluster-info
    
    echo ""
    echo "📋 노드 상태:"
    kubectl get nodes
    
    # Ingress Controller 확인
    echo ""
    echo "🔍 Ingress Controller 확인 중..."
    if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q "ingress-nginx-controller"; then
        echo "✅ Ingress Controller 이미 설치됨"
    else
        echo "🏷️  노드에 ingress-ready 라벨 추가 중..."
        kubectl label node challenge-cluster-control-plane ingress-ready=true --overwrite
        
        echo "📦 Ingress Controller 설치 중..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
        
        echo "⏳ Ingress Controller 준비 대기 중..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=90s
        
        echo "✅ Ingress Controller 설치 완료"
    fi
    
    echo ""
    echo "✅ 기존 클러스터 사용 준비 완료!"
    echo "   다음 명령어로 문제 시스템을 배포하세요:"
    echo "   ./deploy-broken-system.sh"
    exit 0
fi

echo "📦 새로운 클러스터 생성 중..."

# Kind 클러스터 생성
kind create cluster --name challenge-cluster --config=kind-config.yaml

# 클러스터 생성 확인
if [ $? -eq 0 ]; then
    echo "✅ 클러스터 생성 완료!"
    
    # 컨텍스트 설정
    kubectl config use-context kind-challenge-cluster
    
    echo ""
    echo "🎯 클러스터 정보:"
    kubectl cluster-info
    
    echo ""
    echo "📋 노드 상태:"
    kubectl get nodes
    
    # 노드에 ingress-ready 라벨 추가
    echo ""
    echo "🏷️  노드에 ingress-ready 라벨 추가 중..."
    kubectl label node challenge-cluster-control-plane ingress-ready=true --overwrite
    
    # Ingress Controller 설치
    echo ""
    echo "📦 Ingress Controller 설치 중..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
    
    echo "⏳ Ingress Controller 준비 대기 중..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=90s
    
    echo "✅ Ingress Controller 설치 완료"
    
    echo ""
    echo "✅ Challenge 3용 클러스터 준비 완료!"
    echo "   다음 명령어로 문제 시스템을 배포하세요:"
    echo "   ./deploy-broken-system.sh"
else
    echo "❌ 클러스터 생성 실패!"
    exit 1
fi
