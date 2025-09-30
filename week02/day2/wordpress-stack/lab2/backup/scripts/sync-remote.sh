#!/bin/bash
source $(dirname $0)/backup-config.conf

LOG_FILE="${BACKUP_ROOT}/logs/sync_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

log "=== Remote sync started ==="

# S3 동기화
log "Starting S3 synchronization..."
if $(dirname $0)/sync-s3.sh >> ${LOG_FILE} 2>&1; then
    log "✅ S3 sync successful"
else
    log "❌ ERROR: S3 sync failed"
fi

# Google Drive 동기화
log "Starting Google Drive synchronization..."
if $(dirname $0)/sync-gdrive.sh >> ${LOG_FILE} 2>&1; then
    log "✅ Google Drive sync successful"
else
    log "❌ ERROR: Google Drive sync failed"
fi

# FTP 동기화
log "Starting FTP synchronization..."
if $(dirname $0)/sync-ftp.sh >> ${LOG_FILE} 2>&1; then
    log "✅ FTP sync successful"
else
    log "❌ ERROR: FTP sync failed"
fi

# 동기화 결과 요약
log "=== Remote sync completed ==="
log "Sync results saved to: ${LOG_FILE}"

# 원격 저장소 상태 확인
echo ""
echo "📊 원격 저장소 상태:"
echo "S3 시뮬레이션 디렉토리:"
ls -la ${BACKUP_ROOT}/../remote/s3/ 2>/dev/null || echo "  없음"
echo "Google Drive 시뮬레이션 디렉토리:"
ls -la ${BACKUP_ROOT}/../remote/gdrive/ 2>/dev/null || echo "  없음"
echo "FTP 시뮬레이션 디렉토리:"
ls -la ${BACKUP_ROOT}/../remote/ftp/ 2>/dev/null || echo "  없음"
