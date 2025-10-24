#!/bin/bash
set -e
echo "=== HPA 설정 시작 ==="

echo "1/2 Production HPA 설정 중..."
kubectl apply -f - <<YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: production
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
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
YAML

echo "2/2 Staging HPA 설정 중..."
kubectl apply -f - <<YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
  namespace: staging
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
YAML

echo ""
sleep 5
kubectl get hpa -n production
kubectl get hpa -n staging

echo ""
echo "=== HPA 설정 완료 ==="
echo ""
echo "HPA 모니터링: kubectl get hpa --all-namespaces --watch"
echo "다음: Kubecost 대시보드에서 비용 분석"
