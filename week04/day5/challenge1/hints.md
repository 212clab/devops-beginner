# Week 4 Day 5 Challenge 1: 힌트 가이드

## 🎯 전체 접근 방법

### 1단계: 현재 상태 파악
```bash
# 모든 네임스페이스의 Pod 확인
kubectl get pods --all-namespaces

# 리소스 사용률 확인
kubectl top pods --all-namespaces

# HPA 상태 확인
kubectl get hpa --all-namespaces
```

### 2단계: Kubecost로 비용 분석
- http://localhost:30090 접속
- 네임스페이스별 비용 확인
- 낭비 요소 식별

---

## 🚨 시나리오 1: 과도한 리소스 할당

### 💡 힌트 1: 실제 사용량 확인
```bash
# Production Pod의 실제 리소스 사용량 확인
kubectl top pods -n production

# 예상 결과: CPU 50-200m, Memory 100-400Mi 사용 중
```

### 💡 힌트 2: Right-sizing 기준
- **CPU**: 실제 사용량의 1.2-1.5배로 requests 설정
- **Memory**: 실제 사용량의 1.2-1.5배로 requests 설정
- **limits**: requests의 1.5-2배로 설정

### 💡 힌트 3: 수정 위치
`broken-scenario1.yaml` 파일에서:
- `resources.requests.cpu`: 2000m → 200m 수준
- `resources.requests.memory`: 4Gi → 256Mi 수준
- `resources.limits.cpu`: 4000m → 400m 수준
- `resources.limits.memory`: 8Gi → 512Mi 수준

### 💡 힌트 4: 적용 방법
```bash
# 파일 수정 후
kubectl apply -f broken-scenario1.yaml

# 변경 확인
kubectl get deployment frontend -n production -o yaml | grep -A 4 "resources:"
```

---

## 🚨 시나리오 2: HPA 미설정

### 💡 힌트 1: HPA 필요성 확인
```bash
# 현재 HPA 상태 확인
kubectl get hpa -n production

# 예상: HPA가 없거나 매우 적음
```

### 💡 힌트 2: HPA 설정 기준
- **Production**: min 2, max 10, CPU 70%
- **Staging**: min 1, max 5, CPU 70%
- **Development**: HPA 불필요 (고정 1개)

### 💡 힌트 3: 수정 위치
`broken-scenario2.yaml` 파일에서:
- 주석 처리된 HPA 설정 찾기 (# 제거)
- 각 서비스별 HPA 활성화

### 💡 힌트 4: 적용 및 확인
```bash
# 파일 수정 후
kubectl apply -f broken-scenario2.yaml

# HPA 동작 확인
kubectl get hpa -n production
kubectl describe hpa frontend-hpa -n production
```

---

## 🚨 시나리오 3: 환경별 과도한 복제본

### 💡 힌트 1: 환경별 복제본 수 확인
```bash
# 각 환경의 복제본 수 확인
kubectl get deployments -n production
kubectl get deployments -n staging
kubectl get deployments -n development
```

### 💡 힌트 2: 권장 복제본 수
- **Production**: 3-6개 (HPA로 자동 조정)
- **Staging**: 1-2개 (HPA로 자동 조정)
- **Development**: 1개 (고정)

### 💡 힌트 3: 수정 위치
`broken-scenario3.yaml` 파일에서:
- Staging: `replicas: 3` → `replicas: 2`
- Staging: `replicas: 5` → `replicas: 2`
- Development: `replicas: 2-3` → `replicas: 1`

### 💡 힌트 4: 비용 절감 효과
- Staging: 50-60% 절감
- Development: 60-70% 절감

---

## 🚨 시나리오 4: 리소스 제한 누락

### 💡 힌트 1: limits 누락 Pod 찾기
```bash
# limits가 없는 Pod 찾기
kubectl get pods -n production -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name'
```

### 💡 힌트 2: limits 설정 이유
- **CPU limits**: 버스트 허용하되 노드 과부하 방지
- **Memory limits**: OOM(Out of Memory) 방지
- **노드 안정성**: 다른 Pod 영향 최소화

### 💡 힌트 3: 수정 위치
`broken-scenario4.yaml` 파일에서:
- 주석 처리된 `limits:` 섹션 찾기
- 주석 제거 (# 삭제)

### 💡 힌트 4: limits 설정 기준
- **CPU limits**: requests의 1.5-2배
- **Memory limits**: requests의 1.5-2배

---

## 🔍 디버깅 팁

### 문제 해결 순서
1. **현상 파악**: `kubectl get`, `kubectl top` 명령어
2. **상세 분석**: `kubectl describe` 명령어
3. **로그 확인**: `kubectl logs` 명령어
4. **설정 검증**: YAML 파일 확인
5. **적용 및 테스트**: `kubectl apply` 후 검증

### 유용한 명령어
```bash
# 리소스 사용률 정렬
kubectl top pods -n production --sort-by=cpu
kubectl top pods -n production --sort-by=memory

# HPA 상태 모니터링
kubectl get hpa -n production --watch

# 복제본 수 확인
kubectl get deployments --all-namespaces -o wide

# 리소스 설정 확인
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 10 "resources:"
```

### 검증 스크립트 활용
```bash
# 해결 후 검증
./verify-solution.sh

# 통과하지 못한 시나리오 재확인
```

---

## 💰 예상 비용 절감 효과

### 시나리오별 절감률
- **시나리오 1 (Right-sizing)**: 50-80% 절감
- **시나리오 2 (HPA)**: 30-60% 절감 (트래픽 패턴에 따라)
- **시나리오 3 (환경별 최적화)**: 60-70% 절감
- **시나리오 4 (리소스 제한)**: 노드 과부하 방지 (간접 비용 절감)

### 전체 예상 절감
- **월 비용**: $90,000 → $30,000-40,000
- **절감률**: 55-67%
- **연간 절감**: $600,000-720,000

---

## 🎯 성공 기준

### 검증 항목
- [ ] 모든 Pod의 리소스 사용률 50-80%
- [ ] Production/Staging에 HPA 설정 완료
- [ ] 환경별 적절한 복제본 수
- [ ] 모든 Pod에 limits 설정

### 최종 확인
```bash
# 전체 검증
./verify-solution.sh

# 예상 결과: 4/4 통과
```

---

## 📚 추가 학습 자료

### FinOps 베스트 프랙티스
- Right-sizing: 정기적 리소스 사용률 분석
- HPA: 트래픽 패턴 기반 자동 스케일링
- 환경 분리: 비프로덕션 환경 최소화
- 리소스 제한: 노드 안정성 확보

### Kubecost 활용
- Allocation: 네임스페이스/Pod별 비용
- Savings: 최적화 추천 사항
- Reports: 비용 트렌드 분석
- Alerts: 비용 임계값 알림
