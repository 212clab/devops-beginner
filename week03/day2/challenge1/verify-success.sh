#!/bin/bash

# Challenge 2: 성공 검증 스크립트
cd "$(dirname "$0")"

echo "🔍 Challenge 2 배포 재해 시나리오 검증 시작..."
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0

echo "=== 네임스페이스 상태 ==="
kubectl get namespace day2-challenge
echo ""

echo "=== Deployment 상태 ==="
kubectl get deployments -n day2-challenge
echo ""

echo "=== Pod 상태 ==="
kubectl get pods -n day2-challenge -o wide
echo ""

echo "=== 시나리오별 상세 검증 ==="
echo ""

# 시나리오 1: Frontend (이미지 문제)
echo "1️⃣ Frontend (이미지 배포 실패)"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
FRONTEND_READY=$(kubectl get deployment frontend -n day2-challenge -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
FRONTEND_DESIRED=$(kubectl get deployment frontend -n day2-challenge -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "3")

if [ "$FRONTEND_READY" = "$FRONTEND_DESIRED" ]; then
    echo "   ✅ Frontend: $FRONTEND_READY/$FRONTEND_DESIRED Pod Ready"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "   ❌ Frontend: $FRONTEND_READY/$FRONTEND_DESIRED Pod Ready"
    echo "   힌트: 이미지 태그를 확인하세요 (nginx:1.20)"
fi
echo ""

# 시나리오 2: Analytics (리소스 부족)
echo "2️⃣ Analytics (리소스 부족)"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
ANALYTICS_READY=$(kubectl get deployment analytics -n day2-challenge -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
ANALYTICS_DESIRED=$(kubectl get deployment analytics -n day2-challenge -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "2")

if [ "$ANALYTICS_READY" = "$ANALYTICS_DESIRED" ]; then
    echo "   ✅ Analytics: $ANALYTICS_READY/$ANALYTICS_DESIRED Pod Ready"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "   ❌ Analytics: $ANALYTICS_READY/$ANALYTICS_DESIRED Pod Ready"
    echo "   힌트: 리소스 요청량을 줄이세요 (cpu: 200m, memory: 256Mi)"
fi
echo ""

# 시나리오 3: API Server (롤링 업데이트 실패)
echo "3️⃣ API Server (롤링 업데이트 실패)"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
API_READY=$(kubectl get deployment api-server -n day2-challenge -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
API_DESIRED=$(kubectl get deployment api-server -n day2-challenge -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "5")

if [ "$API_READY" = "$API_DESIRED" ]; then
    echo "   ✅ API Server: $API_READY/$API_DESIRED Pod Ready"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "   ❌ API Server: $API_READY/$API_DESIRED Pod Ready"
    echo "   힌트: 롤링 업데이트 전략을 수정하세요 (maxUnavailable: 1, maxSurge: 1)"
fi
echo ""

# 시나리오 4: Database (스케줄링 실패)
echo "4️⃣ Database (노드 스케줄링 실패)"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
DATABASE_READY=$(kubectl get deployment database -n day2-challenge -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
DATABASE_DESIRED=$(kubectl get deployment database -n day2-challenge -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

if [ "$DATABASE_READY" = "$DATABASE_DESIRED" ]; then
    echo "   ✅ Database: $DATABASE_READY/$DATABASE_DESIRED Pod Ready"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo "   ❌ Database: $DATABASE_READY/$DATABASE_DESIRED Pod Ready"
    echo "   힌트: nodeSelector를 제거하세요"
fi
echo ""

# 최종 결과
echo "=================================================="
echo "🎯 Challenge 2 검증 결과"
echo "=================================================="
echo "총 시나리오: $TOTAL_TESTS"
echo "해결 완료: $PASSED_TESTS"
echo "미해결: $((TOTAL_TESTS - PASSED_TESTS))"

PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo "완료율: $PASS_RATE%"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo "🎉 축하합니다! Challenge 2를 완벽하게 해결했습니다!"
    echo ""
    echo "✅ 해결한 배포 문제들:"
    echo "  1. Frontend: 이미지 태그 수정"
    echo "  2. Analytics: 리소스 요청량 조정"
    echo "  3. API Server: 롤링 업데이트 전략 개선"
    echo "  4. Database: 노드 셀렉터 제거"
    echo ""
    echo "🎓 학습한 내용:"
    echo "  - 이미지 배포 문제 해결"
    echo "  - 리소스 관리 및 최적화"
    echo "  - 무중단 배포 전략"
    echo "  - Pod 스케줄링 문제 해결"
elif [ $PASS_RATE -ge 50 ]; then
    echo "👍 절반 이상 해결했습니다! 조금만 더 힘내세요!"
    echo ""
    echo "💡 남은 문제 해결 가이드:"
    echo "  - kubectl describe pod <pod-name> -n day2-challenge"
    echo "  - kubectl logs <pod-name> -n day2-challenge"
    echo "  - kubectl get events -n day2-challenge"
else
    echo "🔧 아직 해결해야 할 문제들이 많습니다."
    echo ""
    echo "📋 단계별 접근:"
    echo "  1. Pod 상태 확인: kubectl get pods -n day2-challenge"
    echo "  2. 상세 정보: kubectl describe pod <pod-name> -n day2-challenge"
    echo "  3. 힌트 확인: cat hints.md"
    echo "  4. 해결책 참고: cat solutions.md"
fi
