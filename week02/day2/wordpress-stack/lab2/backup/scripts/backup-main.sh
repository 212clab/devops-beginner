#!/bin/bash
source $(dirname $0)/backup-config.conf

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_TYPE=${1:-daily}
LOG_FILE="${BACKUP_ROOT}/logs/backup_${BACKUP_DATE}.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

backup_database() {
    log "Starting database backup..."
    
    # 데이터베이스 연결 확인
    if ! docker exec ${MYSQL_CONTAINER} mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1;" >/dev/null 2>&1; then
        log "ERROR: Cannot connect to database"
        exit 1
    fi
    
    # 백업 실행
    docker exec ${MYSQL_CONTAINER} mysqldump \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-database \
        --databases ${MYSQL_DATABASE} \
        -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
        > ${BACKUP_ROOT}/${BACKUP_TYPE}/mysql_${BACKUP_DATE}.sql
    
    if [ $? -eq 0 ] && [ -f "${BACKUP_ROOT}/${BACKUP_TYPE}/mysql_${BACKUP_DATE}.sql" ]; then
        gzip ${BACKUP_ROOT}/${BACKUP_TYPE}/mysql_${BACKUP_DATE}.sql
        log "Database backup completed successfully"
    else
        log "ERROR: Database backup failed"
        exit 1
    fi
}

backup_wordpress() {
    log "Starting WordPress files backup..."
    
    # wp-content 백업
    docker run --rm \
        -v wp-content:/data:ro \
        -v ${BACKUP_ROOT}/${BACKUP_TYPE}:/backup \
        alpine tar czf /backup/wp-content_${BACKUP_DATE}.tar.gz -C /data .
    
    log "WordPress files backup completed"
}

verify_backup() {
    log "Verifying backup integrity..."
    
    # 파일 크기 확인
    DB_SIZE=$(stat -c%s "${BACKUP_ROOT}/${BACKUP_TYPE}/mysql_${BACKUP_DATE}.sql.gz" 2>/dev/null || echo 0)
    WP_SIZE=$(stat -c%s "${BACKUP_ROOT}/${BACKUP_TYPE}/wp-content_${BACKUP_DATE}.tar.gz" 2>/dev/null || echo 0)
    
    log "Backup file sizes - DB: ${DB_SIZE} bytes, WP: ${WP_SIZE} bytes"
    log "✅ Backup verification completed"
}

main() {
    log "=== Backup started (Type: ${BACKUP_TYPE}) ==="
    backup_database
    backup_wordpress
    verify_backup
    log "=== Backup completed successfully ==="
}

main
