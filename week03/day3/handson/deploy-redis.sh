#!/bin/bash

# Step 3-2: 캐시용 고성능 스토리지 추가
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: day3-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-cache-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-cache-pvc
  namespace: day3-lab
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: day3-lab
spec:
  selector:
    app: redis-cache
  ports:
  - port: 6379
    targetPort: 6379
EOF

# Redis Pod 시작 대기
kubectl wait --for=condition=Ready pod -l app=redis-cache --timeout=120s