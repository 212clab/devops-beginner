#!/bin/bash

# Lab 1 Step 2-1: 영속적 스토리지 생성

echo "🚀 Lab 1 Step 2-1: 데이터베이스 스토리지 생성 시작..."

echo "💾 PVC 생성 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: day3-lab
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
EOF

echo "⏳ PVC 바인딩 대기 중..."
kubectl wait --for=condition=Bound pvc/postgres-data --timeout=60s

echo "✅ 데이터베이스 스토리지 생성 완료!"
echo ""
echo "📊 PVC 상태:"
kubectl get pvc postgres-data
echo ""
echo "🎯 다음 단계: PostgreSQL 데이터베이스 배포"
