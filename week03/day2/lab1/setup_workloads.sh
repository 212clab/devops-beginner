#!/bin/bash

# Week 3 Day 2 Lab 1: Basic Workload Management
# Purpose: Deploy Pod -> ReplicaSet -> Deployment hierarchy

echo "=== Kubernetes Workload Management Lab 1 ==="

# 1. Create namespace
kubectl create namespace workload-demo

# 2. Deploy standalone Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: standalone-pod
  namespace: workload-demo
  labels:
    app: web
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    ports:
    - containerPort: 80
EOF

# 3. Deploy ReplicaSet
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-replicaset
  namespace: workload-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: v1
  template:
    metadata:
      labels:
        app: web
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
EOF

# 4. Deploy Deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  namespace: workload-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF

echo "✅ Workloads deployed successfully"
echo ""
echo "Check status:"
echo "kubectl get pods -n workload-demo"
echo "kubectl get rs -n workload-demo"
echo "kubectl get deploy -n workload-demo"
