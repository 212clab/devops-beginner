# Challenge 1 스크립트 가이드

Week 4 Day 1 Challenge 1의 모든 스크립트와 리소스를 관리하는 디렉토리입니다.

---

## 📁 파일 구조

```
challenge1/
├── README.md                    # 이 파일
├── setup-environment.sh         # 환경 설정
├── deploy-broken-system.sh      # 문제 시스템 배포
├── verify-solutions.sh          # 해결 검증
├── cleanup.sh                   # 환경 정리
├── start-port-forward.sh        # 포트 포워딩 시작
├── stop-port-forward.sh         # 포트 포워딩 종료
├── hints.md                     # 힌트 가이드
├── solutions.md                 # 완전한 해결 방법
├── broken-saga.yaml             # Saga 패턴 문제
├── broken-cqrs.yaml             # CQRS 패턴 문제
├── broken-eventsourcing.yaml    # Event Sourcing 문제
└── broken-networking.yaml       # 네트워킹 문제
```

---

## 🚀 사용 방법

### 1. 환경 설정
```bash
./setup-environment.sh
```
- 네임스페이스 생성
- 클러스터 상태 확인
- 기본 설정 구성

### 2. 문제 시스템 배포
```bash
./deploy-broken-system.sh
```
- 4가지 패턴의 의도적 오류가 포함된 시스템 배포
- Saga, CQRS, Event Sourcing, Networking 문제 생성

### 3. 문제 해결
**스스로 해결 시도 (20분)**:
- 로그 확인, 설정 검증, 팀 토론
- 체계적인 디버깅 프로세스 적용

**힌트 참고 (20분 후)**:
```bash
cat hints.md
```

**완전한 해결 방법 (최후의 수단)**:
```bash
cat solutions.md
```

### 4. 해결 검증
```bash
./verify-solutions.sh
```
- 12개 테스트 케이스 자동 검증
- 부분 점수 및 힌트 제공
- 100% 통과 시 축하 메시지

### 5. 웹 확인
```bash
./start-port-forward.sh
```
- 6개 서비스 포트 포워딩 (백그라운드)
- 웹 브라우저에서 JSON 응답 확인
- http://localhost:8081-8086

```bash
./stop-port-forward.sh
```
- 모든 포트 포워딩 종료

### 6. 환경 정리
```bash
./cleanup.sh
```
- 모든 리소스 삭제
- 네임스페이스 정리
- 클러스터 초기화

---

## 🎯 검증 테스트 항목

### Saga 패턴 (3개)
- ✅ Saga Job 성공 실행
- ✅ Order Service 정상 응답
- ✅ Payment Service 정상 응답

### CQRS 패턴 (3개)
- ✅ Command Service 정상 응답
- ✅ Query Service 정상 응답
- ✅ Command Service 엔드포인트 연결

### Event Sourcing (3개)
- ✅ Event Store API 정상 응답
- ✅ CronJob 정상 스케줄링
- ✅ Event Processor 실행 가능

### 네트워킹 (3개)
- ✅ User Service 엔드포인트 연결
- ✅ Ingress 라우팅 정상
- ✅ DNS 해결 정상

---

## 🐛 의도적 오류 목록

### broken-saga.yaml
1. Nginx location 블록 세미콜론 누락
2. Job backoffLimit이 0
3. Job 스크립트의 짧은 URL (FQDN 필요)
4. Job 스크립트의 exit 1 (강제 실패)

### broken-cqrs.yaml
1. JSON 키에 따옴표 누락
2. Service targetPort 불일치
3. Service selector 오류

### broken-eventsourcing.yaml
1. CronJob 스케줄 요일 필드 오류 (일요일만 실행)
2. Nginx alias 경로 오류
3. 볼륨 마운트 경로 오류

### broken-networking.yaml
1. Service selector 불일치
2. Ingress backend 서비스 이름 오류
3. Ingress 포트 번호 오류

---

## 💡 학습 포인트

### Nginx 설정
- location 블록 문법
- JSON 응답 형식
- alias vs root

### Kubernetes Job/CronJob
- backoffLimit 설정
- CronJob 스케줄 표현식
- restartPolicy

### Service 연결
- selector와 라벨 매칭
- targetPort 설정
- 엔드포인트 확인

### 볼륨 마운트
- ConfigMap 마운트
- 경로 충돌 방지
- 파일 위치 확인

---

## 🔧 트러블슈팅

### Job "field is immutable" 오류
**문제**: Job을 수정하려고 할 때 발생
```
The Job "saga-orchestrator" is invalid: spec.template: Invalid value: ...: field is immutable
```

**해결**: Job은 수정 불가, 반드시 삭제 후 재생성
```bash
kubectl delete job saga-orchestrator -n microservices-challenge
kubectl apply -f fixed-saga.yaml
```

### ConfigMap 변경이 적용 안 됨
**문제**: ConfigMap 수정 후에도 Pod가 이전 설정 사용

**해결**: Pod 재시작 필요
```bash
kubectl rollout restart deployment/<deployment-name> -n microservices-challenge
```

### 스크립트 실행 권한 오류
```bash
chmod +x *.sh
```

### Kubernetes 클러스터 연결 실패
```bash
kubectl cluster-info
kubectl get nodes
```

### 포트 포워딩 충돌
```bash
./stop-port-forward.sh
lsof -i :8081-8086
```

### 리소스 정리 실패
```bash
kubectl delete namespace microservices-challenge --force --grace-period=0
kubectl delete namespace testing --force --grace-period=0
```

---

## 📚 참고 문서

- **Challenge 문서**: `../../challenge_1.md`
- **힌트**: `hints.md`
- **해결 방법**: `solutions.md`
- **Kubernetes 공식 문서**: https://kubernetes.io/docs/

---

## ✅ 체크리스트

Challenge 완료 전 확인사항:

- [ ] 환경 설정 완료
- [ ] 문제 시스템 배포 완료
- [ ] 4가지 패턴 모두 분석
- [ ] 12개 테스트 모두 통과
- [ ] 웹 브라우저에서 확인
- [ ] 환경 정리 완료
- [ ] 학습 내용 정리

---

**🎉 Challenge 1을 완료하신 것을 축하합니다!**
