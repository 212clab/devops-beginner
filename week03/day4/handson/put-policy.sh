#!/bin/bash

# Step 1-1: Restricted 정책 적용 
# ./put-policy.sh

# Production: restricted 정책
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Development: baseline 정책
kubectl label namespace development \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline

# Staging: baseline 정책
kubectl label namespace staging \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline

# 정책 확인
kubectl get namespace production -o yaml | grep pod-security
kubectl get namespace development -o yaml | grep pod-security
kubectl get namespace staging -o yaml | grep pod-security