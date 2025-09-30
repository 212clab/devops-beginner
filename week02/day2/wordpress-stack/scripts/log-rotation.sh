#!/bin/bash

LOG_DIR="/logs"
BACKUP_DIR="/backup/logs"
RETENTION_DAYS=30

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== 로그 로테이션 시작 ==="

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR

# 30일 이상 된 로그 파일 압축 및 이동
find $LOG_DIR -name "*.log" -mtime +7 -exec gzip {} \;
find $LOG_DIR -name "*.log.gz" -mtime +$RETENTION_DAYS -exec mv {} $BACKUP_DIR/ \;

# 90일 이상 된 백업 로그 삭제
find $BACKUP_DIR -name "*.log.gz" -mtime +90 -delete

# Docker 로그 정리 (컨테이너별 최대 10MB, 최대 3개 파일)
docker system prune -f --volumes

log "=== 로그 로테이션 완료 ==="
