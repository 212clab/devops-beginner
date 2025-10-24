# Week 4 Day 5 Lab 1 Scripts

## 📋 스크립트 목록

### 실행 순서

1. `step1-setup-cluster.sh` - 클러스터 초기화 (1 control-plane + 2 worker)
2. `step2-install-metrics-server.sh` - Metrics Server 설치
3. `step3-install-kubecost.sh` - Kubecost 설치 (Helm 필요)
4. `step4-deploy-sample-apps.sh` - 샘플 애플리케이션 배포 (3개 네임스페이스)
5. `step5-setup-hpa.sh` - HPA 설정

### 정리

- `cleanup.sh` - 모든 리소스 삭제

## 🚀 빠른 시작

```bash
# 전체 실행
./step1-setup-cluster.sh
./step2-install-metrics-server.sh
./step3-install-kubecost.sh
./step4-deploy-sample-apps.sh
./step5-setup-hpa.sh

# Kubecost 대시보드 접속
kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
# 브라우저: http://localhost:9090

# 정리
./cleanup.sh
```

## ⚠️ 사전 요구사항

- Kind 설치
- kubectl 설치
- Helm 설치 (step3에서 필요)
