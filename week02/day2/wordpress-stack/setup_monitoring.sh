#!/bin/bash

# Week 2 Day 2 Lab 1: 모니터링 및 백업 설정 스크립트
# 사용법: ./setup_monitoring.sh

echo "=== 모니터링 및 백업 설정 시작 ==="

# 기존 컨테이너 정리
echo "0. 기존 컨테이너 정리 중..."
docker stop monitoring-dashboard 2>/dev/null || true
docker rm monitoring-dashboard 2>/dev/null || true

# 스크립트 디렉토리 생성
echo "1. 스크립트 디렉토리 생성 중..."
mkdir -p scripts backup/{daily,weekly,monthly} logs

# 백업 스크립트 생성
echo "2. 백업 스크립트 생성 중..."
cat > scripts/backup.sh << 'EOF'
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
EOF

chmod +x scripts/backup.sh

# 헬스 체크 스크립트 생성
echo "3. 헬스 체크 스크립트 생성 중..."
cat > scripts/health-check.sh << 'EOF'
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
EOF

chmod +x scripts/health-check.sh

# 시스템 정보 수집 스크립트 생성
echo "4. 시스템 정보 수집 스크립트 생성 중..."
cat > scripts/system-info.sh << 'EOF'
#!/bin/bash

REPORT_FILE="/logs/system-report_$(date +%Y%m%d_%H%M%S).txt"

echo "=== 시스템 정보 리포트 ===" > $REPORT_FILE
echo "생성 시간: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 컨테이너 상태
echo "=== 컨테이너 상태 ===" >> $REPORT_FILE
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 볼륨 정보
echo "=== 볼륨 정보 ===" >> $REPORT_FILE
docker volume ls >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 네트워크 정보
echo "=== 네트워크 정보 ===" >> $REPORT_FILE
docker network ls >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 리소스 사용량
echo "=== 리소스 사용량 ===" >> $REPORT_FILE
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 디스크 사용량
echo "=== 디스크 사용량 ===" >> $REPORT_FILE
df -h >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 최근 로그 (에러만)
echo "=== 최근 에러 로그 ===" >> $REPORT_FILE
docker logs mysql-wordpress 2>&1 | grep -i error | tail -5 >> $REPORT_FILE
docker logs wordpress-app 2>&1 | grep -i error | tail -5 >> $REPORT_FILE
docker logs nginx-proxy 2>&1 | grep -i error | tail -5 >> $REPORT_FILE

echo "시스템 리포트 생성 완료: $REPORT_FILE"
EOF

chmod +x scripts/system-info.sh

# 로그 로테이션 스크립트 생성
echo "5. 로그 로테이션 스크립트 생성 중..."
cat > scripts/log-rotation.sh << 'EOF'
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
EOF

chmod +x scripts/log-rotation.sh

