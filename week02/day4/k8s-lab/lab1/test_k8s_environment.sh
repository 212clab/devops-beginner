#!/bin/bash

# Week 2 Day 4 Lab 1: K8s 환경 종합 테스트 스크립트
# 사용법: ./test_k8s_environment.sh

echo "=== Kubernetes 환경 종합 테스트 시작 ==="
echo ""

# 테스트 결과 추적
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 테스트 함수
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo "🧪 테스트 $TOTAL_TESTS: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo "✅ PASS: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ FAIL: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# 1. 클러스터 기본 상태 테스트
echo "1. 클러스터 기본 상태 테스트"
echo "=========================="
echo ""

run_test "클러스터 연결 확인" "kubectl cluster-info"
run_test "노드 Ready 상태 확인" "kubectl get nodes | grep -q Ready"
run_test "시스템 Pod 실행 확인" "kubectl get pods -n kube-system | grep -q Running"

# 2. 네임스페이스 및 리소스 테스트
echo "2. 네임스페이스 및 리소스 테스트"
echo "============================="
echo ""

run_test "lab-demo 네임스페이스 존재 확인" "kubectl get namespace lab-demo"
run_test "ConfigMap 존재 확인" "kubectl get configmap nginx-config -n lab-demo"
run_test "Deployment 존재 확인" "kubectl get deployment nginx-deployment -n lab-demo"
run_test "Service 존재 확인" "kubectl get service nginx-service -n lab-demo"

# 3. Pod 상태 및 가용성 테스트
echo "3. Pod 상태 및 가용성 테스트"
echo "=========================="
echo ""

# Pod 개수 확인
EXPECTED_PODS=3
ACTUAL_PODS=$(kubectl get pods -n lab-demo -l app=nginx --no-headers | wc -l)
if [ "$ACTUAL_PODS" -eq "$EXPECTED_PODS" ]; then
    echo "✅ PASS: Pod 개수 확인 ($ACTUAL_PODS/$EXPECTED_PODS)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: Pod 개수 불일치 ($ACTUAL_PODS/$EXPECTED_PODS)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# Pod Ready 상태 확인
READY_PODS=$(kubectl get pods -n lab-demo -l app=nginx --no-headers | grep -c "1/1.*Running")
if [ "$READY_PODS" -eq "$EXPECTED_PODS" ]; then
    echo "✅ PASS: 모든 Pod Ready 상태 ($READY_PODS/$EXPECTED_PODS)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: 일부 Pod가 Ready 상태가 아님 ($READY_PODS/$EXPECTED_PODS)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

run_test "Deployment Available 상태 확인" "kubectl get deployment nginx-deployment -n lab-demo -o jsonpath='{.status.conditions[?(@.type==\"Available\")].status}' | grep -q True"

# 4. 네트워킹 및 서비스 디스커버리 테스트
echo "4. 네트워킹 및 서비스 디스커버리 테스트"
echo "=================================="
echo ""

run_test "Service Endpoints 확인" "kubectl get endpoints nginx-service -n lab-demo | grep -q ':80'"
run_test "ClusterIP 할당 확인" "kubectl get service nginx-service -n lab-demo -o jsonpath='{.spec.clusterIP}' | grep -v 'None'"
run_test "NodePort 할당 확인" "kubectl get service nginx-nodeport -n lab-demo -o jsonpath='{.spec.ports[0].nodePort}' | grep -q '30080'"

# DNS 해석 테스트
echo "🧪 DNS 해석 테스트"
if kubectl run dns-test-pod --image=busybox:1.35 --rm -it --restart=Never -n lab-demo --timeout=30s -- nslookup nginx-service > /dev/null 2>&1; then
    echo "✅ PASS: DNS 해석 테스트"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: DNS 해석 테스트"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 5. 애플리케이션 기능 테스트
echo "5. 애플리케이션 기능 테스트"
echo "========================"
echo ""

# Health check 엔드포인트 테스트
echo "🧪 Health Check 엔드포인트 테스트"
if kubectl run health-test-pod --image=busybox:1.35 --rm -it --restart=Never -n lab-demo --timeout=30s -- wget -qO- nginx-service/health | grep -q "healthy" > /dev/null 2>&1; then
    echo "✅ PASS: Health Check 엔드포인트"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: Health Check 엔드포인트"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 웹 페이지 접근 테스트
