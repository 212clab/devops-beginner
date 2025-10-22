#!/bin/bash

# Week 4 Day 3 Challenge 1: 해결 검증
# 설명: 4가지 시나리오 해결 여부 자동 검증

echo "=== Challenge 해결 검증 시작 ==="
echo ""

PASS=0
FAIL=0

# 시나리오 1: mTLS STRICT 설정 확인
echo "1/4 시나리오 1 검증 중 (mTLS 설정)..."
MTLS_MODE=$(kubectl get peerauthentication default -n delivery-platform -o jsonpath='{.spec.mtls.mode}' 2>/dev/null || echo "")
if [ "$MTLS_MODE" = "STRICT" ]; then
  echo "✅ 시나리오 1: 통과 (mTLS STRICT 설정 확인)"
  ((PASS++))
else
  echo "❌ 시나리오 1: 실패 (현재 mode: $MTLS_MODE, 필요: STRICT)"
  ((FAIL++))
fi
echo ""

# 시나리오 2: JWT issuer 확인
echo "2/4 시나리오 2 검증 중 (JWT 검증)..."
JWT_ISSUER=$(kubectl get requestauthentication jwt-auth -n delivery-platform -o jsonpath='{.spec.jwtRules[0].issuer}' 2>/dev/null || echo "")
if [[ "$JWT_ISSUER" == *"auth.delivery-platform.svc.cluster.local"* ]]; then
  echo "✅ 시나리오 2: 통과 (JWT issuer 올바름)"
  ((PASS++))
else
  echo "❌ 시나리오 2: 실패 (현재 issuer: $JWT_ISSUER)"
  ((FAIL++))
fi
echo ""

# 시나리오 3: 리소스 제한 확인
echo "3/4 시나리오 3 검증 중 (리소스 제한)..."
CPU_LIMIT=$(kubectl get deployment delivery-service-broken -n delivery-platform -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "")
MEM_LIMIT=$(kubectl get deployment delivery-service-broken -n delivery-platform -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")

if [ -n "$CPU_LIMIT" ] && [ -n "$MEM_LIMIT" ]; then
  echo "✅ 시나리오 3: 통과 (리소스 제한 설정됨: CPU=$CPU_LIMIT, Memory=$MEM_LIMIT)"
  ((PASS++))
else
  echo "❌ 시나리오 3: 실패 (리소스 제한 누락)"
  ((FAIL++))
fi
echo ""

# 시나리오 4: AuthorizationPolicy principal 확인
echo "4/4 시나리오 4 검증 중 (Authorization Policy)..."
PRINCIPAL=$(kubectl get authorizationpolicy merchant-policy -n delivery-platform -o jsonpath='{.spec.rules[0].from[0].source.principals[0]}' 2>/dev/null || echo "")
if [[ "$PRINCIPAL" == *"order-service"* ]]; then
  echo "✅ 시나리오 4: 통과 (올바른 ServiceAccount principal)"
  ((PASS++))
else
  echo "❌ 시나리오 4: 실패 (현재 principal: $PRINCIPAL)"
  ((FAIL++))
fi
echo ""

# 결과 요약
echo "=== 검증 결과 ==="
echo "통과: $PASS/4"
echo "실패: $FAIL/4"
echo ""

if [ $PASS -eq 4 ]; then
  echo "🎉 축하합니다! 모든 시나리오를 해결했습니다!"
  echo ""
  echo "다음 단계:"
  echo "1. 실제 통신 테스트 수행"
  echo "2. 모니터링 대시보드에서 메트릭 확인"
  echo "3. 학습 내용 정리 및 회고"
  exit 0
else
  echo "💡 아직 해결하지 못한 시나리오가 있습니다."
  echo ""
  echo "도움이 필요하면:"
  echo "- hints.md 파일 참고"
  echo "- kubectl describe로 상세 정보 확인"
  echo "- kubectl logs로 로그 분석"
  exit 1
fi
