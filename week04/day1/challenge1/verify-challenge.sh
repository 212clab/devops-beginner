#!/bin/bash

echo "=== Challenge 1 검증 스크립트 ==="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

total_checks=0
passed_checks=0

# 검증 함수
check_issue() {
    local issue_num=$1
    local description=$2
    local check_command=$3
    local failure_hint=$4
    
    total_checks=$((total_checks + 1))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Issue $issue_num: $description"
    echo ""
    
    if eval "$check_command"; then
        echo -e "${GREEN}✅ Issue $issue_num 해결됨!${NC}"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${RED}❌ Issue $issue_num 아직 해결되지 않음${NC}"
        if [ ! -z "$failure_hint" ]; then
            echo -e "${BLUE}💡 힌트: $failure_hint${NC}"
        fi
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Challenge 1: 마이크로서비스 장애 복구"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Issue 1: Query Service Endpoint 문제
check_issue "1" "Query Service Endpoint 연결" \
    "kubectl get endpoints query-service -n microservices-challenge -o jsonpath='{.subsets[0].addresses[0].ip}' | grep -q '[0-9]'" \
    "Service 셀렉터와 Pod 라벨이 일치하지 않습니다. broken-cqrs.yaml 확인 필요"

echo ""

# Issue 2: CronJob 스케줄 문제
check_issue "2" "Event Processor CronJob 스케줄" \
    "kubectl get cronjob event-processor -n microservices-challenge -o jsonpath='{.spec.schedule}' | grep -qE '^0 \\*/1 \\* \\* \\*$|^\\*/30 \\* \\* \\* \\*$'" \
    "CronJob 스케줄이 너무 자주 실행됩니다. broken-eventsourcing.yaml 확인 필요"

echo ""

# Issue 3: Saga ConfigMap URL 문제
check_issue "3" "Saga Orchestrator 성공 실행" \
    "kubectl get job saga-orchestrator -n microservices-challenge -o jsonpath='{.status.succeeded}' 2>/dev/null | grep -q '1'" \
    "Saga Job이 없거나 실패했습니다. broken-saga.yaml의 ConfigMap과 Job 확인 필요"

echo ""

# Issue 4: Ingress 백엔드 문제
check_issue "4" "Ingress User Service 라우팅" \
    "[[ \$(kubectl get ingress ecommerce-ingress -n microservices-challenge -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null) == 'user-service' ]]" \
    "Ingress 백엔드 서비스 이름이 잘못되었습니다. broken-networking.yaml 확인 필요"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 검증 결과"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "총 검사 항목: $total_checks"
echo "통과한 항목: $passed_checks"
echo "실패한 항목: $((total_checks - passed_checks))"
echo ""

if [ $passed_checks -eq $total_checks ]; then
    echo -e "${GREEN}🎉 축하합니다! 모든 문제를 해결했습니다! 🎉${NC}"
    echo ""
    echo "📚 학습 완료 내용:"
    echo "  ✅ Service 셀렉터와 Endpoint 연결"
    echo "  ✅ CronJob 스케줄 설정"
    echo "  ✅ Kubernetes DNS와 FQDN"
    echo "  ✅ Ingress 라우팅 설정"
    exit 0
else
    echo -e "${YELLOW}💪 아직 $(($total_checks - passed_checks))개의 문제가 남아있습니다. 계속 도전하세요!${NC}"
    echo ""
    echo "📖 도움말:"
    echo "  - solutions.md 파일을 참고하세요"
    echo "  - hints.md 파일에서 추가 힌트를 확인하세요"
    echo "  - kubectl describe로 리소스 상태를 확인하세요"
    exit 1
fi
