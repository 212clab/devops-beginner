#!/bin/bash

# Week 3 Day 4 Lab 1: 개발자 Role 생성
# 사용법: ./create-developer-role.sh

set -e

echo "=== 개발자 Role 생성 시작 ==="

# 개발자 Role 생성
echo "1/3 개발자 Role 생성 중..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["get", "list", "watch", "create", "delete"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create", "update"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
EOF

# ServiceAccount 생성
echo "2/3 ServiceAccount 생성 중..."
kubectl create serviceaccount developer-sa -n development --dry-run=client -o yaml | kubectl apply -f -

# RoleBinding 생성
echo "3/3 RoleBinding 생성 중..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: ServiceAccount
  name: developer-sa
  namespace: development
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF

echo ""
echo "=== 개발자 Role 생성 완료 ==="
echo ""
echo "생성된 리소스:"
echo "- Role: developer-role (namespace: development)"
echo "- ServiceAccount: developer-sa"
echo "- RoleBinding: developer-binding"
echo ""
echo "권한 테스트:"
kubectl auth can-i create pods --as=system:serviceaccount:development:developer-sa -n development
