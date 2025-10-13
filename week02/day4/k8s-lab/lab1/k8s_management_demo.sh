#!/bin/bash

# Week 2 Day 4 Lab 1: Kubernetes 관리 명령어 실습 스크립트
# 사용법: ./k8s_management_demo.sh

echo "=== Kubernetes 관리 명령어 실습 시작 ==="
echo ""

# 1. 클러스터 연결 확인
echo "1. 클러스터 연결 확인 중..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes 클러스터에 연결할 수 없습니다."
    exit 1
fi
echo "✅ 클러스터 연결 확인 완료"
echo ""

# 2. 현재 상태 개요
echo "2. 현재 클러스터 상태 개요..."
echo ""
echo "=== 클러스터 정보 ==="
kubectl cluster-info
echo ""
echo "=== 노드 상태 ==="
kubectl get nodes -o wide
echo ""
echo "=== 네임스페이스 목록 ==="
kubectl get namespaces
echo ""

# 3. Pod 관리 명령어 실습
echo "3. Pod 관리 명령어 실습..."
echo ""
echo "=== Pod 목록 확인 ==="
kubectl get pods -n lab-demo -o wide
echo ""

echo "=== Pod 상세 정보 (첫 번째 Pod) ==="
POD_NAME=$(kubectl get pods -n lab-demo -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    echo "Pod 이름: $POD_NAME"
    kubectl describe pod $POD_NAME -n lab-demo | head -30
    echo "..."
    echo ""
    
    echo "=== Pod 로그 확인 (최근 10줄) ==="
    kubectl logs $POD_NAME -n lab-demo --tail=10
    echo ""
    
    echo "=== Pod 내부 명령어 실행 ==="
    echo "nginx 버전 확인:"
    kubectl exec $POD_NAME -n lab-demo -- nginx -v
    echo ""
    echo "설정 파일 확인:"
    kubectl exec $POD_NAME -n lab-demo -- cat /etc/nginx/conf.d/default.conf | head -10
    echo "..."
else
    echo "❌ nginx Pod를 찾을 수 없습니다."
fi
echo ""

# 4. Service 관리 명령어 실습
echo "4. Service 관리 명령어 실습..."
echo ""
echo "=== Service 목록 ==="
kubectl get svc -n lab-demo
echo ""

echo "=== Service 상세 정보 ==="
kubectl describe svc nginx-service -n lab-demo
echo ""

echo "=== Endpoints 확인 ==="
kubectl get endpoints -n lab-demo
echo ""

echo "=== Service 연결 테스트 ==="
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
    echo "✅ Service 연결 성공: $HEALTH_RESPONSE"
else
    echo "❌ Service 연결 실패 (포트 포워딩 확인 필요)"
fi
echo ""

# 5. Deployment 관리 명령어 실습
echo "5. Deployment 관리 명령어 실습..."
echo ""
echo "=== Deployment 상태 확인 ==="
kubectl get deployment nginx-deployment -n lab-demo -o wide
echo ""

echo "=== Deployment 상세 정보 ==="
kubectl describe deployment nginx-deployment -n lab-demo | head -20
echo "..."
echo ""

echo "=== ReplicaSet 확인 ==="
kubectl get replicaset -n lab-demo
echo ""

# 6. 스케일링 실습
echo "6. 스케일링 실습..."
echo ""
echo "현재 Pod 수: $(kubectl get pods -n lab-demo -l app=nginx --no-headers | wc -l)"
echo ""

echo "=== 스케일 업 (5개로 증가) ==="
kubectl scale deployment nginx-deployment --replicas=5 -n lab-demo
echo "스케일링 명령 실행됨"
echo ""

echo "스케일링 진행 상황 (10초 대기)..."
sleep 10
kubectl get pods -n lab-demo -l app=nginx
echo ""

echo "=== 스케일 다운 (원래 크기로 복원) ==="
kubectl scale deployment nginx-deployment --replicas=3 -n lab-demo
echo "스케일링 명령 실행됨"
echo ""

echo "스케일링 진행 상황 (10초 대기)..."
sleep 10
kubectl get pods -n lab-demo -l app=nginx
echo ""

# 7. 롤아웃 관리 실습
echo "7. 롤아웃 관리 실습..."
echo ""
echo "=== 배포 히스토리 확인 ==="
kubectl rollout history deployment/nginx-deployment -n lab-demo
echo ""

echo "=== 현재 롤아웃 상태 ==="
kubectl rollout status deployment/nginx-deployment -n lab-demo
echo ""

# 8. ConfigMap 관리 실습
echo "8. ConfigMap 관리 실습..."
echo ""
echo "=== ConfigMap 목록 ==="
kubectl get configmap -n lab-demo
echo ""

echo "=== ConfigMap 내용 확인 (일부) ==="
kubectl get configmap nginx-config -n lab-demo -o yaml | head -20
echo "..."
echo ""

# 9. 리소스 사용량 확인 (가능한 경우)
echo "9. 리소스 사용량 확인..."
echo ""
echo "=== 노드 리소스 사용량 ==="
if kubectl top nodes &> /dev/null; then
    kubectl top nodes
else
    echo "Metrics Server가 설치되지 않아 리소스 사용량을 확인할 수 없습니다."
fi
echo ""

echo "=== Pod 리소스 사용량 ==="
if kubectl top pods -n lab-demo &> /dev/null; then
    kubectl top pods -n lab-demo
else
    echo "Metrics Server가 설치되지 않아 Pod 리소스 사용량을 확인할 수 없습니다."
fi
echo ""

# 10. 이벤트 확인
echo "10. 클러스터 이벤트 확인..."
echo ""
echo "=== 최근 이벤트 (lab-demo 네임스페이스) ==="
kubectl get events -n lab-demo --sort-by='.lastTimestamp' | tail -10
echo ""

# 11. 네트워크 연결 테스트
echo "11. 네트워크 연결 테스트..."
echo ""
echo "=== 서비스 디스커버리 테스트 ==="
echo "임시 Pod를 생성하여 서비스 연결을 테스트합니다..."

# 테스트 Pod 생성 및 실행
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -n lab-demo -- sh -c "
echo '=== DNS 해상도 테스트 ==='
nslookup nginx-service
echo ''
echo '=== HTTP 연결 테스트 ==='
wget -qO- nginx-service/health
echo ''
echo '=== 서비스 엔드포인트 테스트 ==='
wget -qO- nginx-service:80/health
echo ''
" 2>/dev/null || echo "테스트 Pod 실행 중 오류 발생"

echo ""

# 12. 유용한 명령어 모음
echo "12. 유용한 kubectl 명령어 모음..."
echo ""
echo "=== 자주 사용하는 명령어 ==="
echo "# 모든 리소스 확인"
echo "kubectl get all -n lab-demo"
echo ""
echo "# Pod 로그 실시간 모니터링"
echo "kubectl logs -f -l app=nginx -n lab-demo"
echo ""
echo "# Pod 내부 접근"
echo "kubectl exec -it <pod-name> -n lab-demo -- /bin/sh"
echo ""
echo "# 포트 포워딩"
echo "kubectl port-forward svc/nginx-service 8080:80 -n lab-demo"
echo ""
echo "# 리소스 상세 정보"
echo "kubectl describe <resource-type> <resource-name> -n lab-demo"
echo ""
echo "# 리소스 YAML 출력"
echo "kubectl get <resource-type> <resource-name> -n lab-demo -o yaml"
echo ""

# 13. 포트 포워딩 상태 확인 및 복구
echo "13. 포트 포워딩 상태 확인 및 복구..."
echo ""

# 포트 포워딩 상태 확인
echo "=== 포트 포워딩 상태 확인 ==="
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ 포트 포워딩 정상 동작 중"
else
    echo "❌ 포트 포워딩 연결 끊어짐 - 복구 중..."
    
    # 기존 포트 포워딩 프로세스 종료
    pkill -f "kubectl port-forward.*nginx-service.*8080:80" 2>/dev/null || true
    sleep 2
    
    # 새로운 포트 포워딩 시작
    echo "새로운 포트 포워딩 시작..."
    kubectl port-forward svc/nginx-service 8080:80 -n lab-demo > /dev/null 2>&1 &
    
    # 연결 대기 (최대 10초)
    for i in {1..10}; do
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            echo "✅ 포트 포워딩 복구 완료 ($i초 소요)"
            break
        fi
        sleep 1
    done
    
    # 최종 확인
    if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "❌ 포트 포워딩 복구 실패"
        echo "수동 복구 명령어: kubectl port-forward svc/nginx-service 8080:80 -n lab-demo &"
    fi
fi
echo ""

# 14. 현재 상태 최종 확인
echo "14. 현재 상태 최종 확인..."
echo ""
echo "=== 전체 리소스 상태 ==="
kubectl get all -n lab-demo
echo ""

echo "=== 서비스 접근 테스트 ==="
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ 웹 서비스 정상 접근 가능"
    echo "페이지 제목: $(curl -s http://localhost:8080 | grep -o '<title>.*</title>' | head -1)"
    if curl -s http://localhost:8080/info > /dev/null 2>&1; then
        echo "서버 정보: $(curl -s http://localhost:8080/info | head -1)"
    fi
else
    echo "❌ 웹 서비스 접근 불가"
    echo "포트 포워딩 수동 복구: ./lab_scripts/lab1/ensure_port_forward.sh"
fi
echo ""

# 14. 완료 요약
echo "=== Kubernetes 관리 명령어 실습 완료 ==="
echo ""
echo "✅ 실습 완료 항목:"
echo "- Pod 관리 명령어 (get, describe, logs, exec)"
echo "- Service 관리 명령어 (get, describe, endpoints)"
echo "- Deployment 관리 명령어 (get, describe, scale)"
echo "- 롤아웃 관리 (history, status)"
echo "- ConfigMap 관리 (get, describe)"
echo "- 네트워크 연결 테스트 (DNS, HTTP)"
echo "- 리소스 모니터링 및 이벤트 확인"
echo ""
echo "🔧 핵심 학습 포인트:"
echo "- kubectl 기본 명령어 구조와 옵션"
echo "- Kubernetes 리소스 간의 관계"
echo "- 서비스 디스커버리와 네트워킹"
echo "- 스케일링과 롤아웃 관리"
echo "- 디버깅과 트러블슈팅 방법"
echo ""
echo "📚 추가 학습 권장 명령어:"
echo "- kubectl explain <resource-type>"
echo "- kubectl api-resources"
echo "- kubectl config view"
echo "- kubectl cluster-info dump"
echo ""
echo "다음 단계:"
echo "- test_k8s_environment.sh 실행으로 종합 테스트"
echo "- 브라우저에서 http://localhost:8080 최종 확인"
echo ""
echo "🎉 Kubernetes 관리 명령어 실습이 성공적으로 완료되었습니다!"