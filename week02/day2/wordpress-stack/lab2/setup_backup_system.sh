#!/bin/bash

# Week 2 Day 2 Lab 2: 백업 시스템 자동 구축
# 사용법: ./setup_backup_system.sh

echo "=== 백업 시스템 자동 구축 시작 ==="

# 현재 디렉토리에서 바로 작업
echo "현재 디렉토리: $(pwd)"
echo "백업 시스템을 $(pwd)에 구축합니다."
echo "작업 위치: $(pwd)/backup/"

# 1. 디렉토리 구조 생성
echo "1. 백업 디렉토리 구조 생성 중..."
mkdir -p backup/daily
mkdir -p backup/weekly
mkdir -p backup/monthly
mkdir -p backup/scripts
mkdir -p backup/logs
mkdir -p backup/restore
mkdir -p remote/s3
mkdir -p remote/gdrive
mkdir -p remote/ftp
echo "✅ 디렉토리 구조 생성 완료"

# 2. 백업 설정 파일 생성
echo "2. 백업 설정 파일 생성 중..."
cat > backup/scripts/backup-config.conf << 'EOF'
# 백업 설정
BACKUP_ROOT="$(pwd)/backup"
MYSQL_CONTAINER="mysql-wordpress"
WORDPRESS_CONTAINER="wordpress-app"
MYSQL_USER="wpuser"
MYSQL_PASSWORD="wppassword"
MYSQL_DATABASE="wordpress"

# 보관 정책
DAILY_RETENTION=7
WEEKLY_RETENTION=4
MONTHLY_RETENTION=12

# 원격 저장소
S3_BUCKET="company-wordpress-backup"
S3_REGION="ap-northeast-2"
GDRIVE_FOLDER="WordPress_Backups"
FTP_HOST="backup.company.com"
FTP_USER="backup_user"
EOF
echo "✅ 설정 파일 생성 완료"

# 3. 메인 백업 스크립트 생성
echo "3. 메인 백업 스크립트 생성 중..."
cat > backup/scripts/backup-main.sh << 'EOF'
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
EOF
echo "✅ 메인 백업 스크립트 생성 완료"

# 4. Cron 설정 스크립트 생성
echo "4. Cron 스케줄 설정 스크립트 생성 중..."
cat > backup/scripts/setup-cron.sh << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 현재 crontab 백업
crontab -l > /tmp/crontab.backup 2>/dev/null || touch /tmp/crontab.backup

# 기존 WordPress 백업 작업 제거
grep -v "WordPress 백업" /tmp/crontab.backup > /tmp/crontab.new
grep -v "backup-main.sh" /tmp/crontab.new > /tmp/crontab.backup

# 새로운 cron 작업 추가
cat >> /tmp/crontab.backup << CRON
# WordPress 백업 스케줄
0 2 * * * ${SCRIPT_DIR}/backup-main.sh daily >> ${SCRIPT_DIR}/../logs/cron.log 2>&1
0 3 * * 0 ${SCRIPT_DIR}/backup-main.sh weekly >> ${SCRIPT_DIR}/../logs/cron.log 2>&1
0 4 1 * * ${SCRIPT_DIR}/backup-main.sh monthly >> ${SCRIPT_DIR}/../logs/cron.log 2>&1
CRON

# crontab 적용
crontab /tmp/crontab.backup
echo "Cron jobs installed successfully"
echo "현재 설정된 cron 작업:"
crontab -l | grep -A3 -B1 "WordPress 백업"
EOF
echo "✅ Cron 설정 스크립트 생성 완료"

# 5. 백업 상태 확인 스크립트 생성
echo "5. 백업 상태 확인 스크립트 생성 중..."
cat > backup/scripts/backup-status.sh << 'EOF'
#!/bin/bash
source $(dirname $0)/backup-config.conf

echo "=== WordPress 백업 시스템 상태 ==="
echo

# 최근 백업 파일 확인
echo "📁 최근 백업 파일:"
echo "일일 백업:"
ls -lt ${BACKUP_ROOT}/daily/*.gz 2>/dev/null | head -3 || echo "  백업 파일 없음"
echo
echo "주간 백업:"
ls -lt ${BACKUP_ROOT}/weekly/*.gz 2>/dev/null | head -2 || echo "  백업 파일 없음"
echo
echo "월간 백업:"
ls -lt ${BACKUP_ROOT}/monthly/*.gz 2>/dev/null | head -2 || echo "  백업 파일 없음"
echo

# 디스크 사용량
echo "💾 백업 디스크 사용량:"
du -sh ${BACKUP_ROOT}/* 2>/dev/null || echo "  사용량 정보 없음"
echo

# 최근 로그 확인
echo "📋 최근 백업 로그:"
if ls ${BACKUP_ROOT}/logs/backup_*.log 1> /dev/null 2>&1; then
    tail -5 $(ls -t ${BACKUP_ROOT}/logs/backup_*.log | head -1)
else
    echo "  로그 파일 없음"
fi
echo

# Cron 작업 상태
echo "⏰ 예약된 백업 작업:"
crontab -l 2>/dev/null | grep backup || echo "  예약된 작업 없음"
echo

# 서비스 상태
echo "🔧 WordPress 서비스 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "wordpress|mysql" || echo "  서비스가 실행되지 않음"
echo
EOF
echo "✅ 백업 상태 확인 스크립트 생성 완료"

# 6. 실행 권한 설정
echo "6. 실행 권한 설정 중..."
chmod +x backup/scripts/*.sh
echo "✅ 실행 권한 설정 완료"

# 7. 생성된 파일 확인
echo "7. 생성된 파일 확인..."
echo "📁 디렉토리 구조:"
ls -la backup/
echo
echo "📄 스크립트 파일:"
ls -la backup/scripts/
echo

echo ""
echo "=== 백업 시스템 자동 구축 완료 ==="
echo ""
echo "생성된 구성 요소:"
echo "- 백업 디렉토리: backup/{daily,weekly,monthly}"
echo "- 설정 파일: backup/scripts/backup-config.conf"
echo "- 메인 스크립트: backup/scripts/backup-main.sh"
echo "- Cron 설정: backup/scripts/setup-cron.sh"
echo "- 상태 확인: backup/scripts/backup-status.sh"
echo ""
echo "다음 단계:"
echo "1. ./backup/scripts/backup-status.sh - 시스템 상태 확인"
echo "2. ./backup/scripts/backup-main.sh daily - 수동 백업 테스트"
echo "3. ./backup/scripts/setup-cron.sh - 자동 백업 스케줄 설정"