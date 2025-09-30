#!/bin/bash

# Week 2 Day 2 Lab 2: 원격 저장소 연동 자동 설정
# 사용법: ./setup_remote_storage.sh

echo "=== 원격 저장소 연동 자동 설정 시작 ==="

# 현재 디렉토리 확인
if [ ! -f "backup/scripts/backup-config.conf" ]; then
    echo "❌ 백업 설정 파일을 찾을 수 없습니다. setup_backup_system.sh를 먼저 실행해주세요."
    exit 1
fi

# 1. AWS S3 동기화 스크립트 생성
echo "1. AWS S3 동기화 스크립트 생성 중..."
cat > backup/scripts/sync-s3.sh << 'EOF'
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
EOF

# 2. Google Drive 동기화 스크립트 생성
echo "2. Google Drive 동기화 스크립트 생성 중..."
cat > backup/scripts/sync-gdrive.sh << 'EOF'
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
EOF

# 3. FTP 백업 스크립트 생성
echo "3. FTP 백업 스크립트 생성 중..."
cat > backup/scripts/sync-ftp.sh << 'EOF'
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
EOF

# 4. 통합 원격 동기화 스크립트 생성
echo "4. 통합 원격 동기화 스크립트 생성 중..."
cat > backup/scripts/sync-remote.sh << 'EOF'
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
EOF

# 5. 원격 저장소 상태 확인 스크립트 생성
echo "5. 원격 저장소 상태 확인 스크립트 생성 중..."
cat > backup/scripts/remote-status.sh << 'EOF'
#!/bin/bash
source $(dirname $0)/backup-config.conf

echo "=== 원격 저장소 상태 확인 ==="
echo

# S3 상태 (시뮬레이션)
echo "☁️ AWS S3 상태 (시뮬레이션):"
if [ -d "${BACKUP_ROOT}/../remote/s3" ]; then
    echo "  버킷: ${S3_BUCKET} (시뮬레이션)"
    echo "  리전: ${S3_REGION}"
    echo "  파일 수:"
    find ${BACKUP_ROOT}/../remote/s3 -type f | wc -l | sed 's/^/    /'
    echo "  총 크기:"
    du -sh ${BACKUP_ROOT}/../remote/s3 2>/dev/null | cut -f1 | sed 's/^/    /'
else
    echo "  S3 시뮬레이션 디렉토리 없음"
fi
echo

# Google Drive 상태 (시뮬레이션)
echo "📁 Google Drive 상태 (시뮬레이션):"
if [ -d "${BACKUP_ROOT}/../remote/gdrive" ]; then
    echo "  폴더: ${GDRIVE_FOLDER} (시뮬레이션)"
    echo "  파일 수:"
    find ${BACKUP_ROOT}/../remote/gdrive -type f | wc -l | sed 's/^/    /'
    echo "  총 크기:"
    du -sh ${BACKUP_ROOT}/../remote/gdrive 2>/dev/null | cut -f1 | sed 's/^/    /'
else
    echo "  Google Drive 시뮬레이션 디렉토리 없음"
fi
echo

# FTP 상태 (시뮬레이션)
echo "🌐 FTP 서버 상태 (시뮬레이션):"
if [ -d "${BACKUP_ROOT}/../remote/ftp" ]; then
    echo "  호스트: ${FTP_HOST} (시뮬레이션)"
    echo "  사용자: ${FTP_USER}"
    echo "  파일 수:"
    find ${BACKUP_ROOT}/../remote/ftp -type f | wc -l | sed 's/^/    /'
    echo "  총 크기:"
    du -sh ${BACKUP_ROOT}/../remote/ftp 2>/dev/null | cut -f1 | sed 's/^/    /'
else
    echo "  FTP 시뮬레이션 디렉토리 없음"
fi
echo

# 최근 동기화 로그
echo "📋 최근 동기화 로그:"
if ls ${BACKUP_ROOT}/logs/sync_*.log 1> /dev/null 2>&1; then
    echo "  최근 로그 파일: $(ls -t ${BACKUP_ROOT}/logs/sync_*.log | head -1)"
    echo "  마지막 5줄:"
    tail -5 $(ls -t ${BACKUP_ROOT}/logs/sync_*.log | head -1) | sed 's/^/    /'
else
    echo "  동기화 로그 없음"
fi
EOF

# 6. 실행 권한 설정
echo "6. 실행 권한 설정 중..."
chmod +x backup/scripts/sync-*.sh backup/scripts/remote-status.sh

# 7. 원격 저장소 테스트
echo "7. 원격 저장소 연동 테스트 실행 중..."
./backup/scripts/sync-remote.sh

if [ $? -eq 0 ]; then
    echo "✅ 원격 저장소 연동 테스트 성공"
else
    echo "❌ 원격 저장소 연동 테스트 실패"
    exit 1
fi

echo ""
echo "=== 원격 저장소 연동 자동 설정 완료 ==="
echo ""
echo "생성된 구성 요소:"
echo "- S3 동기화: backup/scripts/sync-s3.sh"
echo "- Google Drive 동기화: backup/scripts/sync-gdrive.sh"
echo "- FTP 동기화: backup/scripts/sync-ftp.sh"
echo "- 통합 동기화: backup/scripts/sync-remote.sh"
echo "- 상태 확인: backup/scripts/remote-status.sh"
echo ""
echo "원격 저장소 상태 확인:"
./backup/scripts/remote-status.sh
echo ""
echo "다음 단계: ./lab_scripts/lab2/setup_disaster_recovery.sh 실행"