echo "🧪 웹 페이지 접근 테스트"
if kubectl run web-test-pod --image=busybox:1.35 --rm -it --restart=Never -n lab-demo --timeout=30s -- wget -qO- nginx-service | grep -q "Welcome to Kubernetes Lab" > /dev/null 2>&1; then
    echo "✅ PASS: 웹 페이지 접근"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: 웹 페이지 접근"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 6. 설정 및 볼륨 마운트 테스트
echo "6. 설정 및 볼륨 마운트 테스트"
echo "=========================="
echo ""

# ConfigMap 마운트 확인
POD_NAME=$(kubectl get pods -n lab-demo -l app=nginx -o jsonpath='{.items[0].metadata.name}')

echo "🧪 ConfigMap 마운트 테스트"
if kubectl exec $POD_NAME -n lab-demo -- cat /etc/nginx/conf.d/default.conf | grep -q "location /health" > /dev/null 2>&1; then
    echo "✅ PASS: ConfigMap 마운트 (nginx.conf)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: ConfigMap 마운트 (nginx.conf)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

echo "🧪 HTML 파일 마운트 테스트"
if kubectl exec $POD_NAME -n lab-demo -- cat /usr/share/nginx/html/index.html | grep -q "Welcome to Kubernetes Lab" > /dev/null 2>&1; then
    echo "✅ PASS: ConfigMap 마운트 (index.html)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: ConfigMap 마운트 (index.html)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 7. 리소스 제한 및 프로브 테스트
echo "7. 리소스 제한 및 프로브 테스트"
echo "============================"
echo ""

run_test "CPU 리소스 제한 설정 확인" "kubectl get pod $POD_NAME -n lab-demo -o jsonpath='{.spec.containers[0].resources.limits.cpu}' | grep -q '500m'"
run_test "메모리 리소스 제한 설정 확인" "kubectl get pod $POD_NAME -n lab-demo -o jsonpath='{.spec.containers[0].resources.limits.memory}' | grep -q '128Mi'"
run_test "Liveness Probe 설정 확인" "kubectl get pod $POD_NAME -n lab-demo -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.path}' | grep -q '/health'"
run_test "Readiness Probe 설정 확인" "kubectl get pod $POD_NAME -n lab-demo -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.path}' | grep -q '/health'"

# 8. 스케일링 기능 테스트
echo "8. 스케일링 기능 테스트"
echo "===================="
echo ""

echo "🧪 스케일 업 테스트 (5개로 증가)"
kubectl scale deployment nginx-deployment --replicas=5 -n lab-demo > /dev/null 2>&1
sleep 10

SCALED_PODS=$(kubectl get pods -n lab-demo -l app=nginx --no-headers | wc -l)
if [ "$SCALED_PODS" -eq 5 ]; then
    echo "✅ PASS: 스케일 업 테스트 (5개)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: 스케일 업 테스트 ($SCALED_PODS/5)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

echo "🧪 스케일 다운 테스트 (3개로 복원)"
kubectl scale deployment nginx-deployment --replicas=3 -n lab-demo > /dev/null 2>&1
sleep 10

RESTORED_PODS=$(kubectl get pods -n lab-demo -l app=nginx --no-headers | wc -l)
if [ "$RESTORED_PODS" -eq 3 ]; then
    echo "✅ PASS: 스케일 다운 테스트 (3개)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: 스케일 다운 테스트 ($RESTORED_PODS/3)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 9. 로드밸런싱 테스트
echo "9. 로드밸런싱 테스트"
echo "=================="
echo ""

echo "🧪 로드밸런싱 테스트 (여러 요청 분산 확인)"
UNIQUE_RESPONSES=0

for i in {1..10}; do
    RESPONSE=$(kubectl run lb-test-$i --image=busybox:1.35 --rm -it --restart=Never -n lab-demo --timeout=10s -- wget -qO- nginx-service/info 2>/dev/null | grep "Pod:" | head -1)
    if [ ! -z "$RESPONSE" ]; then
        UNIQUE_RESPONSES=$((UNIQUE_RESPONSES + 1))
    fi
