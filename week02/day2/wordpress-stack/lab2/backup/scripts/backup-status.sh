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