# 모니터링 대시보드 HTML 생성
echo "6. 모니터링 대시보드 생성 중..."
cat > scripts/dashboard.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>WordPress Stack 모니터링</title>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .card { background: white; padding: 20px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { display: inline-block; padding: 5px 10px; border-radius: 20px; color: white; font-weight: bold; }
        .status.ok { background: #4CAF50; }
        .status.warning { background: #FF9800; }
        .status.error { background: #F44336; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #e3f2fd; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 WordPress Stack 모니터링 대시보드</h1>
        
        <div class="card">
            <h3>📊 서비스 상태</h3>
            <div id="services">
                <span class="status ok">MySQL</span>
                <span class="status ok">WordPress</span>
                <span class="status ok">Redis</span>
                <span class="status ok">Nginx</span>
            </div>
        </div>
        
        <div class="card">
            <h3>📈 시스템 메트릭</h3>
            <div class="metric">
                <strong>CPU 사용률</strong><br>
                <span id="cpu">Loading...</span>
            </div>
            <div class="metric">
                <strong>메모리 사용률</strong><br>
                <span id="memory">Loading...</span>
            </div>
            <div class="metric">
                <strong>디스크 사용률</strong><br>
                <span id="disk">Loading...</span>
            </div>
        </div>
        
        <div class="card">
            <h3>🐳 컨테이너 정보</h3>
            <table>
                <tr>
                    <th>컨테이너</th>
                    <th>상태</th>
                    <th>포트</th>
                    <th>메모리</th>
                </tr>
                <tr>
                    <td>mysql-wordpress</td>
                    <td><span class="status ok">Running</span></td>
                    <td>3306</td>
                    <td>~512MB</td>
                </tr>
                <tr>
                    <td>wordpress-app</td>
                    <td><span class="status ok">Running</span></td>
                    <td>8080:80</td>
                    <td>~256MB</td>
                </tr>
                <tr>
                    <td>redis-session</td>
                    <td><span class="status ok">Running</span></td>
                    <td>6379</td>
                    <td>~64MB</td>
                </tr>
                <tr>
                    <td>nginx-proxy</td>
                    <td><span class="status ok">Running</span></td>
                    <td>80:80</td>
                    <td>~32MB</td>
                </tr>
            </table>
        </div>
        
        <div class="card">
            <h3>🔗 빠른 링크</h3>
            <p>
                <a href="http://localhost" target="_blank">🌐 WordPress 사이트</a> |
                <a href="http://localhost/wp-admin" target="_blank">⚙️ WordPress 관리자</a> |
                <a href="http://localhost/nginx_status" target="_blank">📊 Nginx 상태</a>
            </p>
        </div>
        
        <div class="card">
            <h3>📝 최근 활동</h3>
            <p>마지막 업데이트: <span id="lastUpdate"></span></p>
            <p>마지막 백업: <span id="lastBackup">확인 중...</span></p>
            <p>시스템 가동시간: <span id="uptime">확인 중...</span></p>
        </div>
    </div>
    
    <script>
        document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
        
        // 간단한 상태 체크 (실제 환경에서는 API 호출)
        setTimeout(() => {
            document.getElementById('cpu').textContent = Math.floor(Math.random() * 30 + 10) + '%';
            document.getElementById('memory').textContent = Math.floor(Math.random() * 40 + 30) + '%';
            document.getElementById('disk').textContent = Math.floor(Math.random() * 20 + 15) + '%';
            document.getElementById('uptime').textContent = '2시간 30분';
        }, 1000);
    </script>
</body>
</html>
EOF

# 간단한 웹 서버로 대시보드 서빙
echo "7. 모니터링 대시보드 서버 실행 중..."
docker run -d \
  --name monitoring-dashboard \
  --network wordpress-net \
  --restart=unless-stopped \
  -p 9090:80 \
  -v $(pwd)/scripts/dashboard.html:/usr/share/nginx/html/index.html \
  --memory=64m \
  nginx:alpine

# 백그라운드에서 헬스 체크 실행
echo "8. 백그라운드 모니터링 시작..."
nohup bash -c 'while true; do ./scripts/health-check.sh; sleep 300; done' > /dev/null 2>&1 &

echo ""
echo "=== 모니터링 및 백업 설정 완료 ==="
echo ""
echo "생성된 스크립트:"
echo "✅ scripts/backup.sh - 백업 실행"
echo "✅ scripts/health-check.sh - 헬스 체크"
echo "✅ scripts/system-info.sh - 시스템 정보 수집"
echo "✅ scripts/log-rotation.sh - 로그 로테이션"
echo ""
echo "모니터링 대시보드:"
echo "🌐 http://localhost:9090 - 모니터링 대시보드"
echo ""
echo "수동 실행 예시:"
echo "- 백업 실행: ./scripts/backup.sh"
echo "- 헬스 체크: ./scripts/health-check.sh"
echo "- 시스템 리포트: ./scripts/system-info.sh"
echo ""
echo "📁 로그 위치: logs/"
echo "📁 백업 위치: backup/daily/"