#!/bin/bash

# Week 3 Day 5 Lab 1: Prometheus Stack 설치
# 사용법: ./02-install-prometheus.sh

set -e

echo "=== Prometheus Stack 설치 시작 ==="
echo ""

# Helm Repository 추가
echo "1. Helm Repository 추가 중..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
echo "✅ Repository 추가 완료"

echo ""
echo "2. monitoring Namespace 생성 중..."

# 기존 Namespace가 Terminating 상태인지 확인
if kubectl get namespace monitoring 2>/dev/null | grep -q Terminating; then
    echo "⚠️  기존 monitoring Namespace가 삭제 중입니다. 완료될 때까지 대기..."
    
    # Finalizer 제거로 강제 삭제
    kubectl patch namespace monitoring -p '{"spec":{"finalizers":[]}}' --type=merge 2>/dev/null || true
    
    # 완전히 삭제될 때까지 대기 (최대 60초)
    for i in {1..60}; do
        if ! kubectl get namespace monitoring &>/dev/null; then
            echo "✅ 기존 Namespace 삭제 완료"
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
fi

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace 생성 완료"

echo ""
echo "3. kube-prometheus-stack 설치 중..."
echo "   (약 2-3분 소요됩니다)"

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin123 \
  --wait

echo ""
echo "✅ Prometheus Stack 설치 완료"

echo ""
echo "4. 설치된 컴포넌트 확인 중..."
echo ""

# Helm Release 확인
echo "📦 Helm Release:"
helm list -n monitoring

echo ""
echo "🔍 Pod 상태:"
kubectl get pods -n monitoring

echo ""
echo "🌐 Service 목록:"
kubectl get svc -n monitoring

echo ""
echo "=== 설치 완료 ==="
echo ""
echo "📊 Prometheus 접속:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   http://localhost:9090"
echo ""
echo "📈 Grafana 접속:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin123"
