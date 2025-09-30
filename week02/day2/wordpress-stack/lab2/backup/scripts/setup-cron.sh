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
