#!/bin/bash

# Week 2 Day 1 Lab 2: 보안 모니터링 시스템 구축 스크립트
# 사용법: ./setup_monitoring.sh

echo "=== 보안 모니터링 시스템 구축 시작 ==="

# 모니터링 네트워크 생성
echo "1. 모니터링 네트워크 생성 중..."
docker network create --driver bridge \
  --subnet=172.20.4.0/24 \
  --gateway=172.20.4.1 \
  monitoring-net 2>/dev/null || echo "모니터링 네트워크가 이미 존재합니다."

# 필요한 디렉토리 생성
echo "2. 모니터링 설정 디렉토리 생성 중..."
mkdir -p configs logs scripts

# Fail2ban 설정 파일 생성
echo "3. Fail2ban 침입 탐지 설정 생성 중..."
cat > configs/fail2ban.conf << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = auto
ignoreip = 127.0.0.1/8 172.20.0.0/16

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
banaction = iptables-multiport

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
banaction = iptables-multiport

[mysql-auth]
enabled = true
port = 3306
filter = mysql-auth
logpath = /var/log/mysql/error.log
maxretry = 3
banaction = iptables-multiport

[docker-firewall]
enabled = true
port = all
filter = docker-firewall
logpath = /var/log/kern.log
maxretry = 5
banaction = iptables-allports
EOF

# Fluent Bit 로그 수집 설정
echo "4. Fluent Bit 로그 수집 설정 생성 중..."
cat > configs/fluent-bit.conf << 'EOF'
[SERVICE]
    Flush         1
    Log_Level     info
    Daemon        off
    Parsers_File  parsers.conf

