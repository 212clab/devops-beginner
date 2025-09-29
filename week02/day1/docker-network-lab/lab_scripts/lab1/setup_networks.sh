#!/bin/bash

# Week 2 Day 1 Lab 1: 네트워크 인프라 구축 스크립트
# 사용법: ./setup_networks.sh

echo "=== Docker 네트워크 인프라 구축 시작 ==="

# 프론트엔드 네트워크 (외부 접근 가능)
echo "1. 프론트엔드 네트워크 생성 중..."
docker network create --driver bridge \
  --subnet=172.20.1.0/24 \
  --gateway=172.20.1.1 \
  frontend-net

# 백엔드 네트워크 (내부 통신용)
echo "2. 백엔드 네트워크 생성 중..."
docker network create --driver bridge \
  --subnet=172.20.2.0/24 \
  --gateway=172.20.2.1 \
  backend-net

# 데이터베이스 네트워크 (격리된 네트워크)
echo "3. 데이터베이스 네트워크 생성 중..."
docker network create --driver bridge \
  --subnet=172.20.3.0/24 \
  --gateway=172.20.3.1 \
  --internal \
  database-net

# 네트워크 생성 확인
echo "4. 네트워크 생성 확인..."
docker network ls | grep -E "(frontend-net|backend-net|database-net)"

echo "=== 네트워크 인프라 구축 완료 ==="
echo ""
echo "생성된 네트워크:"
echo "- frontend-net: 172.20.1.0/24 (외부 접근 가능)"
echo "- backend-net: 172.20.2.0/24 (내부 통신용)"
echo "- database-net: 172.20.3.0/24 (격리된 네트워크)"