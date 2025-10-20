#!/bin/bash

echo "=== NodePort 서비스 배포 시작 ==="
echo ""

# 1. 모놀리식 NodePort 서비스
echo "1/2 모놀리식 애플리케이션 NodePort 서비스 생성 중..."
kubectl apply -f manifests/monolith/monolith-nodeport.yaml

# 2. 마이크로서비스 NodePort 서비스
echo "2/2 마이크로서비스 NodePort 서비스 생성 중..."
kubectl apply -f manifests/microservices/microservices-nodeport.yaml

echo ""
echo "=== NodePort 서비스 배포 완료 ==="
echo ""

# 서비스 상태 확인
echo "📊 배포된 NodePort 서비스:"
kubectl get svc -n ecommerce-advanced -o wide | grep NodePort

echo ""
echo "✅ 외부 접근 정보:"
echo "- 모놀리식 애플리케이션: http://localhost:30080/"
echo "- 상품 서비스: http://localhost:30081/"
echo "- 주문 서비스: http://localhost:30082/"
echo ""
echo "💡 브라우저나 curl로 테스트 가능합니다:"
echo "   curl http://localhost:30080/"
echo "   curl http://localhost:30081/"
echo "   curl http://localhost:30082/"
