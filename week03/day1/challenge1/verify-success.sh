#!/bin/bash

# Challenge 1: 웹 애플리케이션 복구 성공 검증 스크립트

echo "🎯 Challenge 1 웹 애플리케이션 복구 검증 시작..."
echo "=================================================="

# 네임스페이스 설정
kubectl config set-context --current --namespace=day1-challenge

TOTAL_TESTS=0
PASSED_TESTS=0

# 테스트 함수
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "[$TOTAL_TESTS] $test_name: "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASS"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo "❌ FAIL"
        return 1
    fi
}

# 상세 테스트 함수
run_detailed_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo "[$TOTAL_TESTS] $test_name:"
    
    if result=$(eval "$test_command" 2>&1); then
        echo "✅ PASS"
        echo "$result" | head -2
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo "❌ FAIL"
        echo "$result" | head -2
        return 1
    fi
    echo ""
}

echo "🔍 Pod 상태 테스트"
echo "--------------------------------------------------"

# 1. 모든 Pod Running 상태 확인
echo "[$((TOTAL_TESTS + 1))] 모든 Pod Running 상태 확인:"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
NOT_RUNNING_PODS=$(kubectl get pods -n day1-challenge --no-headers | grep -v " Running " | grep -v " Completed " | wc -l)

if [ "$NOT_RUNNING_PODS" -eq 0 ]; then
    echo "✅ PASS - 모든 Pod가 Running 상태"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    kubectl get pods -n day1-challenge | head -5
else
    echo "❌ FAIL - $NOT_RUNNING_PODS 개 Pod가 Running 상태가 아님"
    kubectl get pods -n day1-challenge | grep -v " Running "
fi
echo ""

# 2. Frontend Pod 상태 확인
run_test "Frontend Pod 정상 실행" "kubectl get pods -l app=frontend -n day1-challenge | grep -q Running"

# 3. API Server Pod 상태 확인
run_test "API Server Pod 정상 실행" "kubectl get pods -l app=api-server -n day1-challenge | grep -q Running"

# 4. Backend Pod 상태 확인
run_test "Backend Pod 정상 실행" "kubectl get pods -l app=backend -n day1-challenge | grep -q Running"

echo "🔍 Service 연결성 테스트"
echo "--------------------------------------------------"

# 5. Service Endpoints 확인
echo "[$((TOTAL_TESTS + 1))] Service Endpoints 확인:"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
EMPTY_ENDPOINTS=$(kubectl get endpoints -n day1-challenge --no-headers | awk '$2 == "<none>"' | wc -l)

if [ "$EMPTY_ENDPOINTS" -eq 0 ]; then
    echo "✅ PASS - 모든 Service에 Endpoints 존재"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    kubectl get endpoints -n day1-challenge
else
    echo "❌ FAIL - $EMPTY_ENDPOINTS 개 Service에 Endpoints 없음"
    kubectl get endpoints -n day1-challenge | grep "<none>"
fi
echo ""

echo "🔍 웹 애플리케이션 접근 테스트"
echo "--------------------------------------------------"

