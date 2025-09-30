#!/bin/bash

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /logs/health.log
}

check_service() {
    local service_name=$1
    local check_command=$2
    
    if eval $check_command >/dev/null 2>&1; then
        log "✅ $service_name: 정상"
        return 0
    else
        log "❌ $service_name: 비정상"
        return 1
    fi
}

log "=== 헬스 체크 시작 ==="

# MySQL 헬스 체크
check_service "MySQL" "docker exec mysql-wordpress mysqladmin ping -u wpuser -pwppassword"

# Redis 헬스 체크
check_service "Redis" "docker exec redis-session redis-cli ping | grep -q PONG"

# WordPress 헬스 체크
check_service "WordPress" "curl -f http://localhost:8080/"

# Nginx 헬스 체크
check_service "Nginx" "curl -f http://localhost/health"

# 디스크 사용량 체크
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    log "⚠️ 디스크 사용량 경고: ${DISK_USAGE}%"
else
    log "✅ 디스크 사용량 정상: ${DISK_USAGE}%"
fi

# 메모리 사용량 체크
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ $MEMORY_USAGE -gt 80 ]; then
    log "⚠️ 메모리 사용량 경고: ${MEMORY_USAGE}%"
else
    log "✅ 메모리 사용량 정상: ${MEMORY_USAGE}%"
fi

log "=== 헬스 체크 완료 ==="
