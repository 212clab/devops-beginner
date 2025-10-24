#!/bin/bash
# Week 4 Day 5 Hands-on 1: Grafana 및 대시보드 통합 설치 (경량화 버전)
set -e

echo "=== Grafana 및 대시보드 통합 설치 시작 ==="
echo "1/3 모든 설정을 먼저 생성합니다..."

# --- 모든 ConfigMap과 Service를 한 번에 생성 ---
kubectl apply -f - <<'EOF'
# 1. Prometheus 데이터 소스 설정
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  prometheus.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      uid: prometheus # 💡 대시보드에서 이 이름으로 데이터 소스를 찾음
      url: http://prometheus.monitoring.svc.cluster.local:9090 # 클러스터 내부 주소 사용
      access: proxy
      isDefault: true
---
# 2. 대시보드 프로바이더 설정 (어디서 대시보드를 찾을지 알려줌)
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-provider
  namespace: monitoring
data:
  default-provider.yaml: |
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default
---
# 3. 모든 대시보드 내용이 담긴 ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
  cluster-overview.json: |
    {
      "title": "Kubernetes Cluster Overview",
      "uid": "cluster-overview",
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0,
      "refresh": "10s",
      "panels": [
        {
          "id": 1,
          "title": "Total CPU Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
          "targets": [{
            "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\"}[5m]))",
            "legendFormat": "CPU Usage",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 2,
          "title": "Total Memory Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
          "targets": [{
            "expr": "sum(container_memory_usage_bytes{container!=\"\",container!=\"POD\"})",
            "legendFormat": "Memory Usage",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 3,
          "title": "Pods by Namespace",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
          "targets": [{
            "expr": "count(kube_pod_info) by (namespace)",
            "legendFormat": "{{namespace}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 4,
          "title": "Node Status",
          "type": "stat",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
          "targets": [{
            "expr": "sum(kube_node_status_condition{condition=\"Ready\",status=\"true\"})",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        }
      ]
    }
  namespace-detail.json: |
    {
      "title": "Namespace Detail",
      "uid": "namespace-detail",
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0,
      "refresh": "10s",
      "templating": {
        "list": [{
          "name": "namespace",
          "type": "query",
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "query": "label_values(kube_pod_info, namespace)",
          "refresh": 1,
          "includeAll": false,
          "multi": false
        }]
      },
      "panels": [
        {
          "id": 1,
          "title": "CPU Usage by Pod",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
          "targets": [{
            "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"$namespace\",container!=\"\",container!=\"POD\"}[5m])) by (pod)",
            "legendFormat": "{{pod}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 2,
          "title": "Memory Usage by Pod",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
          "targets": [{
            "expr": "sum(container_memory_usage_bytes{namespace=\"$namespace\",container!=\"\",container!=\"POD\"}) by (pod)",
            "legendFormat": "{{pod}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        }
      ]
    }
  pod-detail.json: |
    {
      "title": "Pod Detail",
      "uid": "pod-detail",
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0,
      "refresh": "10s",
      "templating": {
        "list": [
          {
            "name": "namespace",
            "type": "query",
            "datasource": {"type": "prometheus", "uid": "prometheus"},
            "query": "label_values(kube_pod_info, namespace)",
            "refresh": 1,
            "includeAll": false,
            "multi": false
          },
          {
            "name": "deployment",
            "type": "query",
            "datasource": {"type": "prometheus", "uid": "prometheus"},
            "query": "label_values(kube_deployment_labels{namespace=\"$namespace\"}, deployment)",
            "refresh": 1,
            "includeAll": true,
            "multi": false
          },
          {
            "name": "pod",
            "type": "query",
            "datasource": {"type": "prometheus", "uid": "prometheus"},
            "query": "label_values(kube_pod_info{namespace=\"$namespace\"}, pod)",
            "refresh": 1,
            "includeAll": false,
            "multi": false
          }
        ]
      },
      "panels": [
        {
          "id": 1,
          "title": "Pod CPU Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
          "targets": [{
            "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"$namespace\",pod=\"$pod\",container!=\"\",container!=\"POD\"}[5m])) by (container)",
            "legendFormat": "{{container}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 2,
          "title": "Pod Memory Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
          "targets": [{
            "expr": "sum(container_memory_usage_bytes{namespace=\"$namespace\",pod=\"$pod\",container!=\"\",container!=\"POD\"}) by (container)",
            "legendFormat": "{{container}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 3,
          "title": "Network I/O",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
          "targets": [
            {
              "expr": "sum(rate(container_network_receive_bytes_total{namespace=\"$namespace\",pod=\"$pod\"}[5m]))",
              "legendFormat": "Receive",
              "refId": "A"
            },
            {
              "expr": "sum(rate(container_network_transmit_bytes_total{namespace=\"$namespace\",pod=\"$pod\"}[5m]))",
              "legendFormat": "Transmit",
              "refId": "B"
            }
          ],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        },
        {
          "id": 4,
          "title": "Pod Restarts",
          "type": "stat",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
          "targets": [{
            "expr": "sum(kube_pod_container_status_restarts_total{namespace=\"$namespace\",pod=\"$pod\"})",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"}
        }
      ]
    }
  finops-detail.json: |
    {
      "title": "FinOps Cost Analysis",
      "uid": "finops-detail",
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0,
      "refresh": "30s",
      "templating": {
        "list": [{
          "name": "namespace",
          "type": "query",
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "query": "label_values(kube_pod_info, namespace)",
          "refresh": 1,
          "includeAll": true,
          "multi": true
        }]
      },
      "panels": [
        {
          "id": 1,
          "title": "💰 Total Resource Requests (Cost Baseline)",
          "type": "stat",
          "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
          "targets": [{
            "expr": "sum(kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"})",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "fieldConfig": {
            "defaults": {
              "unit": "short",
              "decimals": 2,
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "green"},
                  {"value": 10, "color": "yellow"},
                  {"value": 20, "color": "red"}
                ]
              }
            },
            "overrides": []
          },
          "options": {
            "colorMode": "background",
            "graphMode": "area",
            "justifyMode": "auto",
            "orientation": "auto",
            "reduceOptions": {
              "values": false,
              "calcs": ["lastNotNull"],
              "fields": ""
            },
            "text": {},
            "textMode": "auto"
          }
        },
        {
          "id": 2,
          "title": "📊 Actual CPU Usage",
          "type": "stat",
          "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
          "targets": [{
            "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m]))",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "fieldConfig": {
            "defaults": {
              "unit": "short",
              "decimals": 2,
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "green"},
                  {"value": 5, "color": "yellow"},
                  {"value": 10, "color": "red"}
                ]
              }
            }
          },
          "options": {
            "colorMode": "background",
            "graphMode": "area",
            "justifyMode": "auto",
            "orientation": "auto",
            "reduceOptions": {
              "values": false,
              "calcs": ["lastNotNull"],
              "fields": ""
            }
          }
        },
        {
          "id": 3,
          "title": "⚡ Overall CPU Efficiency",
          "type": "gauge",
          "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0},
          "targets": [{
            "expr": "100 * sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m])) / sum(kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"})",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "fieldConfig": {
            "defaults": {
              "unit": "percent",
              "min": 0,
              "max": 100,
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "red"},
                  {"value": 40, "color": "yellow"},
                  {"value": 70, "color": "green"}
                ]
              }
            }
          },
          "options": {
            "showThresholdLabels": true,
            "showThresholdMarkers": true
          }
        },
        {
          "id": 4,
          "title": "💸 Wasted Resources (Over-provisioned)",
          "type": "stat",
          "gridPos": {"h": 4, "w": 6, "x": 18, "y": 0},
          "targets": [{
            "expr": "sum(kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"}) - sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m]))",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "fieldConfig": {
            "defaults": {
              "unit": "short",
              "decimals": 2,
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "green"},
                  {"value": 5, "color": "yellow"},
                  {"value": 10, "color": "red"}
                ]
              }
            }
          },
          "options": {
            "colorMode": "background",
            "graphMode": "none"
          }
        },
        {
          "id": 5,
          "title": "📈 CPU Requests vs Usage by Namespace",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
          "targets": [
            {
              "expr": "sum(kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"}) by (namespace)",
              "legendFormat": "Requested - {{namespace}}",
              "refId": "A"
            },
            {
              "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m])) by (namespace)",
              "legendFormat": "Used - {{namespace}}",
              "refId": "B"
            }
          ],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "yaxes": [
            {"format": "short", "label": "CPU Cores"},
            {"format": "short"}
          ]
        },
        {
          "id": 6,
          "title": "💾 Memory Requests vs Usage by Namespace",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 4},
          "targets": [
            {
              "expr": "sum(kube_pod_container_resource_requests{resource=\"memory\",namespace=~\"$namespace\"}) by (namespace)",
              "legendFormat": "Requested - {{namespace}}",
              "refId": "A"
            },
            {
              "expr": "sum(container_memory_usage_bytes{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}) by (namespace)",
              "legendFormat": "Used - {{namespace}}",
              "refId": "B"
            }
          ],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "yaxes": [
            {"format": "bytes", "label": "Memory"},
            {"format": "short"}
          ]
        },
        {
          "id": 7,
          "title": "🎯 CPU Efficiency by Namespace",
          "type": "bargauge",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 12},
          "targets": [{
            "expr": "100 * sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m])) by (namespace) / sum(kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"}) by (namespace)",
            "legendFormat": "{{namespace}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "fieldConfig": {
            "defaults": {
              "unit": "percent",
              "min": 0,
              "max": 100,
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "red"},
                  {"value": 40, "color": "yellow"},
                  {"value": 70, "color": "green"}
                ]
              }
            }
          },
          "options": {
            "orientation": "horizontal",
            "displayMode": "gradient",
            "showUnfilled": true
          }
        },
        {
          "id": 8,
          "title": "💾 Memory Efficiency by Namespace",
          "type": "bargauge",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 12},
          "targets": [{
            "expr": "100 * sum(container_memory_usage_bytes{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}) by (namespace) / sum(kube_pod_container_resource_requests{resource=\"memory\",namespace=~\"$namespace\"}) by (namespace)",
            "legendFormat": "{{namespace}}",
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "fieldConfig": {
            "defaults": {
              "unit": "percent",
              "min": 0,
              "max": 100,
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"value": 0, "color": "red"},
                  {"value": 50, "color": "yellow"},
                  {"value": 80, "color": "green"}
                ]
              }
            }
          },
          "options": {
            "orientation": "horizontal",
            "displayMode": "gradient",
            "showUnfilled": true
          }
        },
        {
          "id": 9,
          "title": "🔍 Top 10 Over-Provisioned Pods (CPU)",
          "type": "table",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 20},
          "targets": [{
            "expr": "topk(10, (kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"} - on(pod,namespace,container) rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m])))",
            "format": "table",
            "instant": true,
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "transformations": [
            {
              "id": "organize",
              "options": {
                "excludeByName": {"Time": true, "__name__": true, "job": true, "instance": true},
                "indexByName": {},
                "renameByName": {
                  "namespace": "Namespace",
                  "pod": "Pod",
                  "container": "Container",
                  "Value": "Wasted CPU"
                }
              }
            }
          ]
        },
        {
          "id": 10,
          "title": "🔍 Top 10 Over-Provisioned Pods (Memory)",
          "type": "table",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 20},
          "targets": [{
            "expr": "topk(10, (kube_pod_container_resource_requests{resource=\"memory\",namespace=~\"$namespace\"} - on(pod,namespace,container) container_memory_usage_bytes{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}))",
            "format": "table",
            "instant": true,
            "refId": "A"
          }],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "transformations": [
            {
              "id": "organize",
              "options": {
                "excludeByName": {"Time": true, "__name__": true, "job": true, "instance": true},
                "indexByName": {},
                "renameByName": {
                  "namespace": "Namespace",
                  "pod": "Pod",
                  "container": "Container",
                  "Value": "Wasted Memory (bytes)"
                }
              }
            }
          ]
        },
        {
          "id": 11,
          "title": "📊 Resource Utilization Trend (24h)",
          "type": "graph",
          "gridPos": {"h": 8, "w": 24, "x": 0, "y": 28},
          "targets": [
            {
              "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\",container!=\"POD\",namespace=~\"$namespace\"}[5m]))",
              "legendFormat": "CPU Usage",
              "refId": "A"
            },
            {
              "expr": "sum(kube_pod_container_resource_requests{resource=\"cpu\",namespace=~\"$namespace\"})",
              "legendFormat": "CPU Requests",
              "refId": "B"
            }
          ],
          "datasource": {"type": "prometheus", "uid": "prometheus"},
          "yaxes": [
            {"format": "short", "label": "CPU Cores"},
            {"format": "short"}
          ]
        },
        {
          "id": 12,
          "title": "💡 Cost Optimization Recommendations",
          "type": "text",
          "gridPos": {"h": 6, "w": 24, "x": 0, "y": 36},
          "options": {
            "mode": "markdown",
            "content": "## 💰 FinOps 최적화 권장사항\n\n### 🎯 즉시 적용 가능한 개선 사항\n\n1. **Over-Provisioned 리소스 조정**\n   - CPU 효율성 40% 미만 네임스페이스: 리소스 요청량 50% 감소 검토\n   - 메모리 효율성 50% 미만: 메모리 요청량 30% 감소 검토\n\n2. **Idle 리소스 제거**\n   - 사용률 10% 미만 Pod: 스케일 다운 또는 제거 고려\n   - 장기간 미사용 네임스페이스: 정리 검토\n\n3. **리소스 Limits 설정**\n   - Limits 미설정 Pod: OOM 위험 및 노드 불안정성\n   - Requests = Limits 설정으로 QoS Guaranteed 확보\n\n4. **HPA/VPA 적용**\n   - 트래픽 변동이 큰 서비스: HPA 적용으로 자동 스케일링\n   - 리소스 사용 패턴이 일정한 서비스: VPA로 최적 크기 자동 조정\n\n### 📈 장기 개선 전략\n\n- **Spot/Preemptible 인스턴스**: 비용 70% 절감 가능\n- **Reserved Instances**: 장기 워크로드 30-50% 비용 절감\n- **리소스 태깅**: 부서/프로젝트별 비용 추적 및 차지백\n- **정기 리뷰**: 월간 FinOps 리뷰로 지속적 최적화"
          }
        }
      ]
    }