# 6. Frontend 웹사이트 접근 테스트
echo "[$((TOTAL_TESTS + 1))] Frontend 웹사이트 접근 테스트:"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# NodePort 서비스 포트 확인
FRONTEND_PORT=$(kubectl get svc frontend-service -n day1-challenge -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

if [ ! -z "$FRONTEND_PORT" ]; then
    if curl -s --connect-timeout 5 http://localhost:$FRONTEND_PORT >/dev/null 2>&1; then
        echo "✅ PASS - Frontend 웹사이트 접근 성공 (포트: $FRONTEND_PORT)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ FAIL - Frontend 웹사이트 접근 실패 (포트: $FRONTEND_PORT)"
        echo "  힌트: Service의 targetPort와 Pod의 containerPort 확인"
    fi
else
    echo "❌ FAIL - Frontend Service 포트 정보 없음"
fi
echo ""

# 7. API 서버 접근 테스트
echo "[$((TOTAL_TESTS + 1))] API 서버 접근 테스트:"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

API_PORT=$(kubectl get svc api-service -n day1-challenge -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

if [ ! -z "$API_PORT" ]; then
    if curl -s --connect-timeout 5 http://localhost:$API_PORT >/dev/null 2>&1; then
        echo "✅ PASS - API 서버 접근 성공 (포트: $API_PORT)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ FAIL - API 서버 접근 실패 (포트: $API_PORT)"
        echo "  힌트: 환경변수 설정 확인"
    fi
else
    echo "❌ FAIL - API Service 포트 정보 없음"
fi
echo ""

echo "🔍 Pod 내부 연결성 테스트"
echo "--------------------------------------------------"

# 8. Backend Service 연결 테스트
echo "[$((TOTAL_TESTS + 1))] Backend Service 연결 테스트:"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 테스트용 Pod 생성하여 내부 서비스 접근 테스트
kubectl run test-pod --image=busybox --rm -it --restart=Never -n day1-challenge --command -- timeout 10 wget -qO- http://backend-service.day1-challenge.svc.cluster.local >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ PASS - Backend Service 내부 연결 성공"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL - Backend Service 내부 연결 실패"
    echo "  힌트: Service selector와 Pod labels 확인"
fi
echo ""

# 9. 이미지 문제 해결 확인
echo "[$((TOTAL_TESTS + 1))] 이미지 문제 해결 확인:"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

IMAGE_PULL_ERRORS=$(kubectl get pods -n day1-challenge --no-headers | grep -E "(ErrImagePull|ImagePullBackOff)" | wc -l)

if [ "$IMAGE_PULL_ERRORS" -eq 0 ]; then
    echo "✅ PASS - 이미지 Pull 오류 없음"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "❌ FAIL - $IMAGE_PULL_ERRORS 개 Pod에서 이미지 Pull 오류"
    echo "  힌트: Deployment의 이미지 태그 확인"
fi
echo ""

# 최종 결과
echo "=================================================="
echo "🎯 Challenge 1 웹 애플리케이션 복구 검증 결과"
echo "=================================================="
echo "총 테스트: $TOTAL_TESTS"
echo "통과: $PASSED_TESTS"
echo "실패: $((TOTAL_TESTS - PASSED_TESTS))"

PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo "통과율: $PASS_RATE%"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo ""
    echo "🎉 축하합니다! Challenge 1을 완벽하게 해결했습니다!"
    echo "✅ 모든 웹 애플리케이션이 정상 동작하고 있습니다."
    echo ""
    echo "🏆 해결한 문제들:"
    echo "  - ✅ Frontend Service 포트 매핑 문제"
    echo "  - ✅ API Server 환경변수 설정 문제"
    echo "  - ✅ 이미지 태그 문제"
    echo "  - ✅ Service 라벨 셀렉터 문제"
    echo ""
    echo "🎓 학습한 내용:"
    echo "  - Pod와 Service 간 포트 매핑"
    echo "  - 환경변수 설정 및 관리"
    echo "  - 컨테이너 이미지 관리"
    echo "  - Service와 Pod 간 라벨 매칭"
    echo "  - Kubernetes 기본 디버깅 방법"
    echo ""
    echo "🚀 다음 단계: 더 복잡한 Kubernetes 시나리오에 도전해보세요!"
    
elif [ $PASS_RATE -ge 70 ]; then
    echo ""
    echo "👍 잘했습니다! 대부분의 문제를 해결했습니다."
    echo "⚠️  아직 해결되지 않은 문제가 있습니다."
    echo ""
    echo "💡 남은 문제 해결 힌트:"
    if [ $PASS_RATE -lt 100 ]; then
        echo "  - kubectl describe pod <pod-name> 으로 상세 정보 확인"
        echo "  - kubectl logs <pod-name> 으로 로그 확인"
        echo "  - kubectl get svc -o wide 로 서비스 설정 확인"
        echo "  - kubectl get endpoints 로 연결 상태 확인"
    fi
    
else
    echo ""
    echo "🔧 아직 해결해야 할 문제들이 있습니다."
    echo "📋 단계별 접근을 권장합니다:"
    echo ""
    echo "1️⃣ 먼저 Pod 상태 확인:"
    echo "   kubectl get pods -n day1-challenge"
    echo "   kubectl describe pod <pod-name> -n day1-challenge"
    echo ""
    echo "2️⃣ Service 연결 확인:"
    echo "   kubectl get svc -n day1-challenge"
    echo "   kubectl get endpoints -n day1-challenge"
    echo ""
    echo "3️⃣ 로그 확인:"
    echo "   kubectl logs <pod-name> -n day1-challenge"
    echo ""
    echo "4️⃣ 설정 수정 (두 가지 방법):"
    echo "   방법 1: kubectl edit deployment <deployment-name> -n day1-challenge"
    echo "   방법 2: kubectl apply -f <fixed-file>.yaml"
    echo "   kubectl edit service <service-name> -n day1-challenge"
    echo "   또는: kubectl apply -f <fixed-service>.yaml"
fi

# echo ""
# echo "📊 현재 클러스터 상태:"
# echo "kubectl get all -n day1-challenge"
# kubectl get all -n day1-challenge 2>/dev/null || echo "리소스 상태 확인 불가"
