#!/bin/bash

# Week 4 Day 5 Challenge 1: 환경 정리
# 설명: 클러스터 삭제

echo "=== Challenge 환경 정리 시작 ==="

# 클러스터 삭제
echo "lab-cluster 삭제 중..."
kind delete cluster --name lab-cluster

echo ""
echo "=== Challenge 환경 정리 완료 ==="
echo ""
echo "정리된 리소스:"
echo "- Kind 클러스터 (lab-cluster)"
echo "- 모든 네임스페이스 (production, staging, development)"
echo "- Kubecost, Prometheus, Metrics Server"