---
# 4. Grafana Service (외부 접속용)
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30091
EOF

echo "2/3 Grafana를 배포합니다..."

# --- 모든 설정이 준비된 상태에서 Grafana Deployment 생성 ---
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:10.0.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin
        - name: GF_SECURITY_ADMIN_USER
          value: admin
        volumeMounts:
        - name: grafana-datasources # 데이터 소스 연결
          mountPath: /etc/grafana/provisioning/datasources
        - name: grafana-dashboard-provider # 프로바이더 설정 연결
          mountPath: /etc/grafana/provisioning/dashboards
        - name: grafana-dashboards # 대시보드 파일 연결
          mountPath: /var/lib/grafana/dashboards/default
      volumes:
      - name: grafana-datasources
        configMap: { name: grafana-datasources }
      - name: grafana-dashboard-provider
        configMap: { name: grafana-dashboard-provider }
      - name: grafana-dashboards
        configMap: { name: grafana-dashboards }
EOF

echo "3/3 Grafana가 준비될 때까지 대기합니다..."
kubectl wait --for=condition=available deployment/grafana -n monitoring --timeout=120s

echo ""
echo "=== Grafana 및 대시보드 설치 완료 ==="
echo "모든 설정이 적용된 Grafana가 성공적으로 시작되었습니다."
echo "Grafana 접속: http://localhost:30091 (admin/admin)"