#!/bin/bash

# Week 3 Day 3 Lab 1: 부하테스트 스크립트
# 목적: 3-Tier 애플리케이션의 성능 테스트

echo "=== 부하테스트 시작 ==="

# 1. 기본 연결 테스트
echo "1. 기본 연결 테스트 중..."

# 외부에서 NodePort 테스트
NODEPORT_URL="http://localhost:30080"
echo "NodePort 연결 테스트: $NODEPORT_URL"
if curl -s $NODEPORT_URL > /dev/null 2>&1; then
    echo "✅ NodePort 연결 성공"
else
    echo "❌ NodePort 연결 실패"
    exit 1
fi

# 2. 가벼운 부하테스트 (10 동시 사용자, 30초)
echo "2. 가벼운 부하테스트 실행 중..."
kubectl run load-test-light -n day3-lab --image=busybox --rm -it --restart=Never -- sh -c "
for i in \$(seq 1 10); do
  (for j in \$(seq 1 30); do
    wget -q -O- http://frontend-service || echo 'fail'
    sleep 1
  done) &
done
wait
"

# 3. 중간 부하테스트 (50 동시 사용자, 60초)
echo "3. 중간 부하테스트 실행 중..."
kubectl run load-test-medium -n day3-lab --image=busybox --rm -it --restart=Never -- sh -c "
for i in \$(seq 1 50); do
  (for j in \$(seq 1 60); do
    wget -q -O- http://frontend-service || echo 'fail'
    sleep 1
  done) &
done
wait
"

# 4. 리소스 사용량 확인
echo "4. 리소스 사용량 확인 중..."
kubectl top pods -n day3-lab 2>/dev/null || echo "Metrics server not available"

echo ""
echo "=== 부하테스트 완료 ==="
echo ""
echo "📊 테스트 결과:"
echo "- 가벼운 부하: 10 동시 사용자 × 30초"
echo "- 중간 부하: 50 동시 사용자 × 60초"
echo ""
echo "💡 다음 단계:"
echo "- HPA 설정으로 자동 스케일링 테스트"
echo "- Grafana에서 메트릭 확인"
