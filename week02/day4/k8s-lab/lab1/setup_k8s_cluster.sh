#!/bin/bash

# Week 2 Day 4 Lab 1: K8s 클러스터 자동 구축 스크립트
# 사용법: ./setup_k8s_cluster.sh

echo "=== Kubernetes 클러스터 구축 시작 ==="
echo ""

# 1. 시스템 요구사항 확인
echo "1. 시스템 요구사항 확인 중..."
echo "OS: $(uname -a)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "CPU: $(nproc) cores"
echo "Docker: $(docker --version)"
echo ""

# 2. Kind 설치 확인
echo "2. Kind 설치 확인 중..."
if ! command -v kind &> /dev/null; then
    echo "Kind가 설치되지 않았습니다. 설치를 진행합니다..."
    
    # Linux/WSL 환경
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    # macOS 환경
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    echo "✅ Kind 설치 완료"
else
    echo "✅ Kind 이미 설치됨: $(kind --version)"
fi
echo ""

# 3. kubectl 설치 확인
echo "3. kubectl 설치 확인 중..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl이 설치되지 않았습니다. 설치를 진행합니다..."
    
    # Linux/WSL 환경
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    # macOS 환경
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    echo "✅ kubectl 설치 완료"
else
    echo "✅ kubectl 이미 설치됨: $(kubectl version --client --short)"
fi
echo ""

# 4. 기존 클러스터 정리
echo "4. 기존 클러스터 정리 중..."
if kind get clusters | grep -q "k8s-lab-cluster"; then
    echo "기존 k8s-lab-cluster 발견. 삭제 중..."
    kind delete cluster --name k8s-lab-cluster
    echo "✅ 기존 클러스터 삭제 완료"
fi
echo ""

# 5. Kind 클러스터 설정 파일 생성
echo "5. 클러스터 설정 파일 생성 중..."
cat > kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8s-lab-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8081
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
- role: worker
- role: worker
EOF

echo "✅ 클러스터 설정 파일 생성 완료"
echo ""

# 6. Kind 클러스터 생성
echo "6. Kubernetes 클러스터 생성 중..."
echo "이 작업은 몇 분 소요될 수 있습니다..."
kind create cluster --config=kind-config.yaml

if [ $? -eq 0 ]; then
    echo "✅ 클러스터 생성 완료"
else
    echo "❌ 클러스터 생성 실패"
    exit 1
fi
echo ""

# 7. 클러스터 상태 확인
echo "7. 클러스터 상태 확인 중..."
echo ""
echo "=== 클러스터 정보 ==="
kubectl cluster-info
echo ""

echo "=== 노드 상태 ==="
kubectl get nodes -o wide
echo ""

echo "=== 시스템 Pod 상태 ==="
kubectl get pods -n kube-system
echo ""

# 8. 클러스터 준비 완료 대기
echo "8. 모든 시스템 Pod 준비 대기 중..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ 모든 시스템 구성 요소 준비 완료"
else
    echo "⚠️ 일부 구성 요소가 준비되지 않았지만 계속 진행합니다"
fi
echo ""

# 9. 완료 요약
echo ""
echo "=== Kubernetes 클러스터 구축 완료 ==="
echo ""
echo "클러스터 정보:"
echo "- 클러스터명: k8s-lab-cluster"
echo "- 노드 수: $(kubectl get nodes --no-headers | wc -l)개"
echo "- Control Plane: 1개"
echo "- Worker Node: 2개"
echo ""
echo "접속 정보:"
echo "- API Server: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo "- Context: $(kubectl config current-context)"
echo ""
echo "다음 단계:"
echo "- kubectl get nodes 명령어로 노드 상태 확인"
echo "- kubectl get pods --all-namespaces 명령어로 전체 Pod 확인"
echo "- Lab 1의 다음 단계인 기본 오브젝트 배포 진행"
echo ""
echo "🎉 K8s 클러스터가 성공적으로 구축되었습니다!"