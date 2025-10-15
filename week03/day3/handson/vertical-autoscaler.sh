#!/bin/bash

# VPA (Vertical Pod Autoscaler) 설치 단계 추가
echo "🔧 VPA 설치 중 (Custom Resource Definition 및 컨트롤러)"

# VPA 설치 Manifest 적용 (404 문제 해결된 경로 사용)
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/v1.0.0/full-vpa-v1.yaml

echo "⏳ VPA CRD 등록 대기 중..."
# VPA CRD가 등록될 때까지 최대 30초 대기
kubectl wait --for condition=Established crd/verticalpodautoscalers.autoscaling.k8s.io --timeout=30s

echo "✅ VPA 설치 완료 및 CRD 등록 확인"
# Step 4-2: VPA (Vertical Pod Autoscaler) 설정



kubectl apply -f - <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: redis-vpa
  namespace: day3-lab
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: redis-cache
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: redis
      maxAllowed:
        cpu: 500m
        memory: 512Mi
      minAllowed:
        cpu: 50m
        memory: 64Mi
EOF
