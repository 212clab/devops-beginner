#!/bin/bash

# Week 2 Day 1 Lab 2: 실습 환경 정리 스크립트
# 사용법: ./cleanup.sh

echo "=== Week 2 Day 1 실습 환경 정리 시작 ==="

# 사용자 확인
read -p "모든 실습 컨테이너와 네트워크를 삭제하시겠습니까? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "정리 작업이 취소되었습니다."
    exit 0
fi

echo "1. 실습 컨테이너 중지 및 삭제 중..."

# Lab 1 컨테이너들
lab1_containers=(
    "mysql-db"
    "redis-cache"
    "api-server-1"
    "api-server-2"
    "load-balancer"
    "web-server"
)

# Lab 2 컨테이너들
lab2_containers=(
    "secure-mysql-db"
    "secure-redis-cache"
    "secure-load-balancer"
    "security-monitor"
    "network-analyzer"
    "log-collector"
    "security-analyzer"
    "security-dashboard"
)

# 모든 컨테이너 중지 및 삭제
all_containers=("${lab1_containers[@]}" "${lab2_containers[@]}")

for container in "${all_containers[@]}"; do
    if docker ps -a | grep -q "$container"; then
        echo "  - $container 중지 및 삭제 중..."
        docker stop "$container" 2>/dev/null
        docker rm "$container" 2>/dev/null
    fi
done

echo "2. 실습 네트워크 삭제 중..."

# 실습에서 생성한 네트워크들
networks=(
    "frontend-net"
    "backend-net"
    "database-net"
    "monitoring-net"
)

for network in "${networks[@]}"; do
    if docker network ls | grep -q "$network"; then
        echo "  - $network 삭제 중..."
        docker network rm "$network" 2>/dev/null
    fi
done

echo "3. 실습 이미지 정리 중..."

# 실습에서 빌드한 이미지들
if docker images | grep -q "api-server"; then
    echo "  - api-server 이미지 삭제 중..."
    docker rmi api-server:latest 2>/dev/null
fi

# 사용하지 않는 이미지 정리 (선택적)
read -p "사용하지 않는 Docker 이미지도 정리하시겠습니까? (y/N): " cleanup_images
if [[ $cleanup_images == [yY] ]]; then
    echo "  - 사용하지 않는 이미지 정리 중..."
    docker image prune -f
fi

echo "4. 실습 볼륨 정리 중..."

# 실습에서 생성한 볼륨들
if docker volume ls | grep -q "mysql-data"; then
    echo "  - mysql-data 볼륨 삭제 중..."
    docker volume rm mysql-data 2>/dev/null
fi

# 사용하지 않는 볼륨 정리 (선택적)
read -p "사용하지 않는 Docker 볼륨도 정리하시겠습니까? (y/N): " cleanup_volumes
if [[ $cleanup_volumes == [yY] ]]; then
    echo "  - 사용하지 않는 볼륨 정리 중..."
    docker volume prune -f
fi

echo "5. 방화벽 규칙 정리 중..."

# Docker 방화벽 규칙 초기화 (권한 필요)
if [ "$EUID" -eq 0 ]; then
    echo "  - DOCKER-USER 체인 규칙 초기화 중..."
    iptables -F DOCKER-USER 2>/dev/null || true
    echo "  ✅ 방화벽 규칙 초기화 완료"
else
    echo "  ⚠️ 방화벽 규칙 정리를 위해서는 sudo 권한이 필요합니다."
    echo "  수동으로 실행하세요: sudo iptables -F DOCKER-USER"
fi

echo "6. 실습 파일 정리 중..."

