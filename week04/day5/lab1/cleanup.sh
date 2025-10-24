#!/bin/bash
echo "=== Lab 환경 정리 시작 ==="

echo "1/3 네임스페이스 삭제 중..."
kubectl delete namespace production --ignore-not-found=true
kubectl delete namespace staging --ignore-not-found=true
kubectl delete namespace development --ignore-not-found=true
kubectl delete namespace kubecost --ignore-not-found=true

echo "2/3 Metrics Server 삭제 중..."
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --ignore-not-found=true

echo "3/3 클러스터 삭제 확인..."
read -p "클러스터를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kind delete cluster --name lab-cluster
    echo "✅ 클러스터 삭제 완료"
else
    echo "ℹ️  클러스터 유지"
fi

echo ""
echo "=== Lab 환경 정리 완료 ==="
