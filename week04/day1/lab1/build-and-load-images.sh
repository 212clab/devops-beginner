#!/bin/bash

echo "=== 서비스별 Docker 이미지 빌드 시작 ==="
echo ""

cd docker-images

# 1. 모놀리식 이미지 빌드
echo "1/4 모놀리식 이미지 빌드 중..."
docker build -t ecommerce-monolith:v1 monolith/

# 2. 사용자 서비스 이미지 빌드
echo "2/4 사용자 서비스 이미지 빌드 중..."
docker build -t user-service:v1 user-service/

# 3. 상품 서비스 이미지 빌드
echo "3/4 상품 서비스 이미지 빌드 중..."
docker build -t product-service:v1 product-service/

# 4. 주문 서비스 이미지 빌드
echo "4/4 주문 서비스 이미지 빌드 중..."
docker build -t order-service:v1 order-service/

echo ""
echo "=== Kind 클러스터에 이미지 로드 중 ==="
echo ""

# Kind 클러스터에 이미지 로드
kind load docker-image ecommerce-monolith:v1 --name lab-cluster
kind load docker-image user-service:v1 --name lab-cluster
kind load docker-image product-service:v1 --name lab-cluster
kind load docker-image order-service:v1 --name lab-cluster

echo ""
echo "=== 이미지 빌드 및 로드 완료 ==="
echo ""
echo "빌드된 이미지:"
echo "- ecommerce-monolith:v1"
echo "- user-service:v1"
echo "- product-service:v1"
echo "- order-service:v1"
echo ""
echo "✅ 이제 Deployment YAML에서 이 이미지들을 사용할 수 있습니다!"
