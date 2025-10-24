cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: cloudmart
  labels:
    project: cloudmart      # 프로젝트 이름
    team: platform          # 담당 팀
    cost-center: CC-2001    # 비용 센터 (Grafana FinOps에서 추적용)
EOF



# 먼저 nginx 설정 ConfigMap 생성
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-nginx-config
  namespace: cloudmart
data:
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    http {
        server {
            listen 8080;
            
            location /health {
                access_log off;
                return 200 "healthy\n";
                add_header Content-Type text/plain;
            }
            
            location /ready {
                access_log off;
                return 200 "ready\n";
                add_header Content-Type text/plain;
            }
            
            location /stub_status {
                stub_status;
                access_log off;
            }
            
            location / {
                return 200 "User Service v1.0 - CloudMart\n";
                add_header Content-Type text/plain;
            }
        }
    }
EOF

# User Service Deployment 생성
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: cloudmart
  labels:
    app: user-service
    tier: backend
spec:
  replicas: 2              # 기본 2개 Pod (고가용성)
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        tier: backend
        version: v1        # 버전 관리 (Day 4 GitOps 연계)
      annotations:
        prometheus.io/scrape: "true"    # 💡 Prometheus가 메트릭 수집
        prometheus.io/port: "9113"      # 💡 메트릭 포트
        prometheus.io/path: "/metrics"  # 💡 메트릭 경로
    spec:
      containers:
      - name: user-service
        image: nginx:alpine  # 💡 실제로는 user-service 이미지 사용
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SERVICE_NAME
          value: "user-service"
        - name: DB_HOST
          value: "postgres-service"  # PostgreSQL 연결
        resources:
          requests:
            cpu: 100m        # 최소 보장: CPU 0.1 코어
            memory: 128Mi    # 최소 보장: 메모리 128MB
          limits:
            cpu: 300m        # 최대 사용: CPU 0.3 코어
            memory: 256Mi    # 최대 사용: 메모리 256MB
        livenessProbe:       # 💡 살아있는지 확인 (죽으면 재시작)
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:      # 💡 준비됐는지 확인 (준비 안되면 트래픽 안 보냄)
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      # 💡 Nginx Prometheus Exporter (사이드카)
      - name: nginx-exporter
        image: nginx/nginx-prometheus-exporter:0.11.0
        args:
        - -nginx.scrape-uri=http://localhost:8080/stub_status
        ports:
        - containerPort: 9113
          name: metrics
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
      volumes:
      - name: nginx-config
        configMap:
          name: user-service-nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: cloudmart
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 9113
    targetPort: 9113
    name: metrics        # 💡 메트릭 포트 추가
  type: ClusterIP
EOF

# Product Service nginx 설정 ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-nginx-config
  namespace: cloudmart
data:
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    http {
        server {
            listen 8080;
            
            location /health {
                access_log off;
                return 200 "healthy\n";
                add_header Content-Type text/plain;
            }
            
            location /ready {
                access_log off;
                return 200 "ready\n";
                add_header Content-Type text/plain;
            }
            
            location /stub_status {
                stub_status;
                access_log off;
            }
            
            location / {
                return 200 "Product Service v1.0 - CloudMart\n";
                add_header Content-Type text/plain;
            }
        }
    }
EOF

# Product Service Deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: cloudmart
  labels:
    app: product-service
    tier: backend
spec:
  replicas: 3              # 💡 User보다 많음 (상품 조회가 더 많아서)
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
        tier: backend
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9113"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: product-service
        image: nginx:alpine
        ports:
        - containerPort: 8080
        env:
        - name: SERVICE_NAME
          value: "product-service"
        - name: REDIS_HOST
          value: "redis-service"  # 💡 Redis 캐시 사용 (빠른 조회)
        resources:
          requests:
            cpu: 150m        # 💡 User보다 많음 (트래픽이 더 많아서)
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      - name: nginx-exporter
        image: nginx/nginx-prometheus-exporter:0.11.0
        args:
        - -nginx.scrape-uri=http://localhost:8080/stub_status
        ports:
        - containerPort: 9113
          name: metrics
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
      volumes:
      - name: nginx-config
        configMap:
          name: product-service-nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: cloudmart
spec:
  selector:
    app: product-service
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 9113
    targetPort: 9113
    name: metrics
  type: ClusterIP
EOF


# Order Service nginx 설정 ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-nginx-config
  namespace: cloudmart
data:
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    http {
        server {
            listen 8080;
            
            location /health {
                access_log off;
                return 200 "healthy\n";
                add_header Content-Type text/plain;
            }
            
            location /ready {
                access_log off;
                return 200 "ready\n";
                add_header Content-Type text/plain;
            }
            
            location /stub_status {
                stub_status;
                access_log off;
            }
            
            location / {
                return 200 "Order Service v1.0 - CloudMart\n";
                add_header Content-Type text/plain;
            }
        }
    }
EOF

# Order Service Deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: cloudmart
  labels:
    app: order-service
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
        tier: backend
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9113"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: order-service
        image: nginx:alpine
        ports:
        - containerPort: 8080
        env:
        - name: SERVICE_NAME
          value: "order-service"
        - name: KAFKA_BROKERS
          value: "kafka-service:9092"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 300m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      - name: nginx-exporter
        image: nginx/nginx-prometheus-exporter:0.11.0
        args:
        - -nginx.scrape-uri=http://localhost:8080/stub_status
        ports:
        - containerPort: 9113
          name: metrics
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
      volumes:
      - name: nginx-config
        configMap:
          name: order-service-nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: cloudmart
spec:
  selector:
    app: order-service
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 9113
    targetPort: 9113
    name: metrics
  type: ClusterIP
EOF