#!/bin/bash

# Challenge 2용 Kind 클러스터 생성 스크립트

echo "🚀 Challenge 2용 Kubernetes 클러스터 확인 중..."

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
    
    echo ""
    echo "✅ 기존 클러스터 사용 준비 완료!"
    echo "   다음 명령어로 문제 애플리케이션을 배포하세요:"
    echo "   ./deploy-broken.sh"
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
    
    echo ""
    echo "✅ Challenge 2용 클러스터 준비 완료!"
    echo "   다음 명령어로 문제 애플리케이션을 배포하세요:"
    echo "   ./deploy-broken.sh"
else
    echo "❌ 클러스터 생성 실패!"
    exit 1
fi
