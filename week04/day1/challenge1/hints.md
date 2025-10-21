# Challenge 1 Hints

## 💡 문제 해결 힌트

막힐 때 참고하세요! 단계별로 힌트를 제공합니다.

---

## 🚨 Issue 1: Query Service Endpoint 연결 문제

### 힌트 1: 증상 확인
```bash
# Endpoint가 비어있는지 확인
kubectl get endpoints query-service -n microservices-challenge
```

### 힌트 2: Service 셀렉터 확인
```bash
# Service가 어떤 라벨을 찾고 있는지 확인
kubectl get svc query-service -n microservices-challenge -o yaml | grep -A3 selector
```

### 힌트 3: Pod 라벨 확인
```bash
# 실제 Pod들이 어떤 라벨을 가지고 있는지 확인
kubectl get pods -n microservices-challenge -l app=query-service --show-labels
```

### 힌트 4: 해결 방향
- Service의 `selector`와 Pod의 `labels`가 일치해야 Endpoint가 생성됩니다
- `broken-cqrs.yaml` 파일에서 Service 부분을 찾아보세요
- `app: wrong-query-service` 같은 부분이 있나요?

---

## 🚨 Issue 2: Event Processor CronJob 스케줄 문제

### 힌트 1: 현재 스케줄 확인
```bash
# CronJob의 현재 스케줄 확인
kubectl get cronjob event-processor -n microservices-challenge -o jsonpath='{.spec.schedule}'
```

### 힌트 2: Cron 표현식 이해
```
Cron 표현식: 분 시 일 월 요일

예시:
- */5 * * * *  : 5분마다 실행
- 0 */1 * * *  : 매시간 정각에 실행
- */30 * * * * : 30분마다 실행
```

### 힌트 3: 해결 방향
- 현재 스케줄이 너무 자주 실행되고 있나요?
- `broken-eventsourcing.yaml` 파일에서 CronJob의 `schedule` 부분을 찾아보세요
- 매시간 또는 30분마다 실행되도록 변경하세요

---

## 🚨 Issue 3: Saga Orchestrator 실행 실패

### 힌트 1: Job 존재 확인
```bash
# Saga Job이 있는지 확인
kubectl get jobs -n microservices-challenge
```

### 힌트 2: ConfigMap URL 확인
```bash
# ConfigMap의 URL 설정 확인
kubectl get configmap saga-config -n microservices-challenge -o yaml | grep -A3 data
```

### 힌트 3: Kubernetes DNS 이해
```
Kubernetes 서비스 DNS 형식:
- 같은 네임스페이스: <service-name>
- 다른 네임스페이스: <service-name>.<namespace>.svc.cluster.local

예시:
- 짧은 형식: http://order-service/api/orders
- FQDN 형식: http://order-service.microservices-challenge.svc.cluster.local/api/orders
```

### 힌트 4: Job 로그 확인 (Job이 있다면)
```bash
# Job 로그에서 오류 확인
kubectl logs job/saga-orchestrator -n microservices-challenge
```

### 힌트 5: 해결 방향
- `broken-saga.yaml` 파일에서 `saga-config` ConfigMap을 찾아보세요
- `ORDER_SERVICE_URL`이 FQDN 형식인가요?
- Job이 없다면 파일에 Job 정의가 있는지 확인하세요
- Job을 수정했다면 기존 Job을 삭제하고 재생성해야 합니다:
  ```bash
  kubectl delete job saga-orchestrator -n microservices-challenge
  kubectl apply -f broken-saga.yaml
  ```

---

## 🚨 Issue 4: Ingress User Service 라우팅 문제

### 힌트 1: Ingress 백엔드 확인
```bash
# Ingress가 어떤 서비스를 가리키는지 확인
kubectl get ingress ecommerce-ingress -n microservices-challenge -o yaml | \
  grep -A5 "/api/users"
```

### 힌트 2: 실제 서비스 확인
```bash
# 실제 존재하는 서비스 목록
kubectl get svc -n microservices-challenge
```

### 힌트 3: 서비스 테스트
```bash
# 클러스터 내부에서 서비스 접근 테스트
kubectl exec -n testing deployment/load-tester -- \
  curl -s http://user-service.microservices-challenge.svc.cluster.local
```

### 힌트 4: 해결 방향
- `broken-networking.yaml` 파일에서 Ingress 부분을 찾아보세요
- `/api/users` 경로의 백엔드 서비스 이름이 올바른가요?
- `wrong-user-service` 같은 이름이 있나요?
- 실제 서비스 이름은 `user-service`입니다

---

## 🔧 일반적인 디버깅 명령어

### 리소스 상태 확인
```bash
# 전체 리소스 확인
kubectl get all -n microservices-challenge

# 특정 리소스 상세 정보
kubectl describe <resource-type> <resource-name> -n microservices-challenge

# 리소스 YAML 확인
kubectl get <resource-type> <resource-name> -n microservices-challenge -o yaml
```

### 로그 확인
```bash
# Pod 로그
kubectl logs <pod-name> -n microservices-challenge

# Job 로그
kubectl logs job/<job-name> -n microservices-challenge

# 이전 컨테이너 로그 (재시작된 경우)
kubectl logs <pod-name> -n microservices-challenge --previous
```

### 네트워크 테스트
```bash
# 클러스터 내부에서 서비스 테스트
kubectl exec -n testing deployment/load-tester -- curl -s <service-url>

# DNS 해석 테스트
kubectl exec -n testing deployment/load-tester -- \
  nslookup <service-name>.microservices-challenge.svc.cluster.local
```

### YAML 파일 수정 후
```bash
# 변경사항 적용
kubectl apply -f broken-xxx.yaml

# 적용이 안 되면 삭제 후 재생성
kubectl delete -f broken-xxx.yaml
kubectl apply -f broken-xxx.yaml
```

---

## 📚 추가 학습 자료

### Kubernetes 공식 문서
- Service: https://kubernetes.io/docs/concepts/services-networking/service/
- Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- CronJob: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- Job: https://kubernetes.io/docs/concepts/workloads/controllers/job/

### 문제 해결 패턴
1. **증상 확인**: 무엇이 작동하지 않는가?
2. **로그 분석**: 오류 메시지는 무엇인가?
3. **설정 검증**: 설정이 올바른가?
4. **연결 테스트**: 네트워크 연결이 되는가?
5. **수정 적용**: 변경사항을 적용하고 검증

---

## 💪 막힐 때 시도해볼 것들

1. **검증 스크립트 실행**: `./verify-challenge.sh`로 현재 상태 확인
2. **리소스 상태 확인**: `kubectl get all -n microservices-challenge`
3. **로그 확인**: 오류 메시지에서 힌트 찾기
4. **YAML 파일 재확인**: 오타나 들여쓰기 오류 확인
5. **solutions.md 참고**: 막히면 해결 방법 확인

화이팅! 💪
