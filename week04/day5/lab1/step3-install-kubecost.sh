#!/bin/bash

# Week 4 Day 5 Lab 1: Kubecost 설치
# 설명: Helm을 통한 Kubecost 설치 및 Prometheus 연동
# 사용법: ./step3-install-kubecost.sh

set -e

echo "=== Kubecost 설치 시작 ==="

# 1. Helm 설치 확인
echo "1/5 Helm 설치 확인 중..."
if ! command -v helm &> /dev/null; then
    echo "Helm이 설치되어 있지 않습니다. Helm을 먼저 설치해주세요."
    echo "설치 방법: https://helm.sh/docs/intro/install/"
    exit 1
fi

# 2. Helm 저장소 추가
echo "2/5 Helm 저장소 추가 중..."
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update

# 3. Kubecost 설치
echo "3/5 Kubecost 설치 중..."
helm install kubecost kubecost/cost-analyzer \
  --namespace kubecost --create-namespace \
  --set kubecostToken="aGVsbUBrdWJlY29zdC5jb20=xm343yadf98" \
  --set prometheus.server.global.external_labels.cluster_id="lab-cluster" \
  --set prometheus.server.persistentVolume.enabled=false \
  --set prometheus.alertmanager.persistentVolume.enabled=false

# 4. 배포 완료 대기
echo "4/5 Kubecost 배포 완료 대기 중..."
kubectl wait --for=condition=ready pod \
  -l app=cost-analyzer \
  -n kubecost \
  --timeout=300s

# 5. 서비스 확인
echo "5/5 서비스 확인 중..."
kubectl get pods -n kubecost
kubectl get svc -n kubecost

echo ""
echo "=== Kubecost 설치 완료 ==="
echo ""
echo "Kubecost 대시보드 접속:"
echo "kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090"
echo "브라우저: http://localhost:9090"
echo ""
echo "다음 단계: ./step4-deploy-sample-apps.sh"
