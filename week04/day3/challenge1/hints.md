# Challenge 1 힌트 가이드

## 💡 힌트 사용 방법
- 각 시나리오별로 3단계 힌트 제공
- 1단계부터 순서대로 확인하세요
- 최대한 스스로 해결해보고, 막힐 때만 참고하세요

---

## 🚨 시나리오 1: mTLS 통신 실패

### 힌트 1 (방향성)
- mTLS 관련 Istio 리소스를 확인하세요
- PeerAuthentication과 DestinationRule을 살펴보세요

### 힌트 2 (구체적 위치)
```bash
kubectl get peerauthentication -n delivery-platform
kubectl describe peerauthentication default -n delivery-platform
```
- `mode` 필드를 확인하세요
- PERMISSIVE vs STRICT의 차이를 생각해보세요

### 힌트 3 (해결 방향)
- PeerAuthentication의 mode 값을 변경해야 합니다
- 프로덕션 환경에서 권장하는 mTLS 모드는 무엇일까요?
- PERMISSIVE와 STRICT 중 어떤 것이 더 안전할까요?

---

## 🚨 시나리오 2: JWT 검증 실패

### 힌트 1 (방향성)
- JWT 관련 Istio 리소스를 확인하세요
- RequestAuthentication의 설정을 살펴보세요

### 힌트 2 (구체적 위치)
```bash
kubectl get requestauthentication -n delivery-platform
kubectl describe requestauthentication jwt-auth -n delivery-platform
```
- `issuer` 필드를 확인하세요
- Auth Service의 실제 issuer와 비교하세요

### 힌트 3 (해결 방향)
```bash
# Auth Service의 실제 issuer 확인
kubectl get configmap auth-config -n delivery-platform -o yaml
```
- RequestAuthentication의 issuer를 어디에 맞춰야 할까요?
- JWT 발급자와 검증자의 issuer가 일치해야 합니다

---

## 🚨 시나리오 3: OPA 정책 위반

### 힌트 1 (방향성)
- OPA Gatekeeper의 Constraint를 확인하세요
- 리소스 제한이 없는 Deployment를 찾으세요

### 힌트 2 (구체적 위치)
```bash
kubectl get constraints
kubectl describe k8scontainerresourcelimits require-resource-limits
```
- 어떤 Deployment가 정책을 위반하고 있나요?
```bash
kubectl get deployment -n delivery-platform
kubectl describe deployment delivery-service-broken -n delivery-platform
```

### 힌트 3 (해결 방향)
- delivery-service-broken Deployment를 수정해야 합니다
- 컨테이너에 어떤 설정이 누락되어 있나요?
- OPA 정책이 요구하는 것은 무엇인가요?
- Kubernetes 리소스 관리의 기본 요소를 생각해보세요

---

## 🚨 시나리오 4: Authorization Policy 오류

### 힌트 1 (방향성)
- Istio AuthorizationPolicy를 확인하세요
- ServiceAccount principal 설정을 살펴보세요

### 힌트 2 (구체적 위치)
```bash
kubectl get authorizationpolicy -n delivery-platform
kubectl describe authorizationpolicy merchant-policy -n delivery-platform
```
- `principals` 필드를 확인하세요
- 현재 어떤 ServiceAccount가 허용되어 있나요?
- order-service의 ServiceAccount 이름은 무엇인가요?

### 힌트 3 (해결 방향)
- AuthorizationPolicy의 principal에 잘못된 ServiceAccount 이름이 있습니다
- order-service가 merchant-service에 접근해야 합니다
- principal을 올바른 ServiceAccount 이름으로 변경하세요

---

## 🔍 일반적인 디버깅 명령어

### 전체 상태 확인
```bash
kubectl get all -n delivery-platform
kubectl get pods -A
```

### 로그 확인
```bash
kubectl logs -n delivery-platform deployment/order-service
kubectl logs -n delivery-platform deployment/payment-service
```

### 상세 정보 확인
```bash
kubectl describe pod <pod-name> -n delivery-platform
kubectl describe svc <service-name> -n delivery-platform
```

### Istio 리소스 확인
```bash
kubectl get peerauthentication -A
kubectl get requestauthentication -A
kubectl get authorizationpolicy -A
kubectl get destinationrule -A
```

### OPA Gatekeeper 확인
```bash
kubectl get constrainttemplates
kubectl get constraints
kubectl describe constraint <constraint-name>
```

---

## 💡 문제 해결 팁

### 1. 체계적 접근
1. 증상 파악 (어떤 오류가 발생하는가?)
2. 관련 리소스 확인 (어떤 리소스가 관련되어 있는가?)
3. 설정 비교 (올바른 설정과 현재 설정의 차이는?)
4. 수정 및 검증 (수정 후 동작 확인)

### 2. 로그 활용
- 애플리케이션 로그에서 오류 메시지 확인
- Istio sidecar 로그 확인 (istio-proxy 컨테이너)
- Gatekeeper audit 로그 확인

### 3. 검증 방법
- 각 수정 후 즉시 동작 확인
- verify-solution.sh로 전체 검증
- 테스트 요청으로 실제 동작 확인

---

## 🎯 학습 포인트

### mTLS (시나리오 1)
- PERMISSIVE: mTLS와 평문 모두 허용 (마이그레이션용)
- STRICT: mTLS만 허용 (프로덕션 권장)

### JWT (시나리오 2)
- issuer: JWT 토큰 발급자 식별
- 발급자와 검증자의 issuer가 일치해야 함

### OPA (시나리오 3)
- ConstraintTemplate: 정책 정의
- Constraint: 정책 적용 범위
- 리소스 제한은 안정성과 보안의 기본

### Service (시나리오 4)
- Label Selector: Service와 Pod 연결의 핵심
- Endpoints: 실제 연결된 Pod 목록
- 정확한 label 매칭이 필수
