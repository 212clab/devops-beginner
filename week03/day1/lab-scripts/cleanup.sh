#!/bin/bash

# Lab 1 정리 스크립트

echo "=== Lab 1 Cleanup ==="

echo "1. Deleting test workloads..."
kubectl delete namespace lab-day1 --ignore-not-found=true

echo "2. Deleting Kind cluster..."
kind delete cluster --name lab-cluster

echo "3. Cleaning up generated files..."
cd ~/k8s-lab1 2>/dev/null || cd ~
rm -rf ~/k8s-lab1

echo "4. Resetting kubectl context..."
kubectl config use-context docker-desktop 2>/dev/null || echo "No docker-desktop context found"

echo "Lab 1 cleanup completed!"