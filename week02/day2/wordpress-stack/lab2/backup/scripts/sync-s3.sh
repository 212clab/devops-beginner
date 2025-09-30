#!/bin/bash
source $(dirname $0)/backup-config.conf

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

sync_to_s3() {
    log "Starting S3 sync..."
    
    # AWS CLI 설치 확인 (시뮬레이션)
    if ! command -v aws &> /dev/null; then
        log "AWS CLI not found - would install in production"
        log "Simulating S3 sync..."
        
        # 시뮬레이션: 로컬 디렉토리에 복사
        mkdir -p ${BACKUP_ROOT}/../remote/s3/{daily,weekly,monthly}
        
        # 일일 백업 시뮬레이션
        if [ -d "${BACKUP_ROOT}/daily" ] && [ "$(ls -A ${BACKUP_ROOT}/daily)" ]; then
            cp ${BACKUP_ROOT}/daily/* ${BACKUP_ROOT}/../remote/s3/daily/ 2>/dev/null || true
            log "Daily backups synced to S3 (simulated)"
        fi
        
        # 주간 백업 시뮬레이션
        if [ -d "${BACKUP_ROOT}/weekly" ] && [ "$(ls -A ${BACKUP_ROOT}/weekly)" ]; then
            cp ${BACKUP_ROOT}/weekly/* ${BACKUP_ROOT}/../remote/s3/weekly/ 2>/dev/null || true
            log "Weekly backups synced to S3 (simulated)"
        fi
        
        # 월간 백업 시뮬레이션
        if [ -d "${BACKUP_ROOT}/monthly" ] && [ "$(ls -A ${BACKUP_ROOT}/monthly)" ]; then
            cp ${BACKUP_ROOT}/monthly/* ${BACKUP_ROOT}/../remote/s3/monthly/ 2>/dev/null || true
            log "Monthly backups synced to S3 (simulated)"
        fi
    else
        # 실제 AWS CLI 사용
        log "Using AWS CLI for S3 sync..."
        
        # 일일 백업 동기화
        aws s3 sync ${BACKUP_ROOT}/daily/ s3://${S3_BUCKET}/daily/ \
            --exclude "*.log" \
            --storage-class STANDARD_IA
        
        # 주간 백업 동기화
        aws s3 sync ${BACKUP_ROOT}/weekly/ s3://${S3_BUCKET}/weekly/ \
            --exclude "*.log" \
            --storage-class GLACIER
        
        # 월간 백업 동기화
        aws s3 sync ${BACKUP_ROOT}/monthly/ s3://${S3_BUCKET}/monthly/ \
            --exclude "*.log" \
            --storage-class DEEP_ARCHIVE
    fi
    
    log "S3 sync completed"
}

sync_to_s3
