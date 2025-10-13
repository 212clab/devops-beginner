#!/bin/bash

# --- kubectl 설치 확인 및 설치 안내 ---
# command -v [명령어] : 해당 명령어가 시스템 경로에 있는지 확인
if ! command -v kubectl &> /dev/null; then
    echo "✅ kubectl이 설치되지 않았습니다."
    echo "Homebrew를 사용하여 설치하는 것을 권장합니다."
    echo "실행 명령어: brew install kubectl"
    
    # Homebrew가 설치되어 있다면 자동으로 설치를 진행할 수도 있습니다.
    if command -v brew &> /dev/null; then
        echo "Homebrew가 감지되었습니다. kubectl 설치를 진행합니다..."
        brew install kubectl
    else
        echo "Homebrew가 설치되어 있지 않습니다. https://brew.sh/index_ko 에서 설치 후 다시 시도해 주세요."
    fi
else
    echo "✅ kubectl이 이미 설치되어 있습니다: $(kubectl version --client --short)"
fi


echo # 줄바꿈

# --- 로컬 K8s 클러스터 도구 (kind 또는 minikube) 설치 확인 및 안내 ---
if ! command -v kind &> /dev/null && ! command -v minikube &> /dev/null; then
    echo "⚠️ 로컬 쿠버네티스 클러스터 도구(kind 또는 minikube)가 설치되지 않았습니다."
    echo "둘 중 하나를 선택하여 설치해 주세요."
    echo "  - Kind 설치: brew install kind"
    echo "  - Minikube 설치: brew install minikube"
else
    echo "✅ 로컬 K8s 클러스터 도구가 이미 설치되어 있습니다."
    # 어떤 도구가 설치되었는지 친절하게 알려주기
    if command -v kind &> /dev/null; then
        echo "   - Kind: $(kind --version)"
    fi
    if command -v minikube &> /dev/null; then
        echo "   - Minikube: $(minikube version --short)"
    fi
fi