#!/bin/bash

# Week 2 Day 4 Lab 1: 한글 지원 롤링 업데이트 스크립트
# 사용법: ./deploy_korean_update.sh

echo "=== 한글 지원 롤링 업데이트 시작 ==="
echo ""

# 1. 클러스터 연결 확인
echo "1. 클러스터 연결 확인 중..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes 클러스터에 연결할 수 없습니다."
    exit 1
fi
echo "✅ 클러스터 연결 확인 완료"
echo ""

# 2. 현재 상태 확인
echo "2. 업데이트 전 상태 확인..."
echo "현재 Pod 상태:"
kubectl get pods -n lab-demo
echo ""
echo "현재 페이지 제목:"
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    curl -s http://localhost:8080 | grep -o '<title>.*</title>' | head -1
else
    echo "포트 포워딩이 설정되지 않았습니다. setup_external_access.sh를 먼저 실행해주세요."
fi
echo ""

# 3. 한글 지원 ConfigMap 생성
echo "3. 한글 지원 ConfigMap 생성 중..."
cat > /tmp/configmap-korean.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: lab-demo
data:
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        charset utf-8;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /health {
            access_log off;
            return 200 "healthy";
            add_header Content-Type "text/plain; charset=utf-8";
        }
        
        location /info {
            access_log off;
            return 200 "서버 상태: 정상\n버전: v2.0\n";
            add_header Content-Type "text/plain; charset=utf-8";
        }
    }
  index.html: |
    <!DOCTYPE html>
    <html lang="ko">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>🚀 Kubernetes 실습 - 한글 지원</title>
        <style>
            body { 
                font-family: 'Malgun Gothic', Arial, sans-serif; 
                margin: 40px; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                min-height: 100vh;
            }
            .container { 
                max-width: 800px; 
                margin: 0 auto; 
                background: rgba(255,255,255,0.1); 
                padding: 30px; 
                border-radius: 15px; 
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            }
            h1 { text-align: center; margin-bottom: 30px; font-size: 2.5em; }
            .info { 
                background: rgba(255,255,255,0.2); 
                padding: 20px; 
                border-radius: 10px; 
                margin: 20px 0; 
            }
            .status { 
                display: flex; 
                justify-content: space-between; 
                margin: 20px 0; 
                flex-wrap: wrap;
            }
            .metric { 
                text-align: center; 
                padding: 15px; 
                background: rgba(255,255,255,0.2); 
                border-radius: 10px; 
                margin: 5px;
                flex: 1;
                min-width: 150px;
            }
            .objectives { list-style: none; padding: 0; }
            .objectives li { 
                padding: 8px 0; 
                border-bottom: 1px solid rgba(255,255,255,0.2); 
            }
            .objectives li:last-child { border-bottom: none; }
            .update-info {
                background: rgba(76, 175, 80, 0.3);
                border: 2px solid rgba(76, 175, 80, 0.5);
                padding: 15px;
                border-radius: 10px;
                margin: 20px 0;
                text-align: center;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Kubernetes 실습 환경</h1>
            
            <div class="update-info">
                <h3>✨ 롤링 업데이트 완료!</h3>
                <p>한글 지원이 성공적으로 적용되었습니다.</p>
            </div>
            
            <div class="info">
                <h3>📊 Pod 정보</h3>
                <p><strong>Pod 이름:</strong> <span id="hostname">로딩 중...</span></p>
                <p><strong>네임스페이스:</strong> lab-demo</p>
                <p><strong>서비스:</strong> nginx-service</p>
                <p><strong>버전:</strong> v2.0 (한글 지원)</p>
                <p><strong>업데이트:</strong> <span id="updateTime"></span></p>
            </div>
            
            <div class="status">
                <div class="metric">
                    <h4>🔄 상태</h4>
                    <p id="status">실행 중</p>
                </div>
                <div class="metric">
                    <h4>⏰ 가동시간</h4>
                    <p id="uptime">0초</p>
                </div>
                <div class="metric">
                    <h4>🌐 요청수</h4>
                    <p id="requests">0</p>
                </div>
            </div>
            
            <div class="info">
                <h3>🎯 실습 목표</h3>
                <ul class="objectives">
                    <li>✅ Kubernetes 클러스터 구축 완료</li>
                    <li>✅ Pod, Service, Deployment 배포 완료</li>
                    <li>✅ ConfigMap을 통한 설정 관리 완료</li>
                    <li>✅ 롤링 업데이트를 통한 한글 지원 완료</li>
                    <li>✅ 외부 접근 및 서비스 디스커버리 완료</li>
                </ul>
            </div>
            
            <div class="info">
                <h3>🔗 접근 방법</h3>
                <p><strong>포트 포워딩:</strong> http://localhost:8080</p>
                <p><strong>NodePort:</strong> http://localhost:30080</p>
                <p><strong>헬스체크:</strong> /health</p>
                <p><strong>서버 정보:</strong> /info</p>
            </div>
            
            <div class="info">
                <h3>🛠️ 롤링 업데이트 특징</h3>
                <ul class="objectives">
                    <li>🔄 무중단 서비스 업데이트</li>
                    <li>📦 ConfigMap 변경사항 자동 적용</li>
                    <li>🔍 실시간 상태 모니터링</li>
                    <li>↩️ 롤백 기능 지원</li>
                    <li>📈 점진적 배포로 안정성 확보</li>
                </ul>
            </div>
        </div>
        
        <script>
            let startTime = Date.now();
            let requestCount = 0;
            
            function updateInfo() {
                document.getElementById('hostname').textContent = window.location.hostname || 'localhost';
                const uptime = Math.floor((Date.now() - startTime) / 1000);
                document.getElementById('uptime').textContent = uptime + '초';
                document.getElementById('requests').textContent = ++requestCount;
                document.getElementById('updateTime').textContent = new Date().toLocaleString('ko-KR');
            }
            
            updateInfo();
            setInterval(updateInfo, 1000);
            
            // 헬스체크 테스트
            fetch('/health')
                .then(response => response.text())
                .then(data => {
                    if (data.includes('healthy')) {
                        document.getElementById('status').textContent = '✅ 정상';
                        document.getElementById('status').style.color = '#4CAF50';
                    }
                })
                .catch(() => {
                    document.getElementById('status').textContent = '❌ 오류';
                    document.getElementById('status').style.color = '#f44336';
                });
        </script>
    </body>
    </html>
EOF

# ConfigMap 업데이트 적용
kubectl apply -f /tmp/configmap-korean.yaml
echo "✅ 한글 지원 ConfigMap 업데이트 완료"
echo ""

# 4. 롤링 업데이트 실행
echo "4. 롤링 업데이트 실행 중..."
echo "Pod 재시작을 통해 새로운 ConfigMap을 적용합니다..."

# 롤링 재시작 실행
kubectl rollout restart deployment/nginx-deployment -n lab-demo
echo "✅ 롤링 업데이트 시작됨"
echo ""

# 5. 롤링 업데이트 진행 상황 모니터링
echo "5. 롤링 업데이트 진행 상황 모니터링..."
echo "업데이트 진행 중... (최대 120초 대기)"

# 진행 상황 표시
kubectl rollout status deployment/nginx-deployment -n lab-demo --timeout=120s

if [ $? -eq 0 ]; then
    echo "✅ 롤링 업데이트 성공적으로 완료"
else
    echo "⚠️ 롤링 업데이트 시간 초과 또는 실패"
    echo "현재 상태를 확인합니다..."
fi
echo ""

# 6. 업데이트 후 상태 확인
echo "6. 업데이트 후 상태 확인..."
echo "새로운 Pod 상태:"
kubectl get pods -n lab-demo
echo ""

# Pod 준비 완료 대기
echo "Pod 준비 완료 대기 중..."
kubectl wait --for=condition=Ready pods -l app=nginx -n lab-demo --timeout=60s

if [ $? -eq 0 ]; then
    echo "✅ 모든 Pod 준비 완료"
else
    echo "⚠️ 일부 Pod가 준비되지 않았지만 계속 진행합니다"
fi
echo ""

# 7. 포트 포워딩 재설정 (롤링 업데이트 후)
echo "7. 포트 포워딩 재설정 중..."
echo "롤링 업데이트로 인해 포트 포워딩을 다시 설정합니다..."

# 기존 포트 포워딩 프로세스 정리
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 3

# 새로운 포트 포워딩 시작
kubectl port-forward svc/nginx-service 8080:80 -n lab-demo > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

# 포트 포워딩 준비 대기
sleep 5

# 포트 포워딩 상태 확인
if ps -p $PORT_FORWARD_PID > /dev/null; then
    echo "✅ 포트 포워딩 재설정 완료 (PID: $PORT_FORWARD_PID)"
else
    echo "❌ 포트 포워딩 재설정 실패"
fi
echo ""

# 8. 새로운 페이지 확인
echo "8. 업데이트된 페이지 확인..."
echo "포트 포워딩 안정화 대기 중..."
sleep 3

echo "새로운 페이지 제목:"
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    curl -s http://localhost:8080 | grep -o '<title>.*</title>' | head -1
    echo ""
    echo "서버 정보 확인:"
    curl -s http://localhost:8080/info
else
    echo "⚠️ 페이지 접근 실패. 잠시 후 다시 시도해주세요."
    echo "수동 포트 포워딩: kubectl port-forward svc/nginx-service 8080:80 -n lab-demo &"
fi
echo ""

# 9. 롤링 업데이트 히스토리 확인
echo "9. 배포 히스토리 확인..."
kubectl rollout history deployment/nginx-deployment -n lab-demo
echo ""

# 10. 서비스 가용성 테스트
echo "10. 서비스 가용성 테스트..."
echo "헬스체크 테스트 (5회):"
for i in {1..5}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
        echo "  $i. ✅ $HEALTH_RESPONSE - $(date '+%H:%M:%S')"
    else
        echo "  $i. ❌ 헬스체크 실패 - $(date '+%H:%M:%S')"
    fi
    sleep 1
done
echo ""

# 11. 완료 요약
echo "=== 한글 지원 롤링 업데이트 완료 ==="
echo ""
echo "✅ 업데이트 완료 사항:"
echo "- ConfigMap 한글 지원 설정 적용"
echo "- UTF-8 인코딩 및 한글 폰트 설정"
echo "- 롤링 업데이트를 통한 무중단 배포"
echo "- 새로운 /info 엔드포인트 추가"
echo "- 향상된 UI/UX 적용"
echo ""
echo "🌐 접근 정보:"
echo "- 메인 페이지: http://localhost:8080 (포트 포워딩 PID: $PORT_FORWARD_PID)"
echo "- 헬스체크: http://localhost:8080/health"
echo "- 서버 정보: http://localhost:8080/info (새로 추가됨!)"
echo "- NodePort: http://localhost:30080"
echo "- 포트 포워딩 중지: kill $PORT_FORWARD_PID"
echo ""
echo "🔧 확인 명령어:"
echo "- kubectl get pods -n lab-demo"
echo "- kubectl rollout history deployment/nginx-deployment -n lab-demo"
echo "- kubectl describe deployment nginx-deployment -n lab-demo"
echo ""
echo "📚 학습 포인트:"
echo "- ConfigMap 업데이트 방법"
echo "- 롤링 업데이트 프로세스"
echo "- 무중단 서비스 업데이트"
echo "- 배포 히스토리 관리"
echo "- 서비스 가용성 모니터링"
echo ""
echo "다음 단계:"
echo "- k8s_management_demo.sh 실행으로 관리 명령어 실습"
echo "- test_k8s_environment.sh 실행으로 종합 테스트"
echo ""
echo "🎉 한글 지원 롤링 업데이트가 성공적으로 완료되었습니다!"