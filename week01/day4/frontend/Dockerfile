# frontend/Dockerfile

# 빌드 스테이지
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 프로덕션 스테이지
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/build ./build
RUN npm install -g serve  # serve 글로벌 설치
EXPOSE 3000
CMD ["serve", "-s", "build", "-l", "3000"]