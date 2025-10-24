#!/bin/bash
# Week 4 Day 5 Hands-on 1: 메트릭 수집 상태 확인

echo "=== 메트릭 수집 상태 확인 ==="
echo ""

# Prometheus 포트포워드 시작
kubectl port-forward -n monitoring svc/prometheus 9090:9090 >/dev/null 2>&1 &
PF_PID=$!
sleep 3

echo "1. container_cpu_usage_seconds_total (cAdvisor)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "2. container_memory_usage_bytes (cAdvisor)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=container_memory_usage_bytes' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "3. kube_pod_info (kube-state-metrics)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=kube_pod_info' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "4. kube_pod_container_resource_requests (kube-state-metrics)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=kube_pod_container_resource_requests' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "5. kube_node_status_condition (kube-state-metrics)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=kube_node_status_condition' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "6. node_cpu_seconds_total (node-exporter)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=node_cpu_seconds_total' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "7. container_network_receive_bytes_total (cAdvisor)"
RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=container_network_receive_bytes_total' | jq -r '.data.result | length')
echo "   데이터 포인트: $RESULT"

echo ""
echo "=== Prometheus Targets 상태 ==="
curl -s 'http://localhost:9090/api/v1/targets' | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"' | sort | uniq -c

# 포트포워드 종료
kill $PF_PID 2>/dev/null

echo ""
echo "=== 확인 완료 ==="
echo ""
echo "💡 데이터 포인트가 0이면 해당 메트릭이 수집되지 않는 것입니다."