[INPUT]
    Name              tail
    Path              /var/log/nginx/*.log
    Parser            nginx
    Tag               nginx.*
    Refresh_Interval  5
    Skip_Long_Lines   On

[INPUT]
    Name              tail
    Path              /var/log/mysql/*.log
    Parser            mysql
    Tag               mysql.*
    Refresh_Interval  5
    Skip_Long_Lines   On

[INPUT]
    Name              tail
    Path              /var/log/kern.log
    Parser            syslog
    Tag               kernel.*
    Refresh_Interval  5

[FILTER]
    Name              grep
    Match             *
    Regex             log (error|ERROR|fail|FAIL|attack|ATTACK|suspicious|SUSPICIOUS)

[OUTPUT]
    Name  file
    Match *
    Path  /logs/
    File  security-events.log
    Format json_lines

[OUTPUT]
    Name  stdout
    Match *
    Format json_lines
EOF

# 보안 분석 스크립트 생성
echo "5. 보안 분석 스크립트 생성 중..."
cat > scripts/security_analyzer.py << 'EOF'
#!/usr/bin/env python3
import json
import time
import subprocess
import re
from datetime import datetime
from collections import defaultdict

class SecurityAnalyzer:
    def __init__(self):
        self.suspicious_ips = defaultdict(int)
        self.blocked_ips = set()
        self.alert_threshold = {
            'failed_logins': 5,
            'port_scans': 10,
            'high_traffic': 100,
            'sql_injection': 1,
            'xss_attempts': 1
        }
        self.log_file = '/logs/security-events.log'
        self.report_file = '/logs/security-report.json'
    
    def analyze_logs(self):
        """로그 파일 분석"""
        try:
            with open(self.log_file, 'r') as f:
                for line in f:
                    try:
                        event = json.loads(line.strip())
                        self.process_event(event)
                    except json.JSONDecodeError:
                        continue
        except FileNotFoundError:
            print(f"로그 파일을 찾을 수 없습니다: {self.log_file}")
    
    def process_event(self, event):
        """보안 이벤트 처리"""
        log_data = event.get('log', '')
        tag = event.get('tag', '')
        
        if 'nginx' in tag:
            self.analyze_web_traffic(log_data)
        elif 'mysql' in tag:
            self.analyze_db_access(log_data)
        elif 'kernel' in tag:
            self.analyze_firewall_logs(log_data)
    
    def analyze_web_traffic(self, log_data):
        """웹 트래픽 분석"""
        ip = self.extract_ip(log_data)
        if not ip:
            return
            
        # 실패한 인증 시도 탐지
        if any(code in log_data for code in ['401', '403', '404']):
            self.handle_suspicious_activity(ip, 'failed_auth')
        
        # SQL 인젝션 시도 탐지
        sql_patterns = ['union', 'select', 'drop', 'insert', 'delete', 'update', '--', ';']
        if any(pattern in log_data.lower() for pattern in sql_patterns):
            self.handle_suspicious_activity(ip, 'sql_injection', severity='high')
        
        # XSS 시도 탐지
        xss_patterns = ['<script', 'javascript:', 'onerror=', 'onload=']
        if any(pattern in log_data.lower() for pattern in xss_patterns):
            self.handle_suspicious_activity(ip, 'xss_attempt', severity='high')
        
        # 과도한 요청 탐지
        if '429' in log_data:  # Too Many Requests
            self.handle_suspicious_activity(ip, 'rate_limit_exceeded')
    
    def analyze_db_access(self, log_data):
        """데이터베이스 접근 분석"""
        ip = self.extract_ip(log_data)
        if not ip:
            return
            
        # 실패한 DB 연결 시도
        if 'Access denied' in log_data or 'authentication failed' in log_data.lower():
            self.handle_suspicious_activity(ip, 'db_auth_fail')
        
        # 비정상적인 쿼리 패턴
        if any(pattern in log_data.lower() for pattern in ['information_schema', 'show tables', 'describe']):
            self.handle_suspicious_activity(ip, 'db_reconnaissance')
    
    def analyze_firewall_logs(self, log_data):
        """방화벽 로그 분석"""
        if 'DOCKER-FIREWALL' in log_data:
            ip = self.extract_ip(log_data)
            if ip:
                self.handle_suspicious_activity(ip, 'firewall_block')
    
    def extract_ip(self, log_data):
        """로그에서 IP 주소 추출"""
        # IPv4 패턴 매칭
        ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
        match = re.search(ip_pattern, log_data)
        if match:
            ip = match.group()
            # 내부 IP 제외
            if not ip.startswith(('127.', '172.20.', '10.', '192.168.')):
                return ip
        return None
    
    def handle_suspicious_activity(self, ip, activity_type, severity='medium'):
        """의심스러운 활동 처리"""
        timestamp = datetime.now().isoformat()
        print(f"[{timestamp}] 의심스러운 활동 탐지: {ip} - {activity_type} (심각도: {severity})")
        
        # 활동 카운트 증가
        self.suspicious_ips[ip] += 1
        
        # 심각도에 따른 즉시 차단
        if severity == 'high' or self.suspicious_ips[ip] >= self.alert_threshold.get(activity_type, 5):
            self.block_ip(ip, activity_type)
    
    def block_ip(self, ip, reason):
        """IP 주소 차단"""
        if ip in self.blocked_ips:
            return
            
        try:
            # iptables를 사용한 IP 차단
            subprocess.run([
                'iptables', '-I', 'DOCKER-USER', '1', 
                '-s', ip, '-j', 'DROP'
            ], check=True, capture_output=True)
            
            self.blocked_ips.add(ip)
            print(f"🚫 IP {ip} 차단 완료 (사유: {reason})")
            
            # 차단 로그 기록
            self.log_security_event({
                'action': 'ip_blocked',
                'ip': ip,
                'reason': reason,
                'timestamp': datetime.now().isoformat()
            })
            
        except subprocess.CalledProcessError as e:
            print(f"❌ IP 차단 실패: {e}")
    
    def log_security_event(self, event):
        """보안 이벤트 로깅"""
        try:
            with open('/logs/security-actions.log', 'a') as f:
                f.write(json.dumps(event) + '\n')
        except Exception as e:
            print(f"로깅 오류: {e}")
    
    def generate_report(self):
        """보안 리포트 생성"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'suspicious_ips': dict(self.suspicious_ips),
            'blocked_ips': list(self.blocked_ips),
            'total_threats': len(self.suspicious_ips),
            'total_blocked': len(self.blocked_ips),
            'threat_summary': self.get_threat_summary()
        }
        
        try:
            with open(self.report_file, 'w') as f:
                json.dump(report, f, indent=2)
        except Exception as e:
            print(f"리포트 생성 오류: {e}")
        
        return report
    
    def get_threat_summary(self):
        """위협 요약 정보"""
        if not self.suspicious_ips:
            return "위협이 탐지되지 않았습니다."
        
        top_threats = sorted(self.suspicious_ips.items(), key=lambda x: x[1], reverse=True)[:5]
        summary = f"상위 5개 위협 IP: {', '.join([f'{ip}({count}회)' for ip, count in top_threats])}"
        return summary
    
    def cleanup_old_blocks(self):
        """오래된 차단 규칙 정리 (1시간 후)"""
        # 실제 구현에서는 타임스탬프 기반으로 정리
        pass

if __name__ == "__main__":
    analyzer = SecurityAnalyzer()
    
    print("🔍 보안 분석기 시작...")
    
    while True:
        try:
            analyzer.analyze_logs()
            report = analyzer.generate_report()
            
            if report['total_threats'] > 0:
                print(f"📊 보안 리포트: {report['total_threats']}개 위협, {report['total_blocked']}개 차단")
                print(f"📈 {report['threat_summary']}")
            
            time.sleep(30)  # 30초마다 분석
            
        except KeyboardInterrupt:
            print("\n🛑 보안 분석기 종료")
            break
        except Exception as e:
            print(f"❌ 분석 오류: {e}")
            time.sleep(10)
EOF

chmod +x scripts/security_analyzer.py

# 네트워크 트래픽 모니터링 스크립트
echo "6. 네트워크 트래픽 모니터링 스크립트 생성 중..."
cat > scripts/network_monitor.sh << 'EOF'
#!/bin/bash

echo "🌐 네트워크 트래픽 모니터링 시작..."

# 패킷 캡처 및 분석
tcpdump -i any -w /logs/network-traffic.pcap -C 100 -W 5 &
TCPDUMP_PID=$!

# 실시간 연결 모니터링
while true; do
    echo "=== $(date) ==="
    
    # 활성 연결 수 확인
    echo "활성 연결 수:"
    netstat -an | grep ESTABLISHED | wc -l
    
    # 포트별 연결 상태
    echo "포트별 연결 상태:"
    netstat -an | grep LISTEN | grep -E "(80|443|3306|6379|8080)" | sort
    
    # 의심스러운 연결 탐지
    echo "의심스러운 연결:"
    netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -5
    
    sleep 60
done
EOF

chmod +x scripts/network_monitor.sh

# 보안 모니터링 컨테이너 배포
echo "7. 보안 모니터링 컨테이너 배포 중..."

# Fail2ban 기반 침입 탐지 시스템
docker run -d \
  --name security-monitor \
  --network monitoring-net \
  --ip 172.20.4.10 \
  --privileged \
  -v /var/log:/var/log:ro \
  -v $(pwd)/configs/fail2ban.conf:/etc/fail2ban/jail.local \
  -v $(pwd)/scripts:/scripts \
  -v $(pwd)/logs:/logs \
  crazymax/fail2ban:latest

# 네트워크 트래픽 분석기
docker run -d \
  --name network-analyzer \
  --network monitoring-net \
  --ip 172.20.4.20 \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -v $(pwd)/logs:/logs \
  -v $(pwd)/scripts:/scripts \
  nicolaka/netshoot /scripts/network_monitor.sh

# 로그 수집 및 분석 시스템
docker run -d \
  --name log-collector \
  --network monitoring-net \
  --ip 172.20.4.30 \
  -v /var/log:/var/log:ro \
  -v $(pwd)/logs:/logs \
  -v $(pwd)/configs/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf \
  fluent/fluent-bit:latest

# 보안 분석기 컨테이너
docker run -d \
  --name security-analyzer \
  --network monitoring-net \
  --ip 172.20.4.40 \
  --privileged \
  -v $(pwd)/scripts:/scripts \
  -v $(pwd)/logs:/logs \
  python:3.9-alpine python /scripts/security_analyzer.py

# 모니터링 대시보드 (간단한 웹 인터페이스)
echo "8. 모니터링 대시보드 생성 중..."
cat > scripts/dashboard.py << 'EOF'
#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
from datetime import datetime

class DashboardHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_dashboard()
        elif self.path == '/api/status':
            self.send_status()
        elif self.path == '/api/report':
            self.send_report()
        else:
            self.send_error(404)
    
    def send_dashboard(self):
        html = '''
        <!DOCTYPE html>
        <html>
        <head>
            <title>보안 모니터링 대시보드</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
                .container { max-width: 1200px; margin: 0 auto; }
                .card { background: white; padding: 20px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                .status { display: inline-block; padding: 5px 10px; border-radius: 20px; color: white; }
                .status.ok { background: #4CAF50; }
                .status.warning { background: #FF9800; }
                .status.danger { background: #F44336; }
                button { padding: 10px 20px; margin: 5px; background: #2196F3; color: white; border: none; border-radius: 4px; cursor: pointer; }
                #report { background: #f9f9f9; padding: 15px; border-radius: 4px; white-space: pre-wrap; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🛡️ 보안 모니터링 대시보드</h1>
                
                <div class="card">
                    <h3>시스템 상태</h3>
                    <div id="status">로딩 중...</div>
                    <button onclick="refreshStatus()">상태 새로고침</button>
                </div>
                
                <div class="card">
                    <h3>보안 리포트</h3>
                    <button onclick="loadReport()">리포트 조회</button>
                    <div id="report"></div>
                </div>
            </div>
            
            <script>
                function refreshStatus() {
                    fetch('/api/status')
                        .then(response => response.json())
                        .then(data => {
                            document.getElementById('status').innerHTML = 
                                '<span class="status ok">시스템 정상</span> ' +
                                '<p>마지막 업데이트: ' + data.timestamp + '</p>';
                        });
                }
                
                function loadReport() {
                    fetch('/api/report')
                        .then(response => response.json())
                        .then(data => {
                            document.getElementById('report').textContent = JSON.stringify(data, null, 2);
                        });
                }
                
                // 자동 새로고침
                setInterval(refreshStatus, 30000);
                refreshStatus();
            </script>
        </body>
        </html>
        '''
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())
    
    def send_status(self):
        status = {
            'timestamp': datetime.now().isoformat(),
            'status': 'ok',
            'services': ['security-monitor', 'network-analyzer', 'log-collector', 'security-analyzer']
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(status).encode())
    
    def send_report(self):
        try:
            with open('/logs/security-report.json', 'r') as f:
                report = json.load(f)
        except:
            report = {'error': '리포트를 찾을 수 없습니다.'}
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(report).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8888), DashboardHandler)
    print('보안 대시보드 시작: http://localhost:8888')
    server.serve_forever()
EOF

chmod +x scripts/dashboard.py

# 대시보드 컨테이너 실행
docker run -d \
  --name security-dashboard \
  --network monitoring-net \
  --ip 172.20.4.50 \
  -p 8888:8888 \
  -v $(pwd)/scripts:/scripts \
  -v $(pwd)/logs:/logs \
  python:3.9-alpine python /scripts/dashboard.py

# 모니터링 시스템 상태 확인
echo "9. 모니터링 시스템 상태 확인..."
sleep 10

echo ""
echo "📊 모니터링 컨테이너 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(security-monitor|network-analyzer|log-collector|security-analyzer|security-dashboard)"

echo ""
echo "=== 보안 모니터링 시스템 구축 완료 ==="
echo ""
echo "🔍 모니터링 서비스:"
echo "✅ Fail2ban 침입 탐지: security-monitor"
echo "✅ 네트워크 트래픽 분석: network-analyzer"
echo "✅ 로그 수집 시스템: log-collector"
echo "✅ 보안 분석기: security-analyzer"
echo "✅ 모니터링 대시보드: security-dashboard"
echo ""
echo "🌐 접속 정보:"
echo "- 보안 대시보드: http://localhost:8888"
echo "- 로그 파일: $(pwd)/logs/"
echo "- 보안 리포트: $(pwd)/logs/security-report.json"
echo ""
echo "📋 모니터링 확인 명령어:"
echo "- docker logs security-analyzer"
echo "- tail -f logs/security-events.log"
echo "- cat logs/security-report.json"