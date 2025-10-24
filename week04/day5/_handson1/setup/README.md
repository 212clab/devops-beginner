# Week 4 Day 5 Hands-on 1: FinOps 실습 환경

## 🚀 빠른 시작

### 전체 환경 구축 (권장)
```bash
./setup-complete-environment.sh
./add-jaeger-and-dashboards.sh
```

### 환경 정리
```bash
./cleanup.sh
```

## 📊 접속 정보

| 서비스 | URL | 인증 정보 |
|--------|-----|-----------|
| **Prometheus** | http://localhost:9090 | 포트 포워딩 필요: `kubectl port-forward -n monitoring svc/prometheus 9090:9090` |
| **Grafana** | http://localhost:30091 | ID: admin / PW: admin |
| **Kubecost** | http://localhost:30090 | - |
| **Jaeger** | http://localhost:30092 | - |

## 📦 배포된 리소스

### 모니터링 스택
- **Metrics Server**: 리소스 메트릭 수집
- **Prometheus**: 메트릭 저장 및 쿼리
- **Grafana**: 시각화 대시보드
- **Kubecost**: 비용 분석
- **Jaeger**: 분산 추적

### 애플리케이션
- **Production**: 3 Pods (CPU: 100m-500m, Memory: 128Mi-512Mi)
- **Staging**: 2 Pods (CPU: 50m-200m, Memory: 64Mi-256Mi)
- **Development**: 1 Pod (CPU: 50m-100m, Memory: 64Mi-128Mi)

## 🔍 유용한 명령어

```bash
# 전체 Pod 상태 확인
kubectl get pods --all-namespaces

# 노드 리소스 사용량
kubectl top nodes

# 네임스페이스별 Pod 리소스 사용량
kubectl top pods -n production
kubectl top pods -n staging
kubectl top pods -n development

# Prometheus 타겟 확인
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# 브라우저: http://localhost:9090/targets
```

## 🎯 실습 목표

1. **비용 가시성**: Kubecost로 네임스페이스별 비용 확인
2. **리소스 최적화**: 과도한 리소스 요청 식별
3. **환경별 차별화**: Production/Staging/Development 비용 비교
4. **모니터링**: Grafana 대시보드로 실시간 모니터링
5. **추적**: Jaeger로 분산 추적 (향후 확장)

## ⚠️ 문제 해결

### Kubecost에 데이터가 표시되지 않는 경우
1-2분 기다린 후 새로고침

### Grafana 대시보드가 비어있는 경우
- Prometheus 데이터소스 확인: Configuration > Data Sources
- 대시보드 확인: Dashboards > Browse > Kubernetes Cluster Monitoring

### Prometheus 타겟이 Down인 경우
```bash
# Pod 상태 확인
kubectl get pods -n production -o wide

# Pod 로그 확인
kubectl logs -n production <pod-name> -c nginx-exporter
```
