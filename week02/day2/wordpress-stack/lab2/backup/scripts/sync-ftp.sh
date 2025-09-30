#!/bin/bash
source $(dirname $0)/backup-config.conf

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

sync_to_ftp() {
    log "Starting FTP sync..."
    
    # FTP 시뮬레이션
    log "FTP sync simulation - would upload to ${FTP_HOST}"
    
    # 시뮬레이션: 로컬 디렉토리에 복사
    mkdir -p ${BACKUP_ROOT}/../remote/ftp/offsite
    
    # 주간 백업을 FTP로 전송 시뮬레이션
    if [ -d "${BACKUP_ROOT}/weekly" ] && [ "$(ls -A ${BACKUP_ROOT}/weekly)" ]; then
        cp ${BACKUP_ROOT}/weekly/* ${BACKUP_ROOT}/../remote/ftp/offsite/ 2>/dev/null || true
        log "Weekly backups synced to FTP (simulated)"
    fi
    
    log "FTP sync completed"
}

sync_to_ftp
