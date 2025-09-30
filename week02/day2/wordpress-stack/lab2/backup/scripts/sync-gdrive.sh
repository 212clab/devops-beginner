#!/bin/bash
source $(dirname $0)/backup-config.conf

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

sync_to_gdrive() {
    log "Starting Google Drive sync..."
    
    # rclone 설치 확인 (시뮬레이션)
    if ! command -v rclone &> /dev/null; then
        log "rclone not found - would install in production"
        log "Simulating Google Drive sync..."
        
        # 시뮬레이션: 로컬 디렉토리에 복사
        mkdir -p ${BACKUP_ROOT}/../remote/gdrive/daily
        
        # Google Drive 동기화 시뮬레이션 (일일 백업만)
        if [ -d "${BACKUP_ROOT}/daily" ] && [ "$(ls -A ${BACKUP_ROOT}/daily)" ]; then
            cp ${BACKUP_ROOT}/daily/* ${BACKUP_ROOT}/../remote/gdrive/daily/ 2>/dev/null || true
            log "Daily backups synced to Google Drive (simulated)"
        fi
    else
        # 실제 rclone 사용
        log "Using rclone for Google Drive sync..."
        
        # Google Drive 동기화 (일일 백업만)
        rclone sync ${BACKUP_ROOT}/daily/ gdrive:${GDRIVE_FOLDER}/daily/ \
            --exclude "*.log" \
            --progress
    fi
    
    log "Google Drive sync completed"
}

sync_to_gdrive
