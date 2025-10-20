#!/bin/bash

# Week 4 Day 1 Lab 1: 전체 환경 정리 (수정된 버전)
# 사용법: ./cleanup-fixed.sh

echo "=== Week 4 Day 1 Lab 1: 환경 정리 시작 ==="
echo ""

# 사용자 확인
read -p "모든 실습 리소스를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "정리 작업을 취소했습니다."
    exit 0
fi

echo "1/3 ecommerce 네임스페이스 정리 중..."
kubectl delete namespace ecommerce-advanced --ignore-not-found=true
echo "✅ ecommerce 환경 정리 완료"

echo ""
echo "2/3 /etc/hosts 파일 정리 중..."
sudo sed -i '/ecommerce.local/d' /etc/hosts 2>/dev/null || echo "hosts 파일 정리 건너뜀 (권한 없음)"
echo "✅ hosts 파일 정리 완료"

echo ""
echo "3/3 정리 상태 확인 중..."
echo "남은 네임스페이스:"
kubectl get namespaces | grep ecommerce-advanced || echo "ecommerce-advanced 네임스페이스가 정리되었습니다."

echo ""
echo "=== 환경 정리 완료 ==="
echo ""
echo "🧹 정리된 리소스:"
echo "- ecommerce 네임스페이스 (모든 Pod, Service, Ingress 포함)"
echo "- /etc/hosts의 ecommerce.local 항목"
echo ""
echo "💡 참고사항:"
echo "- Kind 클러스터는 유지됩니다"
echo "- Ingress Controller는 유지됩니다 (다른 실습에서 재사용 가능)"
echo "- 완전한 정리를 원한다면: kind delete cluster --name lab-cluster"
echo ""
echo "🎉 Week 4 Day 1 Lab 1 실습이 완료되었습니다!"
