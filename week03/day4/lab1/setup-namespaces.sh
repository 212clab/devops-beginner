#!/bin/bash

# Week 3 Day 4 Lab 1: 네임스페이스 설정
# 사용법: ./setup-namespaces.sh

set -e

echo "=== 네임스페이스 생성 시작 ==="

# 네임스페이스 생성
echo "1/3 네임스페이스 생성 중..."
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# 라벨 추가
echo "2/3 라벨 추가 중..."
kubectl label namespace development env=dev --overwrite
kubectl label namespace staging env=staging --overwrite
kubectl label namespace production env=prod --overwrite

# 확인
echo "3/3 네임스페이스 확인 중..."
kubectl get namespaces development staging production --show-labels

echo ""
echo "=== 네임스페이스 생성 완료 ==="
echo ""
echo "생성된 네임스페이스:"
echo "- development (env=dev)"
echo "- staging (env=staging)"
echo "- production (env=prod)"
