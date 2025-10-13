#!/bin/bash

# 컴포넌트 상태 확인 스크립트
# 목적: Kubernetes 클러스터의 모든 핵심 컴포넌트 상태를 체계적으로 분석
# 사용법: ./check-components.sh

set -e
trap 'echo "❌ 컴포넌트 확인 중 오류 발생"' ERR

echo "=== Kubernetes Components Health Check ==="
echo "🔍 클러스터의 모든 핵심 컴포넌트를 분석합니다..."

# 로그 디렉토리 생성
mkdir -p logs
echo "📁 로그 디렉토리 생성: ./logs/"

# 전체 상태 추적 변수
TOTAL_COMPONENTS=0
HEALTHY_COMPONENTS=0

echo ""
echo "🏛️ 1. Control Plane Components Analysis"
echo "================================================"

# API Server 상태 확인
echo "🔌 API Server 분석 중..."
TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
if kubectl get pods -n kube-system -l component=kube-apiserver --no-headers | grep -q "Running"; then
    echo "   ✅ API Server: 정상 실행 중"
    HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    
    # API Server 세부 정보
    API_POD=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].metadata.name}')
    echo "   📊 Pod 이름: $API_POD"
    echo "   🔗 엔드포인트: $(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}'):6443"
    
    # API Server 로그 수집
    kubectl logs -n kube-system -l component=kube-apiserver --tail=50 > logs/apiserver.log 2>/dev/null || true
    echo "   📝 로그 저장: logs/apiserver.log"
else
    echo "   ❌ API Server: 문제 발생"
fi

# ETCD 상태 확인
echo ""
echo "🗄️ ETCD 분석 중..."
TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
if kubectl get pods -n kube-system -l component=etcd --no-headers | grep -q "Running"; then
    echo "   ✅ ETCD: 정상 실행 중"
    HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    
    # ETCD 세부 정보
    ETCD_POD=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].metadata.name}')
    echo "   📊 Pod 이름: $ETCD_POD"
    echo "   🔗 클라이언트 포트: 2379, 피어 포트: 2380"
    
    # ETCD 로그 수집
    kubectl logs -n kube-system -l component=etcd --tail=50 > logs/etcd.log 2>/dev/null || true
    echo "   📝 로그 저장: logs/etcd.log"
else
    echo "   ❌ ETCD: 문제 발생"
fi

# Controller Manager 상태 확인
echo ""
echo "🎛️ Controller Manager 분석 중..."
TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
if kubectl get pods -n kube-system -l component=kube-controller-manager --no-headers | grep -q "Running"; then
    echo "   ✅ Controller Manager: 정상 실행 중"
    HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    
    # Controller Manager 세부 정보
    CM_POD=$(kubectl get pods -n kube-system -l component=kube-controller-manager -o jsonpath='{.items[0].metadata.name}')
    echo "   📊 Pod 이름: $CM_POD"
    echo "   🔄 관리 중인 컨트롤러: Deployment, ReplicaSet, Service 등"
    
    # Controller Manager 로그 수집
    kubectl logs -n kube-system -l component=kube-controller-manager --tail=50 > logs/controller-manager.log 2>/dev/null || true
    echo "   📝 로그 저장: logs/controller-manager.log"
else
    echo "   ❌ Controller Manager: 문제 발생"
fi

# Scheduler 상태 확인
echo ""
echo "📅 Scheduler 분석 중..."
TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
if kubectl get pods -n kube-system -l component=kube-scheduler --no-headers | grep -q "Running"; then
    echo "   ✅ Scheduler: 정상 실행 중"
    HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    
    # Scheduler 세부 정보
    SCHED_POD=$(kubectl get pods -n kube-system -l component=kube-scheduler -o jsonpath='{.items[0].metadata.name}')
    echo "   📊 Pod 이름: $SCHED_POD"
    echo "   🎯 역할: Pod를 적절한 노드에 스케줄링"
    
    # Scheduler 로그 수집
    kubectl logs -n kube-system -l component=kube-scheduler --tail=50 > logs/scheduler.log 2>/dev/null || true
    echo "   📝 로그 저장: logs/scheduler.log"
else
    echo "   ❌ Scheduler: 문제 발생"
fi

echo ""
echo "🖥️ 2. Worker Node Components Analysis"
echo "================================================"

# Kube Proxy 확인
echo "🌐 Kube Proxy 분석 중..."
TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
PROXY_COUNT=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers | grep "Running" | wc -l)
if [ "$PROXY_COUNT" -gt 0 ]; then
    echo "   ✅ Kube Proxy: $PROXY_COUNT 개 인스턴스 실행 중"
    HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    echo "   🔗 역할: Service 추상화 및 로드밸런싱"
    echo "   📊 모드: iptables (기본값)"