# 현재 디렉토리의 실습 파일들 정리 (선택적)
read -p "실습 중 생성된 파일들도 삭제하시겠습니까? (y/N): " cleanup_files
if [[ $cleanup_files == [yY] ]]; then
    echo "  - 실습 파일 삭제 중..."
    
    # 생성된 파일들
    files_to_remove=(
        "Dockerfile"
        "package.json"
        "server.js"
        "haproxy.cfg"
        "nginx.conf"
        "index.html"
        "*.pem"
        "*.csr"
        "*.cnf"
        "*.srl"
        "security_test_results.txt"
    )
    
    for file_pattern in "${files_to_remove[@]}"; do
        if ls $file_pattern 1> /dev/null 2>&1; then
            rm -f $file_pattern
            echo "    - $file_pattern 삭제됨"
        fi
    done
    
    # 생성된 디렉토리들
    dirs_to_remove=(
        "configs"
        "logs"
        "scripts"
        "ssl"
    )
    
    for dir in "${dirs_to_remove[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            echo "    - $dir/ 디렉토리 삭제됨"
        fi
    done
fi

echo "7. 시스템 상태 확인..."

# 정리 후 상태 확인
echo ""
echo "📊 정리 후 시스템 상태:"
echo "========================"

echo "남은 컨테이너:"
remaining_containers=$(docker ps -a --format "{{.Names}}" | grep -E "(mysql|redis|api-server|load-balancer|web-server|security|monitor|analyzer)" | wc -l)
if [ $remaining_containers -eq 0 ]; then
    echo "✅ 실습 컨테이너 모두 정리됨"
else
    echo "⚠️ $remaining_containers 개의 컨테이너가 남아있습니다:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(mysql|redis|api-server|load-balancer|web-server|security|monitor|analyzer)"
fi

echo ""
echo "남은 네트워크:"
remaining_networks=$(docker network ls --format "{{.Name}}" | grep -E "(frontend-net|backend-net|database-net|monitoring-net)" | wc -l)
if [ $remaining_networks -eq 0 ]; then
    echo "✅ 실습 네트워크 모두 정리됨"
else
    echo "⚠️ $remaining_networks 개의 네트워크가 남아있습니다:"
    docker network ls | grep -E "(frontend-net|backend-net|database-net|monitoring-net)"
fi

echo ""
echo "남은 볼륨:"
remaining_volumes=$(docker volume ls --format "{{.Name}}" | grep -E "(mysql-data)" | wc -l)
if [ $remaining_volumes -eq 0 ]; then
    echo "✅ 실습 볼륨 모두 정리됨"
else
    echo "⚠️ $remaining_volumes 개의 볼륨이 남아있습니다:"
    docker volume ls | grep -E "(mysql-data)"
fi

echo ""
echo "8. 추가 정리 옵션..."

# Docker 시스템 전체 정리 (선택적)
read -p "Docker 시스템 전체 정리를 실행하시겠습니까? (사용하지 않는 모든 리소스 삭제) (y/N): " system_prune
if [[ $system_prune == [yY] ]]; then
    echo "  - Docker 시스템 전체 정리 중..."
    docker system prune -a -f --volumes
    echo "  ✅ Docker 시스템 전체 정리 완료"
fi

echo ""
echo "=== Week 2 Day 1 실습 환경 정리 완료 ==="
echo ""
echo "🎉 정리 완료 사항:"
echo "✅ 모든 실습 컨테이너 삭제"
echo "✅ 모든 실습 네트워크 삭제"
echo "✅ 실습 이미지 정리"
echo "✅ 실습 볼륨 정리"
if [ "$EUID" -eq 0 ]; then
    echo "✅ 방화벽 규칙 초기화"
else
    echo "⚠️ 방화벽 규칙 수동 정리 필요"
fi

echo ""
echo "📋 수동 확인 사항:"
echo "1. 포트 사용 확인: netstat -tlnp | grep -E '(80|443|3306|6379|8080|8404|8888)'"
echo "2. 방화벽 규칙 확인: sudo iptables -L DOCKER-USER"
echo "3. Docker 상태 확인: docker ps -a"
echo "4. 네트워크 상태 확인: docker network ls"
echo ""
echo "🔄 다음 실습 준비:"
echo "- Week 2 Day 2: Docker 스토리지 & 데이터 관리"
echo "- 새로운 실습 환경에서 시작할 준비가 완료되었습니다!"