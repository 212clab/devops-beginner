#!/bin/bash

# Step 2-1: 기존 Deployment를 StatefulSet으로 전환
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  namespace: day3-lab
spec:
  clusterIP: None
  selector:
    app: postgres-cluster
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: day3-lab
spec:
  selector:
    app: postgres-cluster
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
  namespace: day3-lab
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres-cluster
  template:
    metadata:
      labels:
        app: postgres-cluster
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
        - name: POSTGRES_REPLICATION_MODE
          value: master
        - name: POSTGRES_REPLICATION_USER
          value: replicator
        - name: POSTGRES_REPLICATION_PASSWORD
          value: replicatorpass
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 2Gi
EOF

# StatefulSet 배포 대기
kubectl wait --for=condition=Ready pod -l app=postgres-cluster --timeout=300s