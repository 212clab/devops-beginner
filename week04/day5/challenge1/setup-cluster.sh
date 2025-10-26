#!/bin/bash

set -e

echo "=========================================="
echo "🚀 CloudMart Challenge - 클러스터 셋업"
echo "=========================================="

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 기존 클러스터 정리
echo -e "\n${YELLOW}[1/7] 기존 클러스터 정리...${NC}"
kind delete cluster --name lab-cluster 2>/dev/null || true
sleep 2

# 2. Kind 노드 이미지 다운로드 (미리 받기)
echo -e "\n${GREEN}[2/7] Kind 노드 이미지 다운로드...${NC}"
echo -e "${YELLOW}이미지 크기가 크므로 시간이 걸릴 수 있습니다...${NC}"
KIND_IMAGE="kindest/node:v1.31.0"  # 안정적인 버전으로 변경
docker pull $KIND_IMAGE

# 3. Kind 클러스터 생성
echo -e "\n${GREEN}[3/7] Kind 클러스터 생성...${NC}"
cat <<EOF | kind create cluster --name lab-cluster --image $KIND_IMAGE --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30081
    hostPort: 30081
    protocol: TCP
  - containerPort: 30082
    hostPort: 30082
    protocol: TCP
  - containerPort: 30090
    hostPort: 30090
    protocol: TCP  # Kubecost
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 80
    hostPort: 80
    protocol: TCP
- role: worker
- role: worker
EOF

echo -e "${GREEN}✓ 클러스터 생성 완료${NC}"

# 4. Metrics Server 설치
echo -e "\n${GREEN}[4/7] Metrics Server 설치...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Metrics Server 패치 (Kind용 - TLS 비활성화)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

echo -e "${GREEN}✓ Metrics Server 설치 완료${NC}"

# 5. Namespace 생성
echo -e "\n${GREEN}[5/7] Namespace 생성...${NC}"
kubectl create namespace monitoring
kubectl create namespace kubecost
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace development


# 6. Prometheus 설치 (경량 버전)
echo -e "\n${GREEN}[6/7] Prometheus 설치...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 30s
      evaluation_interval: 30s
    scrape_configs:
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.45.0
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--storage.tsdb.retention.time=2h'
        ports:
        - containerPort: 9090
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 200m
            memory: 512Mi
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  type: ClusterIP
  ports:
  - port: 9090
    targetPort: 9090
  selector:
    app: prometheus
EOF

echo -e "${GREEN}✓ Prometheus 설치 완료${NC}"

# 7. Kubecost 설치 (경량화 - 버전 고정)
echo -e "\n${GREEN}[7/7] Kubecost 설치 (v1.106.7, Grafana 제외)...${NC}"

# Helm 설치 확인
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}Helm 설치 중...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Kubecost Helm repo 추가
helm repo add kubecost https://kubecost.github.io/cost-analyzer/ 2>/dev/null || true
helm repo update

# Kubecost 설치 (Grafana 완전 제거, 버전 고정)
cat <<EOF > /tmp/kubecost-values.yaml
global:
  prometheus:
    enabled: false
    fqdn: http://prometheus.monitoring.svc:9090

# Grafana 완전 비활성화
grafana:
  enabled: false

# 리소스 제한
kubecostModel:
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 1Gi

kubecostFrontend:
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 512Mi

# 불필요한 컴포넌트 비활성화
networkCosts:
  enabled: false

# NodePort 서비스
service:
  type: NodePort
  port: 9090
  targetPort: 9090
  nodePort: 30090
EOF

# 버전 1.106.7로 설치
helm upgrade --install kubecost kubecost/cost-analyzer \
  --namespace kubecost \
  --create-namespace \
  --values /tmp/kubecost-values.yaml \
  --version 1.106.7 \
  --wait \
  --timeout 5m

echo -e "${GREEN}✓ Kubecost v1.106.7 설치 완료${NC}"

# 8. 설치 완료 대기
echo -e "\n${YELLOW}리소스 초기화 대기 중...${NC}"
sleep 20

# Metrics Server 준비 대기
echo -e "${YELLOW}Metrics Server 준비 대기...${NC}"
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

# Prometheus 준비 대기
echo -e "${YELLOW}Prometheus 준비 대기...${NC}"
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s

# Kubecost 준비 대기
echo -e "${YELLOW}Kubecost 준비 대기...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cost-analyzer -n kubecost --timeout=180s

# 8. 설치 결과 확인
echo -e "\n=========================================="
echo -e "${GREEN}✅ 클러스터 셋업 완료!${NC}"
echo -e "=========================================="

echo -e "\n📊 ${GREEN}설치된 컴포넌트:${NC}"
echo -e "  ✓ Kind 클러스터 (lab-cluster)"
echo -e "  ✓ Metrics Server"
echo -e "  ✓ Prometheus (경량 버전)"
echo -e "  ✓ Kubecost v1.106.7 (Grafana 제외)"

echo -e "\n🌐 ${GREEN}접속 정보:${NC}"
echo -e "  Kubecost UI: ${YELLOW}http://localhost:30090${NC}"

echo -e "\n📝 ${GREEN}Namespace:${NC}"
echo -e "  • lab-cluster (클러스터 관리)"
echo -e "  • monitoring (Prometheus)"
echo -e "  • kubecost (비용 분석)"
echo -e "  • production (프로덕션)"
echo -e "  • staging (스테이징)"
echo -e "  • development (개발)"

echo -e "\n🔍 ${GREEN}상태 확인:${NC}"
kubectl get nodes
echo ""
kubectl get pods -n monitoring
echo ""
kubectl get pods -n kubecost

echo -e "\n💡 ${YELLOW}다음 단계:${NC}"
echo -e "  1. Kubecost UI 접속: http://localhost:30090"
echo -e "  2. 문제 시나리오 배포: kubectl apply -f ./brokens/"
echo -e "  3. 비용 분석 시작!"

echo -e "\n=========================================="