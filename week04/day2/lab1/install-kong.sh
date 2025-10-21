#!/bin/bash

# Lab 1: Kong API Gateway - Kong 설치 (DB 모드)

echo "=== Kong API Gateway 설치 시작 ==="
echo ""

# 1. Kong 네임스페이스 생성
echo "1. Kong 네임스페이스 생성 중..."
kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
echo "   ✅ 네임스페이스 생성 완료"

# 2. PostgreSQL 배포
echo ""
echo "2. PostgreSQL 배포 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: kong
spec:
  ports:
  - port: 5432
  selector:
    app: postgres
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: kong
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
        image: postgres:13
        env:
        - name: POSTGRES_USER
          value: kong
        - name: POSTGRES_PASSWORD
          value: kong
        - name: POSTGRES_DB
          value: kong
        ports:
        - containerPort: 5432
EOF
echo "   ✅ PostgreSQL 배포 완료"

# 3. PostgreSQL 준비 대기
echo ""
echo "3. PostgreSQL 준비 대기 중..."
kubectl wait --for=condition=ready pod -l app=postgres -n kong --timeout=120s

# 4. Kong 마이그레이션 실행
# Kong은 설정 정보(API, 라우트, 플러그인 등)를 PostgreSQL(또는 Cassandra) 데이터베이스에 저장
# :: 대규모 및 동적(Dynamic) API 관리를 위한 중앙 집중식 저장소 역할
echo ""
echo "4. Kong 데이터베이스 마이그레이션 중..."
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job # 한번만 사용하고 재실행하지 않음
metadata:
  name: kong-migration
  namespace: kong
spec:
  template:
    spec:
      containers:
      - name: kong-migration
        image: kong:3.4
        env:
        - name: KONG_DATABASE
          value: postgres
        - name: KONG_PG_HOST
          value: postgres
        - name: KONG_PG_USER
          value: kong
        - name: KONG_PG_PASSWORD
          value: kong
        command: ["kong", "migrations", "bootstrap"]
      restartPolicy: OnFailure
EOF

kubectl wait --for=condition=complete job/kong-migration -n kong --timeout=120s
echo "   ✅ 마이그레이션 완료"

# 5. Kong Gateway 배포
echo ""
echo "5. Kong Gateway 배포 중..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kong-proxy
  namespace: kong
spec:
  type: NodePort
  ports:
  - name: proxy
    port: 80
    targetPort: 8000
    nodePort: 30080
  - name: proxy-ssl
    port: 443
    targetPort: 8443
  selector:
    app: kong
---
apiVersion: v1
kind: Service
metadata:
  name: kong-admin
  namespace: kong
spec:
  type: NodePort
  ports:
  - name: admin
    port: 8001
    targetPort: 8001
    nodePort: 30081
  selector:
    app: kong
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kong
  namespace: kong
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kong
  template:
    metadata:
      labels:
        app: kong
    spec:
      containers:
      - name: kong
        image: kong:3.4
        env:
        - name: KONG_DATABASE
          value: postgres
        - name: KONG_PG_HOST
          value: postgres
        - name: KONG_PG_USER
          value: kong
        - name: KONG_PG_PASSWORD
          value: kong
        - name: KONG_PROXY_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_ADMIN_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_PROXY_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_LISTEN
          value: "0.0.0.0:8001"
        ports:
        - containerPort: 8000
          name: proxy
        - containerPort: 8443
          name: proxy-ssl
        - containerPort: 8001
          name: admin
        livenessProbe:
          httpGet:
            path: /status
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /status
            port: 8001
          initialDelaySeconds: 10
          periodSeconds: 5
EOF

echo "   ✅ Kong 배포 완료"

# 6. Kong Pod 준비 대기
echo ""
echo "6. Kong Pod 준비 대기 중..."
kubectl wait --for=condition=ready pod -l app=kong -n kong --timeout=120s

# 7. Kong 상태 확인
echo ""
echo "7. Kong 상태 확인 중..."
kubectl get pods -n kong
echo ""
kubectl get svc -n kong

# 8. Kong Admin API 테스트
echo ""
echo "8. Kong Admin API 테스트 중..."
sleep 5
curl -s http://localhost:8001 | head -n 5

echo ""
echo "=== Kong 설치 완료 ==="
echo ""
echo "📍 접속 정보:"
echo "   - Kong Proxy: http://localhost:8000"
echo "   - Kong Admin API: http://localhost:8001"
echo ""
echo "💡 Kong은 PostgreSQL DB 모드로 실행 중입니다."
echo "   Admin API로 동적 설정이 가능합니다."
echo ""
echo "다음 단계: ./configure-kong.sh"
