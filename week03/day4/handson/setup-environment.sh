#!/bin/bash

# Week 3 Day 4 Hands-on 1: 환경 설정
# 사용법: ./setup-environment.sh

set -e

echo "=== Hands-on 1 환경 설정 시작 ==="

# 네임스페이스 확인 및 생성
echo "1/2 네임스페이스 확인 및 생성 중..."
for ns in development staging production; do
    if ! kubectl get namespace $ns &>/dev/null; then
        echo "  - $ns 네임스페이스 생성 중..."
        kubectl create namespace $ns
        
        # 라벨 추가
        case $ns in
            development)
                kubectl label namespace $ns env=dev
                ;;
            staging)
                kubectl label namespace $ns env=staging
                ;;
            production)
                kubectl label namespace $ns env=prod
                ;;
        esac
    else
        echo "  - $ns 네임스페이스 이미 존재"
    fi
done

# 네임스페이스 확인
echo "2/2 네임스페이스 상태 확인 중..."
kubectl get namespace development staging production --show-labels

echo ""
echo "=== Hands-on 1 환경 설정 완료 ==="
echo ""
echo "준비된 네임스페이스:"
echo "- development (env=dev)"
echo "- staging (env=staging)"
echo "- production (env=prod)"
echo ""
echo "다음 단계: Hands-on 1 실습 진행"
