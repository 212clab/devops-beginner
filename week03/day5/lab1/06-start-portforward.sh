#!/bin/bash

# Week 3 Day 5 Lab 1: 포트포워딩 시작
# 사용법: ./06-start-portforward.sh

set -e

echo "=== 포트포워딩 시작 ==="
echo ""

# PID 파일 디렉토리
PID_DIR="/tmp/day5-lab-portforward"
mkdir -p "$PID_DIR"

# 기존 포트포워딩 종료
if [ -f "$PID_DIR/grafana.pid" ]; then
    echo "기존 Grafana 포트포워딩 종료 중..."
    kill $(cat "$PID_DIR/grafana.pid") 2>/dev/null || true
fi

if [ -f "$PID_DIR/prometheus.pid" ]; then
    echo "기존 Prometheus 포트포워딩 종료 중..."
    kill $(cat "$PID_DIR/prometheus.pid") 2>/dev/null || true
fi

if [ -f "$PID_DIR/argocd.pid" ]; then
    echo "기존 ArgoCD 포트포워딩 종료 중..."
    kill $(cat "$PID_DIR/argocd.pid") 2>/dev/null || true
fi

if [ -f "$PID_DIR/webapp.pid" ]; then
    echo "기존 Web App 포트포워딩 종료 중..."
    kill $(cat "$PID_DIR/webapp.pid") 2>/dev/null || true
fi

echo ""
echo "새로운 포트포워딩 시작 중..."
echo ""

# Grafana 포트포워딩 (백그라운드)
echo "1. Grafana 포트포워딩 시작..."
nohup kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 > /dev/null 2>&1 &
echo $! > "$PID_DIR/grafana.pid"
echo "✅ Grafana: http://localhost:3000 (admin/admin123)"

# Prometheus 포트포워딩 (백그라운드)
echo "2. Prometheus 포트포워딩 시작..."
nohup kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
echo $! > "$PID_DIR/prometheus.pid"
echo "✅ Prometheus: http://localhost:9090"

# ArgoCD 포트포워딩 (백그라운드)
echo "3. ArgoCD 포트포워딩 시작..."
nohup kubectl port-forward -n argocd svc/argocd-server 8080:443 > /dev/null 2>&1 &
echo $! > "$PID_DIR/argocd.pid"
echo "✅ ArgoCD: https://localhost:8080"

# Web App 포트포워딩 (백그라운드)
echo "4. Web App 포트포워딩 시작..."
nohup kubectl port-forward -n day5-lab svc/web-app 8081:80 > /dev/null 2>&1 &
echo $! > "$PID_DIR/webapp.pid"
echo "✅ Web App: http://localhost:8081"

echo ""
echo "=== 포트포워딩 시작 완료 ==="
echo ""
echo "📊 접속 정보:"
echo "   Grafana:    http://localhost:3000 (admin/admin123)"
echo "   Prometheus: http://localhost:9090"
echo "   ArgoCD:     https://localhost:8080"
echo "   Web App:    http://localhost:8081"
echo ""
echo "💡 포트포워딩 중지:"
echo "   ./07-stop-portforward.sh"
echo ""
echo "💡 상태 확인:"
echo "   ps aux | grep 'port-forward'"
