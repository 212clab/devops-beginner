#!/bin/bash

# Week 4 Day 3 Lab 1: 애플리케이션 서비스 배포
# 설명: Frontend, Backend, Database 서비스 배포

set -e

echo "=== 애플리케이션 서비스 배포 시작 ==="

# 1. Database 배포
echo "1/4 Database 배포 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: database
  namespace: secure-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        version: v1
    spec:
      serviceAccountName: database
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_PASSWORD
          value: "postgres"
        - name: POSTGRES_DB
          value: "appdb"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: secure-app
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
EOF

# 2. Backend 배포
echo "2/4 Backend 배포 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend
  namespace: secure-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: secure-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        version: v1
    spec:
      serviceAccountName: backend
      containers:
      - name: backend
        image: node:18-alpine
        command: ["/bin/sh"]
        args:
        - -c
        - |
          mkdir -p /app
          cat > /app/server.js <<'JSEOF'
          const http = require('http');
          const server = http.createServer((req, res) => {
            if (req.url === '/health') {
              res.writeHead(200);
              res.end('OK');
            } else if (req.url === '/api/data') {
              res.writeHead(200, {'Content-Type': 'application/json'});
              res.end(JSON.stringify({
                message: 'Secure data from backend',
                timestamp: new Date().toISOString()
              }));
            } else {
              res.writeHead(404);
              res.end('Not Found');
            }
          });
          server.listen(8080, () => console.log('Backend running on 8080'));
          JSEOF
          node /app/server.js
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: secure-app
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
    name: http
EOF

# 3. Frontend 배포
echo "3/4 Frontend 배포 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend
  namespace: secure-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: secure-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        version: v1
    spec:
      serviceAccountName: frontend
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config
        configMap:
          name: frontend-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: secure-app
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Secure App</title></head>
    <body>
      <h1>Secure Application</h1>
      <p>Protected by mTLS + JWT</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: secure-app
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    name: http
EOF

# 4. 배포 대기
echo "4/4 배포 완료 대기 중..."
kubectl wait --for=condition=ready pod -l app=database -n secure-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=backend -n secure-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=frontend -n secure-app --timeout=120s

kubectl get pods -n secure-app

echo ""
echo "=== 애플리케이션 서비스 배포 완료 ==="
echo ""
echo "배포된 서비스:"
echo "- Database: PostgreSQL (1 replica)"
echo "- Backend: Node.js API (2 replicas)"
echo "- Frontend: Nginx (2 replicas)"
