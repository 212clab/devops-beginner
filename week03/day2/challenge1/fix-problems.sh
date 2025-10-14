#!/bin/bash

# Challenge 1: 문제 해결 스크립트
cd "$(dirname "$0")"

echo "🔧 Challenge 1: 문제 해결 시작"

# 해결 1: 올바른 이미지로 수정
kubectl patch deployment broken-app -n challenge1 -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"nginx:1.20"}]}}}}'

# 해결 2: 적절한 리소스로 수정
kubectl patch deployment resource-hungry -n challenge1 -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"100m","memory":"128Mi"}}}]}}}}'

echo "⏳ 수정 사항 적용 대기..."
kubectl rollout status deployment/broken-app -n challenge1 --timeout=60s
kubectl rollout status deployment/resource-hungry -n challenge1 --timeout=60s

echo "✅ 문제 해결 완료!"
kubectl get pods -n challenge1
