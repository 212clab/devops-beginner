# Lab 1 스크립트 검증 리포트

## ✅ 검증 완료 항목

### 1. 구문 검증
- ✅ 모든 스크립트 bash 구문 오류 없음
- ✅ YAML heredoc 구문 정상
- ✅ 변수 및 명령어 체인 정상

### 2. 에러 처리
- ✅ 모든 step 스크립트에 `set -e` 포함
- ✅ 에러 발생 시 즉시 종료 설정

### 3. 진행 상황 표시
- ✅ Step 1: 3단계 진행 표시 (1/3, 2/3, 3/3)
- ✅ Step 2: 3단계 진행 표시
- ✅ Step 3: 5단계 진행 표시
- ✅ Step 4: 4단계 진행 표시
- ✅ Step 5: 2단계 진행 표시

### 4. 스크립트 연결성
```
step1 → step2 → step3 → step4 → step5
```
- ✅ 각 스크립트가 다음 단계 안내 포함
- ✅ 순차적 실행 가이드 제공

### 5. 리소스 설정
**Production (web-app)**:
- CPU: 200m (requests), 500m (limits)
- Memory: 256Mi (requests), 512Mi (limits)
- Replicas: 3

**Staging (api-server)**:
- CPU: 100m (requests), 300m (limits)
- Memory: 128Mi (requests), 256Mi (limits)
- Replicas: 2

**Development (dev-service)**:
- CPU: 50m (requests), 100m (limits)
- Memory: 64Mi (requests), 128Mi (limits)
- Replicas: 1

### 6. HPA 설정
**Production HPA**:
- Min: 2, Max: 10
- CPU: 70%, Memory: 80%

**Staging HPA**:
- Min: 1, Max: 5
- CPU: 70%

### 7. 네임스페이스 라벨
- production: team=frontend, cost-center=CC-1001
- staging: team=qa, cost-center=CC-1002
- development: team=dev, cost-center=CC-1003

## 📋 실행 순서 검증

1. ✅ step1-setup-cluster.sh
   - Kind 클러스터 생성 (1 control-plane + 2 worker)
   - 포트 매핑: 30080, 30081, 443, 80

2. ✅ step2-install-metrics-server.sh
   - Metrics Server 설치
   - Kind 환경 패치 (--kubelet-insecure-tls)

3. ✅ step3-install-kubecost.sh
   - Helm 설치 확인
   - Kubecost + Prometheus 설치

4. ✅ step4-deploy-sample-apps.sh
   - 3개 네임스페이스 생성
   - 각 환경별 애플리케이션 배포

5. ✅ step5-setup-hpa.sh
   - Production/Staging HPA 설정

6. ✅ cleanup.sh
   - 네임스페이스 삭제
   - Metrics Server 삭제
   - 클러스터 삭제 (선택)

## ✅ 최종 검증 결과

**모든 스크립트가 정상적으로 작성되었으며 의도한 대로 동작할 것으로 예상됩니다.**

### 권장 사항
1. 실제 Kind 클러스터에서 전체 실행 테스트 권장
2. Helm 사전 설치 필요 (step3)
3. 각 단계별 대기 시간 충분히 확보

### 예상 실행 시간
- Step 1: ~2분
- Step 2: ~2분
- Step 3: ~5분 (Kubecost 이미지 Pull)
- Step 4: ~2분
- Step 5: ~1분
- **총 예상 시간**: ~12분

## 📝 테스트 체크리스트

실제 실행 시 확인 사항:
- [ ] Kind 클러스터 정상 생성
- [ ] Metrics Server 메트릭 수집 확인 (`kubectl top nodes`)
- [ ] Kubecost Pod 3/3 Running
- [ ] 3개 네임스페이스 애플리케이션 모두 Running
- [ ] HPA TARGETS 표시 확인
- [ ] Kubecost 대시보드 접속 가능 (http://localhost:9090)
