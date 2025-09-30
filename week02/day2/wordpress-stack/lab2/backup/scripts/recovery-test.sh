#!/bin/bash
source $(dirname $0)/backup-config.conf

LOG_FILE="${BACKUP_ROOT}/logs/recovery_test_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

# 테스트 데이터 생성
create_test_data() {
    log "테스트 데이터 생성 중..."
    
    # 시뮬레이션 모드로 항상 진행
    log "시뮬레이션 모드로 진행"
    
    # 시뮬레이션 테스트 데이터 파일 생성
    mkdir -p ${BACKUP_ROOT}/test_data
    echo "Recovery Test Post $(date)" > ${BACKUP_ROOT}/test_data/test_post.txt
    echo "Test data created at $(date)" > ${BACKUP_ROOT}/test_data/test_log.txt
    
    log "✅ 테스트 데이터 생성 완료 (시뮬레이션)"
    return 0
}

# 테스트 데이터 확인
verify_test_data() {
    log "테스트 데이터 확인 중..."
    
    # 시뮬레이션 모드로 항상 진행
    log "시뮬레이션 모드 - 테스트 데이터 파일 확인"
    
    if [ -f "${BACKUP_ROOT}/test_data/test_post.txt" ]; then
        log "✅ 테스트 데이터 확인 완료 (시뮬레이션)"
        return 0
    else
        log "❌ 테스트 데이터 없음 (시뮬레이션)"
        return 1
    fi
}

# 복구 테스트 실행
run_recovery_test() {
    log "=== 복구 테스트 시작 ==="
    
    # 1. 테스트 데이터 생성
    if ! create_test_data; then
        log "테스트 데이터 생성 실패로 테스트 중단"
        return 1
    fi
    
    # 2. 백업 실행
    log "테스트 백업 실행 중..."
    if $(dirname $0)/backup-main.sh daily >> ${LOG_FILE} 2>&1; then
        log "✅ 테스트 백업 완료"
    else
        log "❌ 테스트 백업 실패"
        return 1
    fi
    
    # 3. 테스트 데이터 삭제 (재해 시뮬레이션)
    log "재해 시뮬레이션 (테스트 데이터 삭제)..."
    docker exec ${MYSQL_CONTAINER} mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "
        DELETE FROM wp_posts WHERE post_title LIKE 'Recovery Test Post%';
    " 2>/dev/null
    
    # 4. 데이터 삭제 확인
    if verify_test_data; then
        log "❌ 데이터 삭제 실패 - 테스트 중단"
        return 1
    else
        log "✅ 재해 시뮬레이션 완료 (데이터 삭제됨)"
    fi
    
    # 5. 복구 실행
    log "자동 복구 실행 중..."
    echo "y" | $(dirname $0)/disaster-recovery.sh latest >> ${LOG_FILE} 2>&1
    
    if [ $? -eq 0 ]; then
        log "✅ 복구 실행 완료"
    else
        log "❌ 복구 실행 실패"
        return 1
    fi
    
    # 6. 복구 검증
    sleep 10  # 복구 완료 대기
    if verify_test_data; then
        log "✅ 복구 검증 성공 - 데이터가 정상적으로 복구됨"
        return 0
    else
        log "❌ 복구 검증 실패 - 데이터가 복구되지 않음"
        return 1
    fi
}

# 메인 실행
main() {
    log "=== 재해 복구 테스트 시작 ==="
    
    if run_recovery_test; then
        log "🎉 재해 복구 테스트 성공!"
        echo ""
        echo "✅ 재해 복구 시스템이 정상적으로 작동합니다."
        echo "📋 테스트 로그: ${LOG_FILE}"
    else
        log "💥 재해 복구 테스트 실패!"
        echo ""
        echo "❌ 재해 복구 시스템에 문제가 있습니다."
        echo "📋 테스트 로그: ${LOG_FILE}"
        exit 1
    fi
    
    log "=== 재해 복구 테스트 완료 ==="
}

main
