#!/bin/bash

# API Server 직접 호출 테스트 스크립트

echo "=== API Server Direct Access Test ==="

echo "1. Getting Authentication Token..."

# kubectl proxy를 사용하여 인증 문제 해결
echo "Starting kubectl proxy for authenticated access..."
kubectl proxy --port=8080 &
PROXY_PID=$!
sleep 3
API_SERVER="http://localhost:8080"
echo "Using kubectl proxy at $API_SERVER"

# 백업용 토큰 방식도 시도
TOKEN=$(kubectl create token default -n kube-system --duration=3600s 2>/dev/null)
if [ ! -z "$TOKEN" ]; then
    echo "Token also available as backup method"
fi

# API Server 주소 확인
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "API Server: $API_SERVER"

echo "2. Testing Direct API Calls..."

# 직접 API 호출 테스트 (kubectl proxy 사용)
echo "Getting pods in lab-day1 namespace:"
curl -s $API_SERVER/api/v1/namespaces/lab-day1/pods

echo -e "\n3. Checking API Versions..."

# API 버전 확인
echo "Available API versions:"
curl -s $API_SERVER/api

echo -e "\n4. Collecting API Metrics..."

# 메트릭 엔드포인트 확인
echo "API Server metrics (first 20 lines):"
curl -s $API_SERVER/metrics | head -20

echo -e "\n5. Analyzing Performance Metrics..."

# API Server 메트릭 수집
curl -s $API_SERVER/metrics > api-metrics.txt

# 주요 메트릭 분석
echo "=== API Server Request Duration ==="
grep "apiserver_request_duration_seconds" api-metrics.txt | head -10

echo "=== API Server Request Total ==="
grep "apiserver_request_total" api-metrics.txt | head -10

echo "=== ETCD Request Duration ==="
grep "etcd_request_duration_seconds" api-metrics.txt | head -10

echo "API Server test completed!"
echo "Metrics saved to api-metrics.txt"

# kubectl proxy 종료
if [ ! -z "$PROXY_PID" ]; then
    kill $PROXY_PID 2>/dev/null
    echo "kubectl proxy stopped"
fi