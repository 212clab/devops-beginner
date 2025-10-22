#!/bin/bash

# Week 4 Day 3 Challenge 1: 환경 정리
# 설명: 클러스터 삭제

echo "=== Challenge 환경 정리 시작 ==="

# 클러스터 삭제
kind delete cluster --name lab-cluster

echo ""
echo "=== Challenge 환경 정리 완료 ==="