done

if [ "$UNIQUE_RESPONSES" -gt 5 ]; then
    echo "✅ PASS: 로드밸런싱 테스트 (응답 수: $UNIQUE_RESPONSES/10)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: 로드밸런싱 테스트 (응답 수: $UNIQUE_RESPONSES/10)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 10. 장애 복구 테스트
echo "10. 장애 복구 테스트"
echo "=================="
echo ""

echo "🧪 Pod 삭제 후 자동 복구 테스트"
ORIGINAL_POD=$(kubectl get pods -n lab-demo -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $ORIGINAL_POD -n lab-demo > /dev/null 2>&1

echo "복구 대기 중 (30초)..."
sleep 30

RECOVERED_PODS=$(kubectl get pods -n lab-demo -l app=nginx --no-headers | grep "1/1.*Running" | wc -l)
if [ "$RECOVERED_PODS" -eq 3 ]; then
    echo "✅ PASS: Pod 자동 복구 테스트"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL: Pod 자동 복구 테스트 ($RECOVERED_PODS/3)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# 11. 성능 및 안정성 검증
echo "11. 성능 및 안정성 검증"
echo "====================="
echo ""

echo "📊 현재 클러스터 상태 요약:"
echo "노드 수: $(kubectl get nodes --no-headers | wc -l)"
echo "네임스페이스 수: $(kubectl get namespaces --no-headers | wc -l)"
echo "전체 Pod 수: $(kubectl get pods --all-namespaces --no-headers | wc -l)"
echo "lab-demo Pod 수: $(kubectl get pods -n lab-demo --no-headers | wc -l)"
echo ""

echo "🔍 리소스 사용량 (가능한 경우):"
kubectl top nodes 2>/dev/null || echo "Metrics Server가 설치되지 않음"
kubectl top pods -n lab-demo 2>/dev/null || echo "Pod 메트릭을 사용할 수 없음"
echo ""

echo "📜 최근 이벤트 (마지막 5개):"
kubectl get events -n lab-demo --sort-by='.lastTimestamp' | tail -5
echo ""

# 12. 테스트 결과 요약
echo ""
echo "=== Kubernetes 환경 종합 테스트 결과 ==="
echo ""
echo "📊 테스트 통계:"
echo "- 총 테스트: $TOTAL_TESTS"
echo "- 성공: $PASSED_TESTS"
echo "- 실패: $FAILED_TESTS"
echo "- 성공률: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 모든 테스트 통과! K8s 환경이 완벽하게 구축되었습니다!"
    echo ""
    echo "✅ 검증된 기능:"
    echo "- 클러스터 기본 동작"
    echo "- Pod 생성 및 관리"
    echo "- 서비스 디스커버리"
    echo "- 로드밸런싱"
    echo "- 설정 관리 (ConfigMap)"
    echo "- 리소스 제한"
    echo "- 헬스 체크"
    echo "- 스케일링"
    echo "- 장애 복구"
    echo ""
    echo "🚀 Lab 2 진행 준비 완료!"
elif [ $FAILED_TESTS -le 2 ]; then
    echo "⚠️ 대부분의 테스트 통과. 일부 기능에 문제가 있을 수 있습니다."
    echo "Lab 2 진행 가능하지만 문제 해결을 권장합니다."
else
    echo "❌ 여러 테스트 실패. 환경 점검이 필요합니다."
    echo "Lab 2 진행 전에 문제를 해결해주세요."
fi

echo ""
echo "🔧 문제 해결 도움말:"
echo "- kubectl get events --sort-by='.lastTimestamp' -n lab-demo"
echo "- kubectl describe pod <pod-name> -n lab-demo"
echo "- kubectl logs <pod-name> -n lab-demo"
echo "- kubectl get all -n lab-demo"
echo ""
echo "📚 추가 정보:"
echo "- K8s 공식 문서: https://kubernetes.io/docs/"
echo "- kubectl 치트시트: https://kubernetes.io/docs/reference/kubectl/cheatsheet/"
echo ""
echo "다음 단계: Lab 2에서 실제 애플리케이션 마이그레이션 실습"