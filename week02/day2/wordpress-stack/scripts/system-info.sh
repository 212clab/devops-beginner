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
