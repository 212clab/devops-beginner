#!/bin/bash

# Week 4 Day 1 Challenge 1: 포트 포워딩 종료 스크립트
# 사용법: ./stop-port-forward.sh

echo "=== 포트 포워딩 종료 ==="
echo ""

# 실행 중인 포트 포워딩 프로세스 확인
RUNNING_PROCESSES=$(pgrep -f "kubectl port-forward.*microservices-challenge" | wc -l)

if [ "$RUNNING_PROCESSES" -eq 0 ]; then
    echo "⚠️  실행 중인 포트 포워딩이 없습니다."
    echo ""
    exit 0
fi

echo "🔍 실행 중인 포트 포워딩: $RUNNING_PROCESSES 개"
echo ""

# 모든 포트 포워딩 프로세스 종료
echo "🛑 포트 포워딩 종료 중..."
pkill -f "kubectl port-forward.*microservices-challenge"

sleep 2

# 종료 확인
REMAINING=$(pgrep -f "kubectl port-forward.*microservices-challenge" | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ 모든 포트 포워딩이 종료되었습니다."
else
    echo "⚠️  일부 프로세스가 남아있습니다. 강제 종료 중..."
    pkill -9 -f "kubectl port-forward.*microservices-challenge"
    sleep 1
    echo "✅ 강제 종료 완료"
fi

echo ""
echo "=== 포트 포워딩 종료 완료 ==="
echo ""
