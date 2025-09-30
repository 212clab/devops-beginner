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
