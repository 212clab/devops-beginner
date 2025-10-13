#!/bin/bash

# Week 2 Day 4 Lab 1: 환경 정리 스크립트
# 사용법: ./cleanup.sh

echo "=== Lab 1 환경 정리 시작 ==="
echo ""

# 1. 포트 포워딩 프로세스 종료
echo "1. 포트 포워딩 프로세스 종료 중..."
pkill -f "kubectl port-forward" 2>/dev/null || true
if [ -f /tmp/port-forward.pid ]; then
    kill $(cat /tmp/port-forward.pid) 2>/dev/null || true
    rm -f /tmp/port-forward.pid
fi
if [ -f /tmp/kubectl-port-forward.pid ]; then
    kill $(cat /tmp/kubectl-port-forward.pid) 2>/dev/null || true
    rm -f /tmp/kubectl-port-forward.pid
fi
echo "✅ 포트 포워딩 프로세스 정리 완료"
echo ""

# 2. Kubernetes 리소스 삭제
echo "2. Kubernetes 리소스 삭제 중..."
if kubectl get namespace lab-demo &> /dev/null; then
    echo "lab-demo 네임스페이스 및 모든 리소스 삭제 중..."
    kubectl delete namespace lab-demo --timeout=60s
    echo "✅ Kubernetes 리소스 삭제 완료"
else
    echo "✅ lab-demo 네임스페이스가 존재하지 않습니다"
fi
echo ""

# 3. Kind 클러스터 삭제
echo "3. Kind 클러스터 삭제 중..."
if command -v kind &> /dev/null; then
    if kind get clusters | grep -q "k8s-lab-cluster"; then
        echo "k8s-lab-cluster 삭제 중..."
        kind delete cluster --name k8s-lab-cluster
        echo "✅ Kind 클러스터 삭제 완료"
    else
        echo "✅ k8s-lab-cluster가 존재하지 않습니다"
    fi
else
    echo "⚠️  kind 명령어를 찾을 수 없습니다"
fi
echo ""

# 4. 임시 파일 정리
echo "4. 임시 파일 정리 중..."
rm -f /tmp/configmap*.yaml
rm -f /tmp/deployment*.yaml
rm -f /tmp/service*.yaml
rm -f /tmp/persistent_port_forward.sh
rm -f /tmp/kubectl-port-forward.log
echo "✅ 임시 파일 정리 완료"
echo ""

# 5. Docker 컨테이너 정리 (Kind 관련)
echo "5. Docker 컨테이너 정리 중..."
if command -v docker &> /dev/null; then
    # Kind 관련 컨테이너 정리
    docker ps -a | grep k8s-lab-cluster | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
    
    # 사용하지 않는 네트워크 정리
    docker network ls | grep k8s-lab-cluster | awk '{print $1}' | xargs -r docker network rm 2>/dev/null || true
    
    echo "✅ Docker 컨테이너 정리 완료"
else
    echo "⚠️  docker 명령어를 찾을 수 없습니다"
fi
echo ""

# 6. 최종 상태 확인
echo "6. 최종 상태 확인..."
echo ""
echo "=== 클러스터 상태 ==="
if kubectl cluster-info &> /dev/null; then
    echo "⚠️  Kubernetes 클러스터가 여전히 실행 중입니다"
    kubectl get nodes 2>/dev/null || echo "노드 정보를 가져올 수 없습니다"
else
    echo "✅ Kubernetes 클러스터 연결 없음"
fi
echo ""

echo "=== 포트 상태 확인 ==="
if curl -s http://localhost:8080 &> /dev/null; then
    echo "⚠️  포트 8080이 여전히 사용 중입니다"
else
    echo "✅ 포트 8080 사용 중지됨"
fi

if curl -s http://localhost:30080 &> /dev/null; then
    echo "⚠️  포트 30080이 여전히 사용 중입니다"
else
    echo "✅ 포트 30080 사용 중지됨"
fi
echo ""

echo "=== Docker 컨테이너 상태 ==="
if command -v docker &> /dev/null; then
    CONTAINERS=$(docker ps | grep k8s-lab-cluster | wc -l)
    if [ $CONTAINERS -eq 0 ]; then
        echo "✅ Kind 관련 컨테이너 없음"
    else
        echo "⚠️  Kind 관련 컨테이너 $CONTAINERS개 실행 중"
        docker ps | grep k8s-lab-cluster
    fi
else
    echo "⚠️  Docker 상태를 확인할 수 없습니다"
fi
echo ""

# 7. 완료 요약
echo "=== Lab 1 환경 정리 완료 ==="
echo ""
echo "✅ 정리 완료 항목:"
echo "- 포트 포워딩 프로세스 종료"
echo "- Kubernetes 리소스 삭제 (lab-demo 네임스페이스)"
echo "- Kind 클러스터 삭제 (k8s-lab-cluster)"
echo "- 임시 파일 정리"
echo "- Docker 컨테이너 정리"
echo ""
echo "🔄 다시 시작하려면:"
echo "1. ./setup_k8s_cluster.sh - 클러스터 재구축"
echo "2. ./deploy_basic_objects.sh - 기본 오브젝트 배포"
echo "3. ./start_port_forward.sh - 포트 포워딩 시작"
echo ""
echo "🎉 환경 정리가 성공적으로 완료되었습니다!"