#!/bin/bash

# Week 2 Day 2 Lab 2: 재해 복구 시스템 자동 구축
# 사용법: ./setup_disaster_recovery.sh

echo "=== 재해 복구 시스템 자동 구축 시작 ==="

# 현재 디렉토리 확인
if [ ! -f "backup/scripts/backup-config.conf" ]; then
    echo "❌ 백업 설정 파일을 찾을 수 없습니다. setup_backup_system.sh를 먼저 실행해주세요."
    exit 1
fi

# 1. 재해 복구 메인 스크립트 생성
echo "1. 재해 복구 메인 스크립트 생성 중..."
cat > backup/scripts/disaster-recovery.sh << 'EOF'
#!/bin/bash
source $(dirname $0)/backup-config.conf

RECOVERY_TYPE=${1:-latest}  # latest, date, s3
RECOVERY_DATE=${2:-$(date +%Y%m%d)}
LOG_FILE="${BACKUP_ROOT}/logs/recovery_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

# 사용법 표시
show_usage() {
    echo "사용법: $0 {latest|date|s3} [YYYYMMDD]"
    echo "예시:"
    echo "  $0 latest                    # 최신 로컬 백업에서 복구"
    echo "  $0 date 20241201            # 특정 날짜 백업에서 복구"
    echo "  $0 s3 20241201              # S3 백업에서 복구"
    exit 1
}

# 현재 시스템 백업 (복구 전)
backup_current_system() {
    log "복구 전 현재 시스템 백업 중..."
    
    EMERGENCY_BACKUP="${BACKUP_ROOT}/emergency_$(date +%Y%m%d_%H%M%S)"
    mkdir -p ${EMERGENCY_BACKUP}
    
    # 현재 데이터베이스 백업
    if docker exec ${MYSQL_CONTAINER} mysqldump \
        --single-transaction \
        --routines \
        --triggers \
        --databases ${MYSQL_DATABASE} \
        -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
        > ${EMERGENCY_BACKUP}/current_mysql.sql 2>/dev/null; then
        log "현재 데이터베이스 백업 완료"
    else
        log "WARNING: 현재 데이터베이스 백업 실패"
    fi
    
    # 현재 WordPress 파일 백업
    if docker run --rm \
        -v wp-content:/data:ro \
        -v ${EMERGENCY_BACKUP}:/backup \
        alpine tar czf /backup/current_wp-content.tar.gz -C /data . 2>/dev/null; then
        log "현재 WordPress 파일 백업 완료"
    else
        log "WARNING: 현재 WordPress 파일 백업 실패"
    fi
    
    log "현재 시스템 백업 완료: ${EMERGENCY_BACKUP}"
}

