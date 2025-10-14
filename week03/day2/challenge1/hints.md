# Challenge 1 힌트

## 🔍 문제 1: broken-app

**증상**: Pod가 ImagePullBackOff 상태

**힌트**:
- `kubectl describe pod <pod-name> -n challenge1`로 이벤트 확인
- 이미지 태그를 확인해보세요
- `nginx:nonexistent-tag` → `nginx:1.20`

**해결 명령어**:
```bash
kubectl patch deployment broken-app -n challenge1 -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"nginx:1.20"}]}}}}'
```

## 🔍 문제 2: resource-hungry

**증상**: Pod가 Pending 상태

**힌트**:
- `kubectl describe pod <pod-name> -n challenge1`로 스케줄링 실패 원인 확인
- CPU/Memory 요청량이 너무 큽니다
- `10000m CPU, 10Gi Memory` → `100m CPU, 128Mi Memory`

**해결 명령어**:
```bash
kubectl patch deployment resource-hungry -n challenge1 -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"100m","memory":"128Mi"}}}]}}}}'
```

## 🎯 검증

모든 수정 후:
```bash
./verify-success.sh
```
