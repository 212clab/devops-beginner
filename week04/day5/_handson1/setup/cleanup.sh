#!/bin/bash

# Week 4 Day 5 Hands-on 1: 환경 정리
# 설명: 실습 환경 완전 삭제

echo "=========================================="
echo "  FinOps 실습 환경 정리"
echo "=========================================="
echo ""

echo "⚠️  경고: 모든 실습 데이터가 삭제됩니다."
read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
fi

echo ""
echo "📌 클러스터 삭제 중..."
kind delete cluster --name lab-cluster

echo ""
echo "✅ 정리 완료!"
echo ""
