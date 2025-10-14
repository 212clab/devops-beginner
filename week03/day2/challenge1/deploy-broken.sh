#!/bin/bash

# Challenge 2: 문제가 있는 워크로드 배포
cd "$(dirname "$0")"

echo "🚀 Challenge 2: 배포 재해 시나리오 시작"

# 네임스페이스 생성
kubectl create namespace day2-challenge --dry-run=client -o yaml | kubectl apply -f -

echo "📦 문제가 있는 애플리케이션 배포 중..."
echo ""

# 시나리오 1: 이미지 배포 실패
echo "1️⃣ Frontend 배포 (이미지 오류)"
kubectl apply -f broken-frontend-deployment.yaml

# 시나리오 2: 리소스 부족
echo "2️⃣ Analytics 배포 (리소스 부족)"
kubectl apply -f broken-analytics-deployment.yaml

# 시나리오 3: 롤링 업데이트 실패
echo "3️⃣ API Server 배포 (롤링 업데이트 문제)"
kubectl apply -f broken-api-deployment.yaml

# 시나리오 4: 노드 스케줄링 실패
echo "4️⃣ Database 배포 (스케줄링 실패)"
kubectl apply -f broken-database-deployment.yaml

echo ""
echo "❌ 문제가 있는 워크로드 배포 완료"
echo ""
echo "🎯 4가지 배포 문제 시나리오:"
echo "  1. Frontend: 잘못된 이미지 태그"
echo "  2. Analytics: 과도한 리소스 요청"
echo "  3. API Server: 잘못된 롤링 업데이트 전략"
echo "  4. Database: 잘못된 노드 셀렉터"
echo ""
echo "🔍 문제를 찾아 해결해보세요!"
echo ""
echo "📋 확인 명령어:"
echo "  kubectl get pods -n day2-challenge"
echo "  kubectl describe pod <pod-name> -n day2-challenge"
echo "  kubectl get deployments -n day2-challenge"
echo ""
echo "📝 문제 파일:"
echo "  - broken-frontend-deployment.yaml"
echo "  - broken-analytics-deployment.yaml"
echo "  - broken-api-deployment.yaml"
echo "  - broken-database-deployment.yaml"
