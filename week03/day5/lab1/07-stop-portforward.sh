#!/bin/bash

# Week 3 Day 5 Lab 1: 포트포워딩 중지
# 사용법: ./07-stop-portforward.sh

set -e

echo "=== 포트포워딩 중지 ==="
echo ""

# PID 파일 디렉토리
PID_DIR="/tmp/day5-lab-portforward"

if [ ! -d "$PID_DIR" ]; then
    echo "ℹ️  실행 중인 포트포워딩이 없습니다."
    exit 0
fi

# Grafana 포트포워딩 종료
if [ -f "$PID_DIR/grafana.pid" ]; then
    PID=$(cat "$PID_DIR/grafana.pid")
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Grafana 포트포워딩 중지"
    fi
    rm -f "$PID_DIR/grafana.pid"
fi

# Prometheus 포트포워딩 종료
if [ -f "$PID_DIR/prometheus.pid" ]; then
    PID=$(cat "$PID_DIR/prometheus.pid")
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Prometheus 포트포워딩 중지"
    fi
    rm -f "$PID_DIR/prometheus.pid"
fi

# ArgoCD 포트포워딩 종료
if [ -f "$PID_DIR/argocd.pid" ]; then
    PID=$(cat "$PID_DIR/argocd.pid")
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ ArgoCD 포트포워딩 중지"
    fi
    rm -f "$PID_DIR/argocd.pid"
fi

# Web App 포트포워딩 종료
if [ -f "$PID_DIR/webapp.pid" ]; then
    PID=$(cat "$PID_DIR/webapp.pid")
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Web App 포트포워딩 중지"
    fi
    rm -f "$PID_DIR/webapp.pid"
fi

# PID 디렉토리 삭제
rmdir "$PID_DIR" 2>/dev/null || true

echo ""
echo "=== 포트포워딩 중지 완료 ==="
