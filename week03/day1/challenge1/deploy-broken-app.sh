#!/bin/bash

# Challenge 1: 문제가 있는 웹 애플리케이션 배포 스크립트

echo "🚀 Challenge 1: 문제가 있는 웹 애플리케이션 배포 시작..."
echo "⚠️  이 애플리케이션들은 의도적으로 문제가 있습니다."

# 현재 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 스크립트 디렉토리: $SCRIPT_DIR"

# 기존 리소스 정리
echo "🧹 기존 리소스 정리 중..."
kubectl delete namespace day1-challenge 2>/dev/null || true
sleep 5

# 네임스페이스 생성
echo "📦 네임스페이스 생성 중..."
kubectl create namespace day1-challenge
kubectl config set-context --current --namespace=day1-challenge

echo "🏗️  문제가 있는 애플리케이션들 배포 중..."

# 시나리오 1: 포트 문제가 있는 Frontend 배포
echo "📱 Frontend 애플리케이션 배포 중 (포트 문제 포함)..."
kubectl apply -f broken-frontend.yaml

# 시나리오 2: 환경변수 문제가 있는 API 서버 배포
echo "🔧 API 서버 배포 중 (환경변수 문제 포함)..."
kubectl apply -f broken-api-server.yaml

# 시나리오 3: 잘못된 이미지 태그 배포
echo "🖼️  Frontend v2 배포 중 (이미지 문제 포함)..."
kubectl apply -f broken-frontend-v2.yaml

# 시나리오 4: 라벨 셀렉터 문제가 있는 Backend 배포
echo "⚙️  Backend 서비스 배포 중 (라벨 문제 포함)..."
kubectl apply -f broken-backend.yaml

# 정상적인 데이터베이스 (참조용)
echo "🗄️  데이터베이스 배포 중 (정상)..."
kubectl apply -f database.yaml

# 배포 완료 대기
echo "⏳ 배포 완료 대기 중 (30초)..."
sleep 30

echo ""
echo "💥 Challenge 1 문제 애플리케이션 배포 완료!"
echo ""
echo "🎯 배포된 문제들:"
echo "  1. Frontend Service: 잘못된 targetPort (8080 → 80)"
echo "  2. API Server: 잘못된 DATABASE_HOST 환경변수"
echo "  3. Frontend v2: 존재하지 않는 이미지 태그"
echo "  4. Backend Service: 잘못된 라벨 셀렉터"
echo ""
echo "🔍 현재 상태 확인:"
kubectl get pods -n day1-challenge
echo ""
kubectl get svc -n day1-challenge
echo ""
echo "🚀 Challenge 시작!"
echo "  1. 웹사이트 접근 테스트: curl http://localhost:30080"
echo "  2. API 서버 테스트: curl http://localhost:30081"
echo "  3. 각 문제를 하나씩 진단하고 해결하세요"
echo ""
echo "📋 사용 가능한 명령어:"
echo "  kubectl get pods -n day1-challenge"
echo "  kubectl describe pod <pod-name> -n day1-challenge"
echo "  kubectl logs <pod-name> -n day1-challenge"
echo "  kubectl get svc -n day1-challenge"
echo "  kubectl describe svc <service-name> -n day1-challenge"
echo ""
echo "🎯 목표: 모든 애플리케이션이 정상 동작하도록 문제 해결!"
