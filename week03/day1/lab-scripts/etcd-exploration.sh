#!/bin/bash

# ETCD 탐험 스크립트
# 목적: Kubernetes의 핵심 데이터 저장소인 ETCD를 안전하게 탐험
# 사용법: ./etcd-exploration.sh

set -e
trap 'echo "❌ ETCD 탐험 중 오류 발생"' ERR

echo "=== ETCD Deep Dive Exploration ==="
echo "🗄️ Kubernetes의 두뇌인 ETCD를 탐험합니다..."

# ETCD Pod 존재 확인
echo "🔍 1. ETCD Pod 확인 중..."
if ! kubectl get pods -n kube-system -l component=etcd --no-headers | grep -q "Running"; then
    echo "❌ ETCD Pod를 찾을 수 없습니다. 클러스터가 정상인지 확인하세요."
    exit 1
fi

ETCD_POD=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].metadata.name}')
echo "   ✅ ETCD Pod 발견: $ETCD_POD"

# ETCD 환경 변수 설정 함수
setup_etcd_env() {
    cat << 'EOF'
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
EOF
}

echo ""
echo "🏥 2. ETCD Health Check"
echo "================================================"

# ETCD 클러스터 상태 확인
echo "🔍 ETCD 클러스터 상태 확인 중..."
kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)

echo '📊 ETCD 엔드포인트 상태:'
etcdctl endpoint health --write-out=table

echo ''
echo '📈 ETCD 클러스터 상태:'
etcdctl endpoint status --write-out=table

echo ''
echo '🔢 ETCD 멤버 목록:'
etcdctl member list --write-out=table
" 2>/dev/null || echo "⚠️ ETCD 상태 확인 중 일부 오류 발생 (정상적일 수 있음)"

echo ""
echo "🗂️ 3. Kubernetes Data Structure Analysis"
echo "================================================"

# 전체 키 개수 확인
echo "📊 ETCD에 저장된 데이터 개요:"
TOTAL_KEYS=$(kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)
etcdctl get / --prefix --keys-only | wc -l
" 2>/dev/null || echo "0")

echo "   📈 총 키 개수: $TOTAL_KEYS"

# 주요 네임스페이스별 키 분석
echo ""
echo "🏷️ 네임스페이스별 데이터 분포:"
kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)

echo '📁 주요 데이터 카테고리:'
etcdctl get /registry --prefix --keys-only | cut -d'/' -f3 | sort | uniq -c | head -10
" 2>/dev/null || echo "⚠️ 데이터 분포 분석 중 오류 발생"

echo ""
echo "🔍 4. Resource Type Analysis"
echo "================================================"

# 리소스 타입별 분석
echo "📋 Kubernetes 리소스 타입별 저장 현황:"
kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)

echo '🏷️ 네임스페이스:'
etcdctl get /registry/namespaces --prefix --keys-only | wc -l | xargs echo '   개수:'

echo '🚀 Pod:'
etcdctl get /registry/pods --prefix --keys-only | wc -l | xargs echo '   개수:'

echo '🔗 Service:'
etcdctl get /registry/services --prefix --keys-only | wc -l | xargs echo '   개수:'

echo '📦 Deployment:'
etcdctl get /registry/deployments --prefix --keys-only | wc -l | xargs echo '   개수:'

echo '🔄 ReplicaSet:'
etcdctl get /registry/replicasets --prefix --keys-only | wc -l | xargs echo '   개수:'
" 2>/dev/null || echo "⚠️ 리소스 분석 중 오류 발생"

echo ""
echo "🔬 5. Sample Data Examination"
echo "================================================"

# 샘플 데이터 조회 (안전한 읽기 전용)
echo "📖 샘플 데이터 구조 분석:"

echo ""
echo "🏷️ Default 네임스페이스 정보:"
kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)
etcdctl get /registry/namespaces/default --print-value-only | head -20
" 2>/dev/null || echo "⚠️ 네임스페이스 정보 조회 실패"

echo ""
echo "🔗 Kubernetes 기본 서비스 정보:"
kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)
etcdctl get /registry/services/specs/default/kubernetes --print-value-only | head -10
" 2>/dev/null || echo "⚠️ 서비스 정보 조회 실패"

echo ""
echo "📊 6. ETCD Performance Metrics"
echo "================================================"

# ETCD 성능 메트릭
echo "⚡ ETCD 성능 정보:"
kubectl exec -n kube-system $ETCD_POD -- sh -c "
$(setup_etcd_env)

echo '💾 데이터베이스 크기:'
etcdctl endpoint status --write-out=json | grep -o '\"dbSize\":[0-9]*' | cut -d':' -f2 | xargs -I {} echo '   {} bytes'

echo '🔄 리비전 번호:'
etcdctl endpoint status --write-out=json | grep -o '\"revision\":[0-9]*' | cut -d':' -f2 | xargs -I {} echo '   현재 리비전: {}'
" 2>/dev/null || echo "⚠️ 성능 메트릭 조회 실패"

echo ""
echo "🎓 7. Educational Summary"
echo "================================================"

echo "📚 ETCD 학습 포인트:"
echo "   • ETCD는 Kubernetes의 모든 상태 정보를 저장하는 분산 키-값 저장소"
echo "   • Raft 합의 알고리즘을 사용하여 데이터 일관성 보장"
echo "   • /registry/ 경로 하위에 모든 Kubernetes 리소스 저장"
echo "   • etcdctl 도구로 직접 데이터 조회 및 관리 가능"
echo "   • 프로덕션에서는 정기적인 백업이 필수"

echo ""
echo "⚠️ 중요 주의사항:"
echo "   • ETCD 데이터 직접 수정은 클러스터 손상 위험"
echo "   • 항상 kubectl을 통한 간접 접근 권장"
echo "   • 백업 없이 ETCD 조작 금지"
echo "   • 이 스크립트는 읽기 전용 탐험만 수행"

echo ""
echo "🔗 다음 단계 추천:"
echo "   • kubectl get 명령어와 ETCD 데이터 비교"
echo "   • 리소스 생성 후 ETCD 변화 관찰"
echo "   • ETCD 백업/복원 실습 (별도 환경에서)"

echo ""
echo "✅ ETCD 탐험 완료!"
echo "📖 더 자세한 내용은 Kubernetes 공식 문서 참조: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/"