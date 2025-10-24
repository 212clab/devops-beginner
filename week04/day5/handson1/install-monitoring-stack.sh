#!/bin/bash

# Week 4 Day 5 Hands-on 1: 모니터링 스택 통합 설치
# 설명: 개별 스크립트를 순차적으로 실행

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 모니터링 스택 통합 설치 시작 ==="
echo ""

# 1. Metrics Server
echo "1/7 Metrics Server 설치..."
"$SCRIPT_DIR/install-metrics-server.sh"
echo ""

# 2. Prometheus
echo "2/7 Prometheus 설치..."
"$SCRIPT_DIR/install-prometheus.sh"
echo ""

# 3. kube-state-metrics
echo "3/7 kube-state-metrics 설치..."
"$SCRIPT_DIR/install-kube-state-metrics.sh"
echo ""

# 4. node-exporter
echo "4/7 node-exporter 설치..."
"$SCRIPT_DIR/install-node-exporter.sh"
echo ""

# 5. Grafana
echo "5/7 Grafana 설치..."
"$SCRIPT_DIR/install-grafana.sh"
echo ""

# 6. Grafana 대시보드
echo "6/7 Grafana 대시보드 설치..."
"$SCRIPT_DIR/install-grafana-dashboards.sh"
echo ""

# 7. Jaeger
echo "7/7 Jaeger 설치..."
"$SCRIPT_DIR/install-jaeger.sh"
echo ""

echo "=== 모니터링 스택 통합 설치 완료 ==="
echo ""
echo "설치된 컴포넌트:"
echo "- Metrics Server (kube-system)"
echo "- Prometheus (monitoring)"
echo "- kube-state-metrics (monitoring)"
echo "- node-exporter (monitoring)"
echo "- Grafana: http://localhost:30091 (admin/admin)"
echo "- Jaeger: http://localhost:16686 (포트포워딩 필요)"
echo ""
echo "Grafana 대시보드:"
echo "  * Cluster Overview - 클러스터 전체 현황"
echo "  * Namespace Detail - 네임스페이스별 리소스"
echo "  * Pod Detail - Pod 상세 (namespace/deployment/pod 선택)"
echo "  * FinOps Detail - 비용 효율성 분석"
echo ""
echo "확인 명령어:"
echo "  kubectl get pods -n monitoring"
echo "  kubectl get pods -n tracing"
echo "  kubectl top nodes"
echo "  kubectl top pods -A"
echo ""
echo "포트포워딩 시작:"
echo "  ./start-port-forwarding.sh"

