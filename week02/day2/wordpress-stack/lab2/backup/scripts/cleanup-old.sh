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
