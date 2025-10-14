#!/bin/bash

# Challenge 2 정리 스크립트
cd "$(dirname "$0")"

echo "🧹 Challenge 2 환경 정리 시작..."

echo "📦 네임스페이스 삭제 중..."
kubectl delete namespace day2-challenge --ignore-not-found=true

echo "✅ Challenge 2 환경 정리 완료!"
echo "   (클러스터는 유지되어 다른 Challenge에서 재사용 가능)"
