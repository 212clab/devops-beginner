#!/bin/bash

# Week 3 Day 5 Lab 1: Metrics Server 및 HPA 설정
# 사용법: ./04-setup-hpa.sh

set -e

NAMESPACE="day5-lab"

echo "=== Metrics Server 및 HPA 설정 시작 ==="
echo ""

# Namespace 확인
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "❌ Namespace '$NAMESPACE'가 존재하지 않습니다."
    echo "먼저 ./00-setup-cluster.sh를 실행하세요."
    exit 1
fi

# Metrics Server 설치
echo "1. Metrics Server 설치 중..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "✅ Metrics Server 설치 완료"

# Kind 클러스터용 패치
echo ""
echo "2. Metrics Server 설정 패치 중..."
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "✅ 패치 완료"

# Metrics Server 준비 대기
echo ""
echo "3. Metrics Server 준비 대기 중... (약 30초)"
sleep 30

# Metrics Server 확인
echo ""
echo "🔍 Metrics Server 상태:"
kubectl get deployment metrics-server -n kube-system

# 메트릭 수집 확인
echo ""
echo "4. 메트릭 수집 확인 중..."
echo ""

MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if kubectl top nodes &> /dev/null; then
        echo "✅ 노드 메트릭 수집 성공"
        kubectl top nodes
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⏳ 메트릭 수집 대기 중... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "⚠️  메트릭 수집이 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요."
fi

# HPA 생성
echo ""
echo "5. HPA 생성 중..."
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 4
        periodSeconds: 30
      selectPolicy: Max
EOF

echo "✅ HPA 생성 완료"

# HPA 상태 확인
echo ""
echo "6. HPA 상태 확인 중..."
echo ""

sleep 5

echo "📊 HPA 상태:"
kubectl get hpa -n $NAMESPACE web-app-hpa

echo ""
echo "📋 HPA 상세 정보:"
kubectl describe hpa -n $NAMESPACE web-app-hpa

echo ""
echo "=== HPA 설정 완료 ==="
echo ""
echo "💡 부하 테스트:"
echo "   kubectl run -n $NAMESPACE load-generator --image=busybox --restart=Never -- /bin/sh -c \"while true; do wget -q -O- http://web-app; done\""
echo ""
echo "💡 HPA 모니터링:"
echo "   watch kubectl get hpa -n $NAMESPACE web-app-hpa"
echo ""
echo "💡 부하 중지:"
echo "   kubectl delete pod -n $NAMESPACE load-generator"
