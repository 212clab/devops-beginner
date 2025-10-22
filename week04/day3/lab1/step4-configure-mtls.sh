#!/bin/bash

# Week 4 Day 3 Lab 1: mTLS 설정
# 설명: Istio mTLS STRICT 모드 적용

set -e

echo "=== mTLS 설정 시작 ==="

# 1. PeerAuthentication 설정
echo "1/2 PeerAuthentication 설정 중..."
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: secure-app
spec:
  mtls:
    mode: STRICT
EOF

# 2. DestinationRule 설정
echo "2/2 DestinationRule 설정 중..."
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: auth-service
  namespace: secure-app
spec:
  host: auth-service.secure-app.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF

echo ""
echo "=== mTLS 설정 완료 ==="
echo ""
echo "적용된 설정:"
echo "- PeerAuthentication: STRICT 모드"
echo "- DestinationRule: ISTIO_MUTUAL TLS"
echo ""
echo "효과:"
echo "- 모든 서비스 간 통신이 mTLS로 암호화됨"
echo "- 인증되지 않은 통신 차단"
