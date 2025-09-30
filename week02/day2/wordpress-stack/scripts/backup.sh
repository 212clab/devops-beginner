#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /logs/backup.log
}

log "=== 백업 시작 ==="

# 데이터베이스 백업
log "데이터베이스 백업 중..."
docker exec mysql-wordpress mysqldump \
  --single-transaction \
  --routines \
  --triggers \
  --add-drop-database \
  --databases wordpress \
  -u wpuser -pwppassword \
  > ${BACKUP_DIR}/daily/wordpress_db_${BACKUP_DATE}.sql

if [ $? -eq 0 ]; then
    gzip ${BACKUP_DIR}/daily/wordpress_db_${BACKUP_DATE}.sql
    log "✅ 데이터베이스 백업 완료"
else
    log "❌ 데이터베이스 백업 실패"
    exit 1
fi

# WordPress 파일 백업
log "WordPress 파일 백업 중..."
docker run --rm \
  -v wp-content:/data:ro \
  -v $(pwd)/backup/daily:/backup \
  alpine tar czf /backup/wp_content_${BACKUP_DATE}.tar.gz -C /data .

if [ $? -eq 0 ]; then
    log "✅ WordPress 파일 백업 완료"
else
    log "❌ WordPress 파일 백업 실패"
    exit 1
fi

# 설정 파일 백업
log "설정 파일 백업 중..."
tar czf ${BACKUP_DIR}/daily/config_${BACKUP_DATE}.tar.gz config/

# 백업 검증
log "백업 무결성 검증 중..."
cd ${BACKUP_DIR}/daily
md5sum *_${BACKUP_DATE}.* > checksums_${BACKUP_DATE}.md5

log "=== 백업 완료 ==="
log "백업 파일 위치: ${BACKUP_DIR}/daily/"
ls -la ${BACKUP_DIR}/daily/*_${BACKUP_DATE}.*
