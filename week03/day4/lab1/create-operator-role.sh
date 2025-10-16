#!/bin/bash

# Week 3 Day 4 Lab 1: 운영자 Role 생성
# 사용법: ./create-operator-role.sh

set -e

echo "=== 운영자 Role 생성 시작 ==="

# 운영자 ClusterRole (읽기 전용) 생성
echo "1/4 ClusterRole 생성 중..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: operator-readonly
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
EOF

# 프로덕션 운영 Role 생성
echo "2/4 프로덕션 Role 생성 중..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator-prod
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "deployments/scale"]
  verbs: ["get", "list", "update", "patch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "update"]
EOF

# ServiceAccount 생성
echo "3/4 ServiceAccount 생성 중..."
kubectl create serviceaccount operator-sa -n production --dry-run=client -o yaml | kubectl apply -f -

# Bindings 생성
echo "4/4 Bindings 생성 중..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: operator-readonly-binding
subjects:
- kind: ServiceAccount
  name: operator-sa
  namespace: production
roleRef:
  kind: ClusterRole
  name: operator-readonly
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: operator-prod-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: operator-sa
  namespace: production
roleRef:
  kind: Role
  name: operator-prod
  apiGroup: rbac.authorization.k8s.io
EOF

echo ""
echo "=== 운영자 Role 생성 완료 ==="
echo ""
echo "생성된 리소스:"
echo "- ClusterRole: operator-readonly"
echo "- Role: operator-prod (namespace: production)"
echo "- ServiceAccount: operator-sa"
echo "- ClusterRoleBinding: operator-readonly-binding"
echo "- RoleBinding: operator-prod-binding"