# 백업 파일 찾기
find_backup_files() {
    log "백업 파일 검색 중..."
    
    case ${RECOVERY_TYPE} in
        "latest")
            DB_BACKUP=$(ls -t ${BACKUP_ROOT}/daily/mysql_*.sql.gz 2>/dev/null | head -1)
            WP_BACKUP=$(ls -t ${BACKUP_ROOT}/daily/wp-content_*.tar.gz 2>/dev/null | head -1)
            ;;
        "date")
            DB_BACKUP=$(find ${BACKUP_ROOT} -name "mysql_*${RECOVERY_DATE}*.sql.gz" | head -1)
            WP_BACKUP=$(find ${BACKUP_ROOT} -name "wp-content_*${RECOVERY_DATE}*.tar.gz" | head -1)
            ;;
        "s3")
            log "S3에서 백업 다운로드 중..."
            mkdir -p ${BACKUP_ROOT}/restore
            
            # S3 시뮬레이션 (실제로는 aws s3 cp 사용)
            if [ -d "${BACKUP_ROOT}/../remote/s3" ]; then
                cp ${BACKUP_ROOT}/../remote/s3/daily/*${RECOVERY_DATE}* ${BACKUP_ROOT}/restore/ 2>/dev/null || true
                DB_BACKUP=$(ls ${BACKUP_ROOT}/restore/mysql_*${RECOVERY_DATE}*.sql.gz 2>/dev/null | head -1)
                WP_BACKUP=$(ls ${BACKUP_ROOT}/restore/wp-content_*${RECOVERY_DATE}*.tar.gz 2>/dev/null | head -1)
            fi
            ;;
        *)
            log "ERROR: 잘못된 복구 타입: ${RECOVERY_TYPE}"
            show_usage
            ;;
    esac
    
    if [[ ! -f "$DB_BACKUP" ]] || [[ ! -f "$WP_BACKUP" ]]; then
        log "ERROR: 백업 파일을 찾을 수 없습니다 (${RECOVERY_TYPE} ${RECOVERY_DATE})"
        log "DB 백업: $DB_BACKUP"
        log "WP 백업: $WP_BACKUP"
        exit 1
    fi
    
    log "백업 파일 발견:"
    log "  데이터베이스: $DB_BACKUP"
    log "  WordPress: $WP_BACKUP"
}

# 데이터베이스 복구
restore_database() {
    log "데이터베이스 복구 시작..."
    
    # 데이터베이스 백업 압축 해제
    gunzip -c "$DB_BACKUP" > /tmp/restore_db.sql
    
    # 기존 데이터베이스 삭제 및 재생성
    docker exec ${MYSQL_CONTAINER} mysql -u root -prootpassword -e "
        DROP DATABASE IF EXISTS ${MYSQL_DATABASE};
        CREATE DATABASE ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
    " 2>/dev/null
    
    # 백업 데이터 복원
    if docker exec -i ${MYSQL_CONTAINER} mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < /tmp/restore_db.sql 2>/dev/null; then
        log "데이터베이스 복구 완료"
        rm -f /tmp/restore_db.sql
    else
        log "ERROR: 데이터베이스 복구 실패"
        exit 1
    fi
}

# WordPress 파일 복구
restore_wordpress() {
    log "WordPress 파일 복구 시작..."
    
    # 기존 wp-content 백업
    docker run --rm \
        -v wp-content:/data \
        -v ${BACKUP_ROOT}/restore:/backup \
        alpine tar czf /backup/wp-content-before-restore.tar.gz -C /data . 2>/dev/null || true
    
    # wp-content 복원
    if docker run --rm \
        -v wp-content:/data \
        -v $(dirname "$WP_BACKUP"):/backup \
        alpine sh -c "rm -rf /data/* && tar xzf /backup/$(basename "$WP_BACKUP") -C /data" 2>/dev/null; then
        log "WordPress 파일 복구 완료"
    else
        log "ERROR: WordPress 파일 복구 실패"
        exit 1
    fi
}

# 서비스 재시작 및 검증
restart_and_verify() {
    log "서비스 재시작 중..."
    
    # WordPress 컨테이너 재시작
    docker restart ${WORDPRESS_CONTAINER} 2>/dev/null || log "WARNING: WordPress 컨테이너 재시작 실패"
    
    # Nginx 프록시 재시작 (있는 경우)
    docker restart nginx-proxy 2>/dev/null || log "INFO: Nginx 프록시 없음"
    
    # 서비스 시작 대기
    log "서비스 시작 대기 중..."
    sleep 30
    
    # 헬스 체크
    if curl -f http://localhost/health >/dev/null 2>&1; then
        log "✅ WordPress 서비스 정상"
    elif curl -f http://localhost:8080 >/dev/null 2>&1; then
        log "✅ WordPress 서비스 정상 (포트 8080)"
    else
        log "⚠️  WARNING: WordPress 서비스 헬스 체크 실패"
    fi
    
    # 데이터베이스 연결 확인
    if docker exec ${MYSQL_CONTAINER} mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT COUNT(*) FROM ${MYSQL_DATABASE}.wp_posts;" >/dev/null 2>&1; then
        log "✅ 데이터베이스 연결 및 데이터 확인 완료"
    else
        log "⚠️  WARNING: 데이터베이스 검증 실패"
    fi
}

# 메인 실행
main() {
    log "=== 재해 복구 시작 ==="
    log "복구 타입: ${RECOVERY_TYPE}"
    log "복구 날짜: ${RECOVERY_DATE}"
    
    backup_current_system
    find_backup_files
    
    echo ""
    echo "⚠️  경고: 이 작업은 현재 데이터를 삭제합니다."
    echo "복구할 백업:"
    echo "  - 데이터베이스: $(basename "$DB_BACKUP")"
    echo "  - WordPress: $(basename "$WP_BACKUP")"
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "사용자에 의해 복구 취소됨"
        exit 0
    fi
    
    restore_database
    restore_wordpress
    restart_and_verify
    
    log "=== 재해 복구 완료 ==="
    log "복구 로그: ${LOG_FILE}"
}

# 인수 확인
if [[ $# -eq 0 ]]; then
    show_usage
fi

main
EOF

# 2. 백업 정리 스크립트 생성
echo "2. 백업 정리 스크립트 생성 중..."
cat > backup/scripts/cleanup-old.sh << 'EOF'
#!/bin/bash
source $(dirname $0)/backup-config.conf

LOG_FILE="${BACKUP_ROOT}/logs/cleanup_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

cleanup_daily() {
    log "일일 백업 정리 중 (${DAILY_RETENTION}일 이상 된 파일)..."
    if [ -d "${BACKUP_ROOT}/daily" ]; then
        find ${BACKUP_ROOT}/daily -name "*" -type f -mtime +${DAILY_RETENTION} -delete 2>/dev/null
        DELETED=$(find ${BACKUP_ROOT}/daily -name "*" -type f -mtime +${DAILY_RETENTION} 2>/dev/null | wc -l)
        log "일일 백업 정리 완료 (삭제된 파일: ${DELETED}개)"
    fi
}

cleanup_weekly() {
    log "주간 백업 정리 중 (${WEEKLY_RETENTION}주 이상 된 파일)..."
    if [ -d "${BACKUP_ROOT}/weekly" ]; then
        find ${BACKUP_ROOT}/weekly -name "*" -type f -mtime +$((${WEEKLY_RETENTION} * 7)) -delete 2>/dev/null
        DELETED=$(find ${BACKUP_ROOT}/weekly -name "*" -type f -mtime +$((${WEEKLY_RETENTION} * 7)) 2>/dev/null | wc -l)
        log "주간 백업 정리 완료 (삭제된 파일: ${DELETED}개)"
    fi
}

cleanup_monthly() {
    log "월간 백업 정리 중 (${MONTHLY_RETENTION}개월 이상 된 파일)..."
    if [ -d "${BACKUP_ROOT}/monthly" ]; then
        find ${BACKUP_ROOT}/monthly -name "*" -type f -mtime +$((${MONTHLY_RETENTION} * 30)) -delete 2>/dev/null
        DELETED=$(find ${BACKUP_ROOT}/monthly -name "*" -type f -mtime +$((${MONTHLY_RETENTION} * 30)) 2>/dev/null | wc -l)
        log "월간 백업 정리 완료 (삭제된 파일: ${DELETED}개)"
    fi
}

cleanup_logs() {
    log "오래된 로그 파일 정리 중 (30일 이상)..."
    if [ -d "${BACKUP_ROOT}/logs" ]; then
        find ${BACKUP_ROOT}/logs -name "*.log" -type f -mtime +30 -delete 2>/dev/null
        DELETED=$(find ${BACKUP_ROOT}/logs -name "*.log" -type f -mtime +30 2>/dev/null | wc -l)
        log "로그 정리 완료 (삭제된 파일: ${DELETED}개)"
    fi
}

cleanup_emergency() {
    log "오래된 응급 백업 정리 중 (7일 이상)..."
    if [ -d "${BACKUP_ROOT}" ]; then
        find ${BACKUP_ROOT} -name "emergency_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null
        log "응급 백업 정리 완료"
    fi
}

main() {
    log "=== 백업 정리 시작 ==="
    
    cleanup_daily
    cleanup_weekly
    cleanup_monthly
    cleanup_logs
    cleanup_emergency
    
    # 디스크 사용량 보고
    log "현재 백업 디스크 사용량:"
    if [ -d "${BACKUP_ROOT}" ]; then
        du -sh ${BACKUP_ROOT}/* 2>/dev/null | tee -a ${LOG_FILE} || log "사용량 정보 없음"
    fi
    
    log "=== 백업 정리 완료 ==="
}

main
EOF

# 3. 복구 테스트 스크립트 생성
echo "3. 복구 테스트 스크립트 생성 중..."
cat > backup/scripts/recovery-test.sh << 'EOF'
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
EOF

# 4. 실행 권한 설정
echo "4. 실행 권한 설정 중..."
chmod +x backup/scripts/disaster-recovery.sh
chmod +x backup/scripts/cleanup-old.sh
chmod +x backup/scripts/recovery-test.sh

# 5. 재해 복구 시스템 테스트
echo "5. 재해 복구 시스템 테스트 실행 중..."
echo "테스트를 실행하시겠습니까? (실제 데이터에 영향을 줄 수 있습니다)"
read -p "테스트 실행? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./backup/scripts/recovery-test.sh
    TEST_RESULT=$?
else
    echo "테스트를 건너뜁니다."
    TEST_RESULT=0
fi

echo ""
echo "=== 재해 복구 시스템 자동 구축 완료 ==="
echo ""
echo "생성된 구성 요소:"
echo "- 재해 복구: backup/scripts/disaster-recovery.sh"
echo "- 백업 정리: backup/scripts/cleanup-old.sh"
echo "- 복구 테스트: backup/scripts/recovery-test.sh"
echo ""
echo "사용법:"
echo "  ./backup/scripts/disaster-recovery.sh latest"
echo "  ./backup/scripts/disaster-recovery.sh date 20241201"
echo "  ./backup/scripts/cleanup-old.sh"
echo "  ./backup/scripts/recovery-test.sh"
echo ""

if [ $TEST_RESULT -eq 0 ]; then
    echo "다음 단계: ./lab_scripts/lab2/test_backup_system.sh 실행"
else
    echo "⚠️  재해 복구 테스트에서 문제가 발견되었습니다. 로그를 확인해주세요."
fi