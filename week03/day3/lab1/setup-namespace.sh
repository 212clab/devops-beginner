#!/bin/bash

# Lab 1 Step 1-1: 네임스페이스 및 기본 설정

echo "🚀 Lab 1 Step 1-1: 환경 준비 시작..."

echo "📦 네임스페이스 생성 중..."
kubectl create namespace day3-lab --dry-run=client -o yaml | kubectl apply -f -

echo "🔧 기본 네임스페이스 설정 중..."
kubectl config set-context --current --namespace=day3-lab # 쿠버네티스의 기본값으로 설정

echo "✅ 환경 준비 완료!"
echo ""
echo "📊 네임스페이스 상태:"
kubectl get namespace day3-lab
echo ""
echo "🎯 다음 단계: 데이터베이스 스토리지 생성"
