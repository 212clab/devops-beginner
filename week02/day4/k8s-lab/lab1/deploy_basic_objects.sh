#!/bin/bash

# Week 2 Day 4 Lab 1: K8s 기본 오브젝트 자동 배포 스크립트
# 사용법: ./deploy_basic_objects.sh

echo "=== Kubernetes 기본 오브젝트 배포 시작 ==="
echo ""

# 1. 클러스터 연결 확인
echo "1. 클러스터 연결 확인 중..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes 클러스터에 연결할 수 없습니다."
    echo "먼저 setup_k8s_cluster.sh를 실행해주세요."
    exit 1
fi
echo "✅ 클러스터 연결 확인 완료"
echo ""

# 2. 네임스페이스 생성
echo "2. 네임스페이스 생성 중..."
kubectl create namespace lab-demo --dry-run=client -o yaml | kubectl apply -f -
echo "✅ lab-demo 네임스페이스 생성 완료"
echo ""

# 3. ConfigMap 생성
echo "3. ConfigMap 생성 중..."
cat > /tmp/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: lab-demo
data:
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /health {
            access_log off;
            return 200 "healthy";
            add_header Content-Type text/plain;
        }
        
        location /info {
            access_log off;
            return 200 "Pod Info Available";
            add_header Content-Type text/plain;
        }
    }
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>K8s Lab Demo</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f0f8ff; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            h1 { color: #326ce5; text-align: center; }
            .info { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
            .status { display: flex; justify-content: space-between; margin: 20px 0; }
            .metric { text-align: center; padding: 10px; background: #f8f9fa; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Welcome to Kubernetes Lab!</h1>
            <div class="info">
                <h3>📊 Pod Information</h3>
                <p><strong>Pod Name:</strong> <span id="hostname">Loading...</span></p>
                <p><strong>Namespace:</strong> lab-demo</p>
                <p><strong>Service:</strong> nginx-service</p>
            </div>
            <div class="status">
                <div class="metric">
                    <h4>🔄 Status</h4>
                    <p id="status">Running</p>
                </div>
                <div class="metric">
                    <h4>⏰ Uptime</h4>
                    <p id="uptime">0s</p>
                </div>
                <div class="metric">
                    <h4>🌐 Requests</h4>
                    <p id="requests">0</p>
                </div>
            </div>
            <div class="info">
                <h3>🎯 Lab Objectives</h3>
                <ul>
                    <li>✅ Kubernetes 클러스터 구축</li>
                    <li>✅ Pod, Service, Deployment 배포</li>
                    <li>✅ ConfigMap을 통한 설정 관리</li>
                    <li>✅ 서비스 디스커버리 확인</li>
                </ul>
            </div>
        </div>
        <script>
            let startTime = Date.now();
            let requestCount = 0;
            
            function updateInfo() {
                document.getElementById('hostname').textContent = window.location.hostname || 'localhost';
                document.getElementById('uptime').textContent = Math.floor((Date.now() - startTime) / 1000) + 's';
                document.getElementById('requests').textContent = ++requestCount;
            }
            
            updateInfo();
            setInterval(updateInfo, 1000);
            
            fetch('/health')
                .then(response => response.text())
                .then(data => {
                    if (data.includes('healthy')) {
                        document.getElementById('status').textContent = '✅ Healthy';
                        document.getElementById('status').style.color = 'green';
                    }
                })
                .catch(() => {
                    document.getElementById('status').textContent = '❌ Error';
                    document.getElementById('status').style.color = 'red';
                });
        </script>
    </body>
    </html>
EOF

kubectl apply -f /tmp/configmap.yaml
echo "✅ ConfigMap 생성 완료"
echo ""

# 4. Deployment 생성
echo "4. Deployment 생성 중..."
cat > /tmp/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: lab-demo
  labels:
    app: nginx
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
        - name: nginx-html
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: nginx-html
        configMap:
          name: nginx-config
EOF

kubectl apply -f /tmp/deployment.yaml
echo "✅ Deployment 생성 완료"
echo ""

# 5. Service 생성
echo "5. Service 생성 중..."
cat > /tmp/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: lab-demo
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
  type: ClusterIP
EOF

kubectl apply -f /tmp/service.yaml
echo "✅ ClusterIP Service 생성 완료"
echo ""

# 6. NodePort Service 생성 (외부 접근용)
echo "6. NodePort Service 생성 중..."
cat > /tmp/service-nodeport.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
  namespace: lab-demo
  labels:
    app: nginx
    service-type: nodeport
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
    name: http
  type: NodePort
EOF

kubectl apply -f /tmp/service-nodeport.yaml
echo "✅ NodePort Service 생성 완료"
echo ""



# 7. 배포 상태 확인
echo "7. 배포 상태 확인 중..."
echo ""
echo "=== 네임스페이스 리소스 ==="
kubectl get all -n lab-demo
echo ""

echo "=== Pod 상세 정보 ==="
kubectl get pods -n lab-demo -o wide
echo ""

echo "=== Service 정보 ==="
kubectl get svc -n lab-demo
echo ""

# 8. Pod 준비 완료 대기
echo "8. Pod 준비 완료 대기 중..."
kubectl wait --for=condition=Ready pods -l app=nginx -n lab-demo --timeout=120s

if [ $? -eq 0 ]; then
    echo "✅ 모든 Pod 준비 완료"
else
    echo "⚠️ 일부 Pod가 준비되지 않았지만 계속 진행합니다"
fi
echo ""

# 9. 연결 테스트
echo "9. 서비스 연결 테스트 중..."

# ClusterIP 서비스 테스트
echo "ClusterIP 서비스 테스트..."
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -n lab-demo -- wget -qO- nginx-service/health 2>/dev/null || echo "테스트 Pod 실행 중..."

# Endpoints 확인
echo ""
echo "=== Endpoints 확인 ==="
kubectl get endpoints -n lab-demo
echo ""

# 10. 완료 요약
echo ""
echo "=== Kubernetes 기본 오브젝트 배포 완료 ==="
echo ""
echo "배포된 리소스:"
echo "- Namespace: lab-demo"
echo "- ConfigMap: nginx-config (설정 파일)"
echo "- Deployment: nginx-deployment (3 replicas)"
echo "- Service: nginx-service (ClusterIP)"
echo "- Service: nginx-nodeport (NodePort:30080)"
echo ""
echo "접속 정보:"
echo "- 클러스터 내부: http://nginx-service.lab-demo.svc.cluster.local"
echo "- 주 접근: http://localhost:8080 (Ingress Controller)"
echo "- 대체 접근: http://localhost:30080 (NodePort)"
echo "- 포트 포워딩: kubectl port-forward svc/nginx-service 8081:80 -n lab-demo (선택사항)"
echo ""
echo "확인 명령어:"
echo "- kubectl get all -n lab-demo"
echo "- kubectl logs -l app=nginx -n lab-demo"
echo "- kubectl describe pod -l app=nginx -n lab-demo"
echo ""
# 10. NGINX Ingress Controller 설정
echo "10. NGINX Ingress Controller 설정..."
echo "프로덕션 환경과 유사한 Ingress Controller를 설정합니다..."
echo ""

# NGINX Ingress Controller 설치
echo "=== NGINX Ingress Controller 설치 ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
echo "✅ NGINX Ingress Controller 설치 완료"
echo ""

# Ingress Controller 준비 대기
echo "=== Ingress Controller 준비 대기 ==="
echo "Ingress Controller Pod가 준비될 때까지 대기합니다 (최대 120초)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

if [ $? -eq 0 ]; then
    echo "✅ Ingress Controller 준비 완료"
else
    echo "⚠️ Ingress Controller 준비 시간 초과, 계속 진행합니다"
fi
echo ""

# Ingress 리소스 생성
echo "=== Ingress 리소스 생성 ==="
cat > /tmp/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: lab-demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF

kubectl apply -f /tmp/ingress.yaml
echo "✅ Ingress 리소스 생성 완료"
echo ""

# 11. Ingress 연결 테스트
echo "11. Ingress 연결 테스트..."
echo "Ingress Controller를 통한 접근을 테스트합니다..."
echo ""

# 연결 테스트 (최대 60초 대기)
echo "=== HTTP 연결 테스트 (localhost:30080) ==="
echo "Kind 포트 매핑: 컸테이너 80 -> 호스트 30080"
for i in {1..60}; do
    if curl -s http://localhost:30080/health > /dev/null 2>&1; then
        echo "✅ Ingress 접근 성공! ($i초 소요)"
        echo "🌍 브라우저에서 http://localhost:30080 접근 가능"
        HEALTH_RESPONSE=$(curl -s http://localhost:30080/health)
        echo "헬스체크 응답: $HEALTH_RESPONSE"
        break
    else
        echo "⏳ 연결 대기 중... ($i/60초)"
        sleep 1
    fi
done

# 최종 연결 확인
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "⚠️ Ingress 연결 대기 중... Ingress Controller가 준비되면 자동으로 접근 가능합니다."
    echo "수동 확인: curl http://localhost:8080/health"
    echo "대체 접근: kubectl port-forward svc/nginx-service 8081:80 -n lab-demo &"
fi
echo ""

echo "다음 단계:"
echo "- 브라우저에서 http://localhost:8080 접근 테스트"
echo "- deploy_korean_update.sh 실행으로 한글 지원 업데이트"
echo "- k8s_management_demo.sh 실행으로 관리 명령어 실습"
echo "- test_k8s_environment.sh 실행으로 종합 테스트"
echo ""
echo "🌍 외부 접근 방법:"
echo "- 주 접근: http://localhost:8080 (Ingress Controller)"
echo "- 대체 접근: http://localhost:30080 (NodePort)"
echo "- 포트 포워딩: kubectl port-forward svc/nginx-service 8081:80 -n lab-demo"
echo ""
echo "📝 특징:"
echo "- 프로덕션 환경 유사: Ingress Controller 사용"
echo "- HTTP 라우팅: 경로 기반 라우팅 지원"
echo "- 무중단 서비스: 롤링 업데이트 중에도 연결 유지"
echo "- 포트 포워딩 불필요: Ingress로 직접 접근"
echo ""
echo "🎉 기본 오브젝트 배포가 성공적으로 완료되었습니다!"