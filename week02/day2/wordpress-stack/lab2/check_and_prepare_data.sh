#!/bin/bash

# Week 2 Day 2 Lab 2: 데이터 확인 및 준비
# 사용법: ./check_and_prepare_data.sh

echo "=== 데이터베이스 상태 확인 및 준비 ==="

# WordPress 데이터베이스 연결 확인
echo "1. 데이터베이스 연결 확인 중..."
if docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ 데이터베이스 연결 성공"
else
    echo "❌ 데이터베이스 연결 실패"
    exit 1
fi

# 현재 데이터베이스 상태 확인
echo "2. 현재 데이터베이스 상태 확인 중..."
TABLES=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "SHOW TABLES;" -s -N 2>/dev/null | wc -l)
echo "   테이블 수: ${TABLES}개"

if [ $TABLES -eq 0 ]; then
    echo "⚠️  WordPress 테이블이 없습니다. WordPress 초기 설정이 필요합니다."
    echo "   http://localhost 또는 http://localhost:8080 에 접속하여 WordPress를 설정해주세요."
    
    # WordPress 자동 설정 시도
    echo "3. WordPress 자동 설정 시도 중..."
    
    # WordPress CLI 설치 및 설정
    docker exec wordpress-app bash -c "
        # WP-CLI 다운로드
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
        
        # WordPress 설정
        cd /var/www/html
        wp core install --url='http://localhost' --title='Test WordPress Site' --admin_user='admin' --admin_password='admin123' --admin_email='admin@example.com' --allow-root
        
        # 테스트 포스트 생성
        wp post create --post_type=post --post_title='Welcome to WordPress' --post_content='This is your first WordPress post for backup testing.' --post_status=publish --allow-root
        wp post create --post_type=post --post_title='Backup Test Post' --post_content='This post is created for testing the backup system.' --post_status=publish --allow-root
        wp post create --post_type=page --post_title='About Us' --post_content='This is the about us page for testing.' --post_status=publish --allow-root
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ WordPress 자동 설정 완료"
    else
        echo "⚠️  WordPress 자동 설정 실패. 수동 설정이 필요합니다."
    fi
else
    echo "✅ WordPress 테이블 존재"
    
    # 포스트 수 확인
    POSTS=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "SELECT COUNT(*) FROM wp_posts WHERE post_status='publish';" -s -N 2>/dev/null)
    echo "   게시된 포스트 수: ${POSTS}개"
    
    if [ $POSTS -lt 2 ]; then
        echo "3. 테스트 데이터 추가 중..."
        docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "
            INSERT INTO wp_posts (post_author, post_date, post_date_gmt, post_content, post_title, post_excerpt, post_status, comment_status, ping_status, post_password, post_name, to_ping, pinged, post_modified, post_modified_gmt, post_content_filtered, post_parent, guid, menu_order, post_type, post_mime_type, comment_count) 
            VALUES 
            (1, NOW(), UTC_TIMESTAMP(), 'This is a test post for backup system validation.', 'Backup Test Post 1', '', 'publish', 'open', 'open', '', 'backup-test-post-1', '', '', NOW(), UTC_TIMESTAMP(), '', 0, '', 0, 'post', '', 0),
            (1, NOW(), UTC_TIMESTAMP(), 'This is another test post for backup system validation.', 'Backup Test Post 2', '', 'publish', 'open', 'open', '', 'backup-test-post-2', '', '', NOW(), UTC_TIMESTAMP(), '', 0, '', 0, 'post', '', 0),
            (1, NOW(), UTC_TIMESTAMP(), 'This is a test page for backup system validation.', 'Test Page', '', 'publish', 'closed', 'closed', '', 'test-page', '', '', NOW(), UTC_TIMESTAMP(), '', 0, '', 0, 'page', '', 0);
        " 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ 테스트 데이터 추가 완료"
        else
            echo "⚠️  테스트 데이터 추가 실패"
        fi
    fi
fi

# 최종 데이터베이스 상태 확인
echo "4. 최종 데이터베이스 상태 확인..."
FINAL_TABLES=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "SHOW TABLES;" -s -N 2>/dev/null | wc -l)
FINAL_POSTS=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword wordpress -e "SELECT COUNT(*) FROM wp_posts WHERE post_status='publish';" -s -N 2>/dev/null || echo 0)

echo "   최종 테이블 수: ${FINAL_TABLES}개"
echo "   최종 포스트 수: ${FINAL_POSTS}개"

# 데이터베이스 크기 확인
DB_SIZE=$(docker exec mysql-wordpress mysql -u wpuser -pwppassword -e "
    SELECT ROUND(SUM(data_length + index_length) / 1024, 2) AS 'DB Size (KB)' 
    FROM information_schema.tables 
    WHERE table_schema='wordpress';
" -s -N 2>/dev/null || echo 0)

echo "   데이터베이스 크기: ${DB_SIZE} KB"

# WordPress 파일 상태 확인
echo "5. WordPress 파일 상태 확인..."
WP_FILES=$(docker exec wordpress-app find /var/www/html/wp-content -type f | wc -l 2>/dev/null || echo 0)
WP_SIZE=$(docker exec wordpress-app du -sk /var/www/html/wp-content 2>/dev/null | cut -f1 || echo 0)

echo "   wp-content 파일 수: ${WP_FILES}개"
echo "   wp-content 크기: ${WP_SIZE} KB"

# 백업 준비 상태 확인
echo ""
echo "======================================"
echo "        백업 준비 상태 요약"
echo "======================================"

if [ $FINAL_TABLES -gt 10 ] && [ $FINAL_POSTS -gt 0 ]; then
    echo "✅ 데이터베이스: 백업 준비 완료"
    echo "   - 테이블: ${FINAL_TABLES}개"
    echo "   - 포스트: ${FINAL_POSTS}개"
    echo "   - 크기: ${DB_SIZE} KB"
else
    echo "⚠️  데이터베이스: 데이터 부족"
    echo "   WordPress 초기 설정을 완료해주세요."
fi

if [ $WP_FILES -gt 10 ] && [ $WP_SIZE -gt 100 ]; then
    echo "✅ WordPress 파일: 백업 준비 완료"
    echo "   - 파일: ${WP_FILES}개"
    echo "   - 크기: ${WP_SIZE} KB"
else
    echo "⚠️  WordPress 파일: 파일 부족"
fi

echo ""
echo "백업 시스템 테스트를 계속 진행할 수 있습니다."
echo "다음 명령어로 백업을 실행하세요:"
echo "  ./setup_backup_system.sh"