#!/bin/bash

# Week 2 Day 1 Lab 2: SSL/TLS 인증서 생성 스크립트
# 사용법: ./generate_ssl.sh

echo "=== SSL/TLS 인증서 생성 시작 ==="

# CA 개인키 생성
echo "1. CA 개인키 생성 중..."
openssl genrsa -out ca-key.pem 4096

# CA 인증서 생성
echo "2. CA 인증서 생성 중..."
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=DevOps Lab/OU=Security/CN=Lab CA"

# 서버 개인키 생성
echo "3. 서버 개인키 생성 중..."
openssl genrsa -out server-key.pem 4096

# 서버 인증서 요청 생성
echo "4. 서버 인증서 요청 생성 중..."
openssl req -subj "/C=KR/ST=Seoul/L=Seoul/O=DevOps Lab/OU=Security/CN=localhost" \
  -sha256 -new -key server-key.pem -out server.csr

# 서버 인증서 생성
echo "5. 서버 인증서 생성 중..."
echo "subjectAltName = DNS:localhost,IP:127.0.0.1,IP:172.20.1.10" > extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -out server-cert.pem -extfile extfile.cnf -CAcreateserial

# 클라이언트 개인키 생성
echo "6. 클라이언트 개인키 생성 중..."
openssl genrsa -out client-key.pem 4096

# 클라이언트 인증서 요청 생성
echo "7. 클라이언트 인증서 요청 생성 중..."
openssl req -subj '/C=KR/ST=Seoul/L=Seoul/O=DevOps Lab/OU=Security/CN=client' \
  -new -key client-key.pem -out client.csr

# 클라이언트 인증서 생성
echo "8. 클라이언트 인증서 생성 중..."
echo "extendedKeyUsage = clientAuth" > extfile-client.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -out client-cert.pem -extfile extfile-client.cnf -CAcreateserial

# 권한 설정
chmod 400 ca-key.pem server-key.pem client-key.pem
chmod 444 ca.pem server-cert.pem client-cert.pem

# SSL 인증서를 하나의 파일로 결합 (HAProxy용)
cat server-cert.pem server-key.pem > ssl/server.pem

# 임시 파일 정리
rm -f server.csr client.csr extfile.cnf extfile-client.cnf ca.srl

echo "=== SSL/TLS 인증서 생성 완료 ==="
echo ""
echo "생성된 인증서 파일:"
ls -la *.pem
echo ""
echo "✅ 인증서 정보:"
echo "- CA 인증서: ca.pem"
echo "- 서버 인증서: server-cert.pem"
echo "- 서버 개인키: server-key.pem"
echo "- 클라이언트 인증서: client-cert.pem"
echo "- HAProxy용 결합 파일: ssl/server.pem"