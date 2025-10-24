#!/bin/bash
set -e
echo "=== 샘플 애플리케이션 배포 시작 ==="
echo "1/4 네임스페이스 생성 중..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace production team=frontend cost-center=CC-1001 --overwrite
kubectl label namespace staging team=qa cost-center=CC-1002 --overwrite
kubectl label namespace development team=dev cost-center=CC-1003 --overwrite

echo "2/4 Production 애플리케이션 배포 중..."
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
YAML

echo "3/4 Staging 애플리케이션 배포 중..."
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx:alpine
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 300m
            memory: 256Mi
YAML

echo "4/4 Development 애플리케이션 배포 중..."
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-service
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dev
  template:
    metadata:
      labels:
        app: dev
    spec:
      containers:
      - name: dev
        image: nginx:alpine
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
YAML

echo ""
echo "배포 완료 대기 중..."
kubectl wait --for=condition=ready pod -l app=web -n production --timeout=120s
kubectl wait --for=condition=ready pod -l app=api -n staging --timeout=120s
kubectl wait --for=condition=ready pod -l app=dev -n development --timeout=120s

echo ""
echo "=== 샘플 애플리케이션 배포 완료 ==="
echo ""
echo "다음 단계: ./step5-setup-hpa.sh"
