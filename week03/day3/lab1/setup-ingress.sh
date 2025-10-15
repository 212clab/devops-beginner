#!/bin/bash

# Lab 1 Step 5-1: Ingress Controller 설치 및 설정

echo "🚀 Lab 1 Step 5-1: Ingress 설정 시작..."

echo "🌐 Ingress 리소스 생성 중..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-ingress
  namespace: day3-lab
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: shop.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 3000
EOF

echo "✅ Ingress 설정 완료!"
echo ""
echo "📊 Ingress 상태:"
kubectl get ingress shop-ingress
echo ""
echo "🌐 도메인 접근 설정:"
echo "다음 명령어로 로컬 hosts 파일에 추가하세요:"
echo "echo '127.0.0.1 shop.local' | sudo tee -a /etc/hosts"
echo ""
echo "접근 URL: http://shop.local"
echo ""
echo "🎯 다음 단계: 전체 시스템 테스트"
