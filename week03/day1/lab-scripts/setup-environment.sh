#!/bin/bash

# Lab 1 환경 설정 스크립트
# 목적: Kubernetes 클러스터 탐험을 위한 환경 준비
# 사용법: ./setup-environment.sh

set -e  # 에러 발생 시 즉시 종료
trap 'echo "❌ 환경 설정 중 오류 발생"' ERR

echo "=== Lab 1 Environment Setup ==="
echo "🚀 Kubernetes 클러스터 탐험 환경을 준비합니다..."

# 1. 작업 디렉토리 생성
echo "📁 1/4 작업 디렉토리 생성 중..."
mkdir -p ~/k8s-lab1
cd ~/k8s-lab1
echo "   ✅ 작업 디렉토리: ~/k8s-lab1"

# 2. 필요한 도구 확인
echo "🔧 2/4 필수 도구 확인 중..."
if ! command -v kubectl &> /dev/null; then
    echo "   ❌ kubectl이 설치되지 않았습니다"
    echo "   💡 설치 방법: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v kind &> /dev/null; then
    echo "   ❌ kind가 설치되지 않았습니다"
    echo "   💡 설치 방법: https://kind.sigs.k8s.io/docs/user/quick-start/"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "   ❌ docker가 설치되지 않았습니다"
    echo "   💡 설치 방법: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "   ✅ kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "   ✅ kind: $(kind version)"
echo "   ✅ docker: $(docker --version)"

# 3. Docker 상태 확인
echo "🐳 3/4 Docker 상태 확인 중..."
if ! docker info &> /dev/null; then
    echo "   ❌ Docker가 실행되지 않고 있습니다"
    echo "   💡 Docker Desktop을 시작하거나 Docker 서비스를 시작하세요"
    exit 1
fi
echo "   ✅ Docker 정상 실행 중"

# 4. 네임스페이스 설정 (클러스터가 있는 경우에만)
echo "🏷️ 4/4 네임스페이스 설정 중..."
if kubectl cluster-info &> /dev/null; then
    echo "   🔍 기존 클러스터 발견"
    
    # 클러스터 정보 표시
    echo "   📊 클러스터 정보:"
    kubectl cluster-info --request-timeout=5s | head -3
    
    # 기존 네임스페이스 확인 및 생성
    if kubectl get namespace lab-day1 &> /dev/null; then
        echo "   ⚠️ lab-day1 네임스페이스가 이미 존재합니다"
        echo "   🔄 기존 네임스페이스 재사용"
    else
        kubectl create namespace lab-day1
        echo "   ✅ lab-day1 네임스페이스 생성 완료"
    fi
    
    # 네임스페이스에 라벨 추가 (교육용)
    kubectl label namespace lab-day1 purpose=education --overwrite
    kubectl label namespace lab-day1 week=3 --overwrite
    kubectl label namespace lab-day1 day=1 --overwrite
    
    kubectl config set-context --current --namespace=lab-day1
    echo "   ✅ 현재 컨텍스트를 lab-day1로 설정"
    
    # 현재 컨텍스트 확인
    echo "   📍 현재 컨텍스트: $(kubectl config current-context)"
    echo "   🏷️ 현재 네임스페이스: $(kubectl config view --minify --output 'jsonpath={..namespace}')"
else
    echo "   ⚠️ 클러스터가 없습니다. 먼저 클러스터를 생성하세요."
    echo "   💡 다음 명령어: ./create-cluster.sh"
    echo "   📖 클러스터 생성 후 이 스크립트를 다시 실행하세요"
fi

# 5. 환경 변수 설정
echo "🌍 환경 변수 설정..."
export LAB_NAMESPACE=lab-day1
export LAB_DIR=~/k8s-lab1
echo "   ✅ LAB_NAMESPACE=$LAB_NAMESPACE"
echo "   ✅ LAB_DIR=$LAB_DIR"

echo ""
echo "🎉 환경 설정 완료!"
echo "📍 작업 디렉토리: ~/k8s-lab1"
echo "🏷️ 네임스페이스: lab-day1"
echo ""
echo "📋 다음 단계:"
echo "   1. ./create-cluster.sh - 클러스터 생성"
echo "   2. ./check-components.sh - 컴포넌트 확인"
echo "   3. ./etcd-exploration.sh - ETCD 탐험"