else
    echo "   ❌ Kube Proxy: 문제 발생"
fi

# CNI 플러그인 확인
echo ""
echo "🔌 CNI Plugin 분석 중..."
TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
CNI_COUNT=$(kubectl get pods -n kube-system -l app=kindnet --no-headers 2>/dev/null | grep "Running" | wc -l || echo "0")
if [ "$CNI_COUNT" -gt 0 ]; then
    echo "   ✅ CNI Plugin (kindnet): $CNI_COUNT 개 인스턴스 실행 중"
    HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    echo "   🌐 역할: Pod 간 네트워킹 제공"
    echo "   📊 타입: Bridge 네트워크"
else
    # 다른 CNI 플러그인 확인
    OTHER_CNI=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -E "(calico|flannel|weave)" | wc -l || echo "0")
    if [ "$OTHER_CNI" -gt 0 ]; then
        echo "   ✅ CNI Plugin: 다른 CNI 플러그인 실행 중"
        HEALTHY_COMPONENTS=$((HEALTHY_COMPONENTS + 1))
    else
        echo "   ❌ CNI Plugin: 문제 발생"
    fi
fi

echo ""
echo "📊 3. Log Analysis & Health Summary"
echo "================================================"

# 로그 분석
echo "🔍 로그 분석 중..."
ERROR_COUNT=0
WARNING_COUNT=0

if [ -f logs/apiserver.log ]; then
    API_ERRORS=$(grep -i error logs/apiserver.log | wc -l || echo "0")
    API_WARNINGS=$(grep -i warning logs/apiserver.log | wc -l || echo "0")
    ERROR_COUNT=$((ERROR_COUNT + API_ERRORS))
    WARNING_COUNT=$((WARNING_COUNT + API_WARNINGS))
fi

if [ -f logs/controller-manager.log ]; then
    CM_ERRORS=$(grep -i error logs/controller-manager.log | wc -l || echo "0")
    CM_WARNINGS=$(grep -i warning logs/controller-manager.log | wc -l || echo "0")
    ERROR_COUNT=$((ERROR_COUNT + CM_ERRORS))
    WARNING_COUNT=$((WARNING_COUNT + CM_WARNINGS))
fi

if [ -f logs/scheduler.log ]; then
    SCHED_ERRORS=$(grep -i error logs/scheduler.log | wc -l || echo "0")
    SCHED_WARNINGS=$(grep -i warning logs/scheduler.log | wc -l || echo "0")
    ERROR_COUNT=$((ERROR_COUNT + SCHED_ERRORS))
    WARNING_COUNT=$((WARNING_COUNT + SCHED_WARNINGS))
fi

echo "   📈 로그 분석 결과:"
echo "   🔴 에러: $ERROR_COUNT 개"
echo "   🟡 경고: $WARNING_COUNT 개"

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "   ⚠️ 에러 발견! 상세 내용은 logs/ 디렉토리 확인"
fi

echo ""
echo "🎯 4. Overall Health Status"
echo "================================================"

# 전체 상태 요약
HEALTH_PERCENTAGE=$((HEALTHY_COMPONENTS * 100 / TOTAL_COMPONENTS))

echo "📊 클러스터 상태 요약:"
echo "   ✅ 정상 컴포넌트: $HEALTHY_COMPONENTS/$TOTAL_COMPONENTS"
echo "   📈 전체 상태: $HEALTH_PERCENTAGE%"

if [ "$HEALTH_PERCENTAGE" -eq 100 ]; then
    echo "   🎉 클러스터 완전 정상!"
elif [ "$HEALTH_PERCENTAGE" -ge 80 ]; then
    echo "   ✅ 클러스터 대부분 정상"
elif [ "$HEALTH_PERCENTAGE" -ge 60 ]; then
    echo "   ⚠️ 클러스터 일부 문제 있음"
else
    echo "   ❌ 클러스터 심각한 문제 있음"
fi

echo ""
echo "📁 생성된 파일:"
echo "   📝 logs/apiserver.log - API Server 로그"
echo "   📝 logs/controller-manager.log - Controller Manager 로그"
echo "   📝 logs/scheduler.log - Scheduler 로그"
echo "   📝 logs/etcd.log - ETCD 로그"

echo ""
echo "🎓 학습 포인트:"
echo "   • Control Plane: API Server, ETCD, Controller Manager, Scheduler"
echo "   • Worker Node: Kubelet, Kube Proxy, CNI Plugin"
echo "   • 각 컴포넌트는 독립적으로 실행되며 서로 협력"
echo "   • 로그 분석을 통해 문제 진단 가능"

echo ""
echo "✅ 컴포넌트 분석 완료!"