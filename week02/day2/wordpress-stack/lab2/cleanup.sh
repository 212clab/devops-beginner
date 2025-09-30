#!/bin/bash

# Week 2 Day 2 Lab 2: 실습 환경 정리
# 사용법: ./cleanup.sh

echo "=== Lab 2 실습 환경 정리 시작 ==="

# 정리 옵션 확인
FULL_CLEANUP=${1:-"partial"}  # partial, full

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 백업 파일 정리
cleanup_backup_files() {
    log "백업 파일 정리 중..."
    
    if [ -d "backup" ]; then
        echo "백업 디렉토리 내용:"
        du -sh backup/* 2>/dev/null || echo "  백업 파일 없음"
        
        read -p "백업 파일을 삭제하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf backup/daily/* backup/weekly/* backup/monthly/* 2>/dev/null
            rm -rf backup/logs/* 2>/dev/null
            log "✅ 백업 파일 정리 완료"
        else
            log "백업 파일 보존"
        fi
    fi
}

# 원격 저장소 시뮬레이션 정리
cleanup_remote_simulation() {
    log "원격 저장소 시뮬레이션 정리 중..."
    
    if [ -d "remote" ]; then
        echo "원격 저장소 시뮬레이션 내용:"
        du -sh remote/* 2>/dev/null || echo "  시뮬레이션 파일 없음"
        
        read -p "원격 저장소 시뮬레이션을 삭제하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf remote/
            log "✅ 원격 저장소 시뮬레이션 정리 완료"
        else
            log "원격 저장소 시뮬레이션 보존"
        fi
    fi
}

# Cron 작업 정리
cleanup_cron_jobs() {
    log "Cron 작업 정리 중..."
    
    # WordPress 백업 관련 cron 작업 확인
    BACKUP_CRONS=$(crontab -l 2>/dev/null | grep -c "backup-main.sh" || echo "0")
    
    if [ $BACKUP_CRONS -gt 0 ]; then
        echo "현재 설정된 백업 Cron 작업:"
        crontab -l 2>/dev/null | grep "backup"
        echo
        
        read -p "백업 관련 Cron 작업을 제거하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 백업 관련 cron 작업 제거
            crontab -l 2>/dev/null | grep -v "backup-main.sh" | grep -v "sync-remote.sh" | grep -v "cleanup-old.sh" | crontab -
            log "✅ Cron 작업 정리 완료"
        else
            log "Cron 작업 보존"
        fi
    else
        log "백업 관련 Cron 작업 없음"
    fi
}

# 백그라운드 프로세스 정리
cleanup_background_processes() {
    log "백그라운드 프로세스 정리 중..."
    
    # 헬스 체크 프로세스 확인 및 종료
    HEALTH_PIDS=$(pgrep -f "health-check.sh" || echo "")
    if [ -n "$HEALTH_PIDS" ]; then
        echo "실행 중인 헬스 체크 프로세스: $HEALTH_PIDS"
        read -p "헬스 체크 프로세스를 종료하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill $HEALTH_PIDS 2>/dev/null
            log "✅ 헬스 체크 프로세스 종료 완료"
        fi
    else
        log "실행 중인 헬스 체크 프로세스 없음"
    fi
    
    # 백업 관련 프로세스 확인
    BACKUP_PIDS=$(pgrep -f "backup-main.sh" || echo "")
    if [ -n "$BACKUP_PIDS" ]; then
        echo "실행 중인 백업 프로세스: $BACKUP_PIDS"
        read -p "백업 프로세스를 종료하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill $BACKUP_PIDS 2>/dev/null
            log "✅ 백업 프로세스 종료 완료"
        fi
    else
        log "실행 중인 백업 프로세스 없음"
    fi
}

# 전체 환경 정리 (Lab 1 포함)
cleanup_full_environment() {
    log "전체 환경 정리 중..."
    
    echo "⚠️  경고: 이 작업은 Lab 1에서 구축한 WordPress 시스템도 삭제합니다."
    echo "현재 실행 중인 컨테이너:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "wordpress|mysql|nginx|redis"
    echo
    
    read -p "전체 WordPress 스택을 삭제하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 컨테이너 중지 및 제거
        log "컨테이너 중지 및 제거 중..."
        docker stop mysql-wordpress wordpress-app nginx-proxy redis-session 2>/dev/null || true
        docker rm mysql-wordpress wordpress-app nginx-proxy redis-session 2>/dev/null || true
        
        # 네트워크 제거
        log "네트워크 제거 중..."
        docker network rm wordpress-net 2>/dev/null || true
        
        # 볼륨 제거 확인
        echo "현재 볼륨:"
        docker volume ls | grep -E "wp-content|mysql-data|nginx|redis"
        echo
        
        read -p "데이터 볼륨도 삭제하시겠습니까? (데이터가 영구 삭제됩니다) (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker volume rm wp-content mysql-data wp-config nginx-logs nginx-cache redis-data 2>/dev/null || true
            log "✅ 볼륨 삭제 완료"
        else
            log "볼륨 보존"
        fi
        
        log "✅ 전체 환경 정리 완료"
    else
        log "전체 환경 정리 취소"
    fi
}

# 부분 정리 (Lab 2만)
cleanup_partial_environment() {
    log "Lab 2 관련 요소만 정리 중..."
    
    cleanup_backup_files
    cleanup_remote_simulation
    cleanup_cron_jobs
    cleanup_background_processes
    
    log "✅ Lab 2 부분 정리 완료"
}

# 정리 상태 확인
show_cleanup_status() {
    echo ""
    echo "======================================"
    echo "         정리 완료 상태"
    echo "======================================"
    echo ""
    
    # 컨테이너 상태
    echo "🐳 Docker 컨테이너 상태:"
    CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "wordpress|mysql|nginx|redis" || echo "  관련 컨테이너 없음")
    echo "$CONTAINERS"
    echo
    
    # 볼륨 상태
    echo "💾 Docker 볼륨 상태:"
    VOLUMES=$(docker volume ls | grep -E "wp-content|mysql-data|nginx|redis" || echo "  관련 볼륨 없음")
    echo "$VOLUMES"
    echo
    
    # 백업 디렉토리 상태
    echo "📁 백업 디렉토리 상태:"
    if [ -d "backup" ]; then
        du -sh backup/* 2>/dev/null || echo "  백업 디렉토리 비어있음"
    else
        echo "  백업 디렉토리 없음"
    fi
    echo
    
    # Cron 작업 상태
    echo "⏰ Cron 작업 상태:"
    CRON_JOBS=$(crontab -l 2>/dev/null | grep -c "backup" || echo "0")
    echo "  백업 관련 Cron 작업: ${CRON_JOBS}개"
    echo
    
    # 프로세스 상태
    echo "🔄 백그라운드 프로세스 상태:"
    HEALTH_PROCS=$(pgrep -f "health-check.sh" | wc -l)
    BACKUP_PROCS=$(pgrep -f "backup-main.sh" | wc -l)
    echo "  헬스 체크 프로세스: ${HEALTH_PROCS}개"
    echo "  백업 프로세스: ${BACKUP_PROCS}개"
    echo
}

# 메인 실행
main() {
    log "Lab 2 실습 환경 정리 시작"
    
    case $FULL_CLEANUP in
        "full")
            log "전체 정리 모드"
            cleanup_partial_environment
            cleanup_full_environment
            ;;
        "partial"|*)
            log "부분 정리 모드 (Lab 2만)"
            cleanup_partial_environment
            ;;
    esac
    
    show_cleanup_status
    
    echo ""
    echo "🎉 Lab 2 실습 환경 정리 완료!"
    echo ""
    echo "사용법:"
    echo "  ./cleanup.sh          # Lab 2만 정리"
    echo "  ./cleanup.sh full     # 전체 환경 정리 (Lab 1 포함)"
    echo ""
    
    log "실습 환경 정리 완료 - $(date)"
}

# 사용법 표시
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Lab 2 실습 환경 정리 스크립트"
    echo ""
    echo "사용법:"
    echo "  $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  (없음)    Lab 2 관련 요소만 정리 (기본값)"
    echo "  full      전체 환경 정리 (Lab 1 포함)"
    echo "  --help    이 도움말 표시"
    echo ""
    echo "정리 대상:"
    echo "  - 백업 파일 및 디렉토리"
    echo "  - 원격 저장소 시뮬레이션"
    echo "  - Cron 작업"
    echo "  - 백그라운드 프로세스"
    echo "  - Docker 컨테이너/볼륨 (full 옵션시)"
    exit 0
fi

main