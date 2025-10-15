#!/bin/bash

# Lab 1 Step 2-2: PostgreSQL 데이터베이스 배포

echo "🚀 Lab 1 Step 2-2: PostgreSQL 데이터베이스 배포 시작...."

echo "🗄️ PostgreSQL Deployment 및 Service 생성 중..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: day3-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16
        env:
        - name: POSTGRES_DB
          value: shopdb
        - name: POSTGRES_USER
          value: shopuser
        - name: POSTGRES_PASSWORD
          value: shoppass
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 200m
            memory: 512Mi
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-data
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: day3-lab
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
EOF

echo "⏳ PostgreSQL Pod 시작 대기 중..."
kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s

echo "✅ PostgreSQL 데이터베이스 배포 완료!"
echo ""
echo "📊 데이터베이스 상태:"
kubectl get pods -l app=postgres
kubectl get svc database-service
echo ""
echo "🎯 다음 단계: 백엔드 API 서버 배포"
