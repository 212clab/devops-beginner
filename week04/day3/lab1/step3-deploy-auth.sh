#!/bin/bash

# Week 4 Day 3 Lab 1: 인증 서비스 배포
# 설명: JWT 발급 및 검증 서비스 배포

set -e

echo "=== 인증 서비스 배포 시작 ==="

# 1. Auth Service 배포
echo "1/3 Auth Service 배포 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: auth-config
  namespace: secure-app
data:
  JWT_SECRET: "my-super-secret-key-change-in-production"
  JWT_ALGORITHM: "HS256"
  JWT_EXPIRATION: "3600"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
        version: v1
    spec:
      containers:
      - name: auth
        image: python:3.9-slim
        command: ["/bin/bash"]
        args:
        - -c
        - |
          pip install flask pyjwt
          mkdir -p /app
          cat > /app/auth.py <<'PYEOF'
          from flask import Flask, request, jsonify
          import jwt
          import datetime
          import os

          app = Flask(__name__)
          SECRET = os.getenv('JWT_SECRET', 'secret')
          ALGORITHM = os.getenv('JWT_ALGORITHM', 'HS256')
          EXPIRATION = int(os.getenv('JWT_EXPIRATION', '3600'))

          USERS = {
              'admin': 'admin123',
              'user': 'user123'
          }

          @app.route('/health')
          def health():
              return jsonify({'status': 'healthy'}), 200

          @app.route('/login', methods=['POST'])
          def login():
              data = request.get_json()
              username = data.get('username')
              password = data.get('password')
              
              if username in USERS and USERS[username] == password:
                  payload = {
                      'sub': username,
                      'iat': datetime.datetime.utcnow(),
                      'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=EXPIRATION)
                  }
                  token = jwt.encode(payload, SECRET, algorithm=ALGORITHM)
                  return jsonify({'token': token}), 200
              
              return jsonify({'error': 'Invalid credentials'}), 401

          @app.route('/verify', methods=['POST'])
          def verify():
              token = request.headers.get('Authorization', '').replace('Bearer ', '')
              try:
                  payload = jwt.decode(token, SECRET, algorithms=[ALGORITHM])
                  return jsonify({'valid': True, 'user': payload['sub']}), 200
              except:
                  return jsonify({'valid': False}), 401

          if __name__ == '__main__':
              app.run(host='0.0.0.0', port=8080)
          PYEOF
          python /app/auth.py
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: auth-config
---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: secure-app
spec:
  selector:
    app: auth-service
  ports:
  - port: 8080
    targetPort: 8080
    name: http
EOF

# 2. 배포 대기
echo "2/3 배포 완료 대기 중..."
kubectl wait --for=condition=ready pod -l app=auth-service -n secure-app --timeout=120s

# 3. 상태 확인
echo "3/3 상태 확인 중..."
kubectl get pods -n secure-app -l app=auth-service
kubectl get svc -n secure-app auth-service

echo ""
echo "=== 인증 서비스 배포 완료 ==="
echo ""
echo "배포된 서비스:"
echo "- Auth Service: JWT 발급 및 검증"
echo ""
echo "API 엔드포인트:"
echo "- POST /login: JWT 토큰 발급"
echo "- POST /verify: JWT 토큰 검증"
echo "- GET /health: 헬스체크"
