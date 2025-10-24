#!/bin/bash

# Week 4 Day 5 Challenge 1: 해결 검증
# 설명: 4가지 시나리오 해결 여부 자동 검증

echo "=== Challenge 해결 검증 시작 ==="
echo ""

PASS=0
FAIL=0

# 시나리오 1 검증: 리소스 Right-sizing
echo "1/4 시나리오 1 검증 중: 리소스 Right-sizing..."

# Production 네임스페이스의 주요 서비스 리소스 확인
FRONTEND_CPU=$(kubectl get deployment frontend -n production -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
FRONTEND_MEM=$(kubectl get deployment frontend -n production -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")

# CPU가 200m-500m 범위인지 확인 (원래 2000m에서 최적화)
if [[ "$FRONTEND_CPU" =~ ^[2-5][0-9][0-9]m$ ]] && [[ "$FRONTEND_MEM" =~ ^[2-5][0-9][0-9]Mi$ ]]; then
  echo "✅ 시나리오 1: 통과 (Frontend 리소스 최적화 완료)"
  ((PASS++))
else
  echo "❌ 시나리오 1: 실패 (Frontend 리소스가 여전히 과도하거나 너무 낮음)"
  echo "   현재: CPU=$FRONTEND_CPU, Memory=$FRONTEND_MEM"
  echo "   권장: CPU=200-500m, Memory=256-512Mi"
  ((FAIL++))
fi

# 시나리오 2 검증: HPA 설정
echo ""
echo "2/4 시나리오 2 검증 중: HPA 설정..."

# Production HPA 확인
HPA_COUNT=$(kubectl get hpa -n production --no-headers 2>/dev/null | wc -l)

if [ "$HPA_COUNT" -ge 3 ]; then
  # Frontend HPA 상세 확인
  FRONTEND_HPA_MIN=$(kubectl get hpa frontend-hpa -n production -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "0")
  FRONTEND_HPA_MAX=$(kubectl get hpa frontend-hpa -n production -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "0")
  
  if [ "$FRONTEND_HPA_MIN" -ge 2 ] && [ "$FRONTEND_HPA_MAX" -ge 8 ]; then
    echo "✅ 시나리오 2: 통과 (HPA 설정 완료)"
    ((PASS++))
  else
    echo "❌ 시나리오 2: 실패 (HPA 설정이 부적절함)"
    echo "   현재: min=$FRONTEND_HPA_MIN, max=$FRONTEND_HPA_MAX"
    echo "   권장: min=2, max=10"
    ((FAIL++))
  fi
else
  echo "❌ 시나리오 2: 실패 (HPA가 충분히 설정되지 않음)"
  echo "   현재 HPA 개수: $HPA_COUNT"
  echo "   권장: 최소 3개 이상 (frontend, user-service, product-service 등)"
  ((FAIL++))
fi

# 시나리오 3 검증: 환경별 최적화
echo ""
echo "3/4 시나리오 3 검증 중: 환경별 최적화..."

# Staging 복제본 수 확인
STAGING_FRONTEND_REPLICAS=$(kubectl get deployment frontend -n staging -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
STAGING_USER_REPLICAS=$(kubectl get deployment user-service -n staging -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

# Development 복제본 수 확인
DEV_FRONTEND_REPLICAS=$(kubectl get deployment frontend -n development -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
DEV_USER_REPLICAS=$(kubectl get deployment user-service -n development -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

if [ "$STAGING_FRONTEND_REPLICAS" -le 2 ] && [ "$STAGING_USER_REPLICAS" -le 2 ] && \
   [ "$DEV_FRONTEND_REPLICAS" -eq 1 ] && [ "$DEV_USER_REPLICAS" -eq 1 ]; then
  echo "✅ 시나리오 3: 통과 (환경별 복제본 최적화 완료)"
  ((PASS++))
else
  echo "❌ 시나리오 3: 실패 (환경별 복제본이 여전히 과도함)"
  echo "   Staging: frontend=$STAGING_FRONTEND_REPLICAS, user-service=$STAGING_USER_REPLICAS (권장: 각 2개 이하)"
  echo "   Development: frontend=$DEV_FRONTEND_REPLICAS, user-service=$DEV_USER_REPLICAS (권장: 각 1개)"
  ((FAIL++))
fi

# 시나리오 4 검증: 리소스 제한 설정
echo ""
echo "4/4 시나리오 4 검증 중: 리소스 제한 설정..."

# limits 누락된 Pod 찾기
PODS_WITHOUT_LIMITS=$(kubectl get pods -n production -o json 2>/dev/null | \
  jq -r '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name' 2>/dev/null | wc -l)

if [ "$PODS_WITHOUT_LIMITS" -eq 0 ]; then
  echo "✅ 시나리오 4: 통과 (모든 Pod에 리소스 제한 설정 완료)"
  ((PASS++))
else
  echo "❌ 시나리오 4: 실패 (리소스 제한이 누락된 Pod 존재)"
  echo "   limits 누락 Pod 개수: $PODS_WITHOUT_LIMITS"
  echo "   모든 Pod에 requests와 limits를 설정해야 합니다"
  ((FAIL++))
fi

echo ""
echo "=== 검증 결과 ==="
echo "통과: $PASS/4"
echo "실패: $FAIL/4"

if [ $PASS -eq 4 ]; then
  echo ""
  echo "🎉 축하합니다! 모든 시나리오를 해결했습니다!"
  echo ""
  echo "💰 예상 비용 절감 효과:"
  echo "- 시나리오 1 (Right-sizing): 50-80% 절감"
  echo "- 시나리오 2 (HPA): 30-60% 절감"
  echo "- 시나리오 3 (환경별 최적화): 60-70% 절감"
  echo "- 시나리오 4 (리소스 제한): 노드 과부하 방지"
  echo ""
  echo "📊 Grafana FinOps에서 실제 비용 절감 효과를 확인하세요:"
  echo "http://localhost:30091"
  exit 0
else
  echo ""
  echo "💡 아직 해결하지 못한 시나리오가 있습니다."
  echo ""
  echo "🔍 문제 해결 가이드:"
  echo "1. kubectl top pods --all-namespaces 로 리소스 사용률 확인"
  echo "2. kubectl get hpa --all-namespaces 로 HPA 설정 확인"
  echo "3. kubectl get deployments --all-namespaces 로 복제본 수 확인"
  echo "4. kubectl describe pod <pod-name> 로 리소스 설정 확인"
  exit 1
fi
