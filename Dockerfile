# 1. 가볍고 보안성이 높은 Alpine Linux 기반의 Node.js 공식 이미지 사용
FROM node:18-alpine

# 2. 컨테이너 내부의 작업 디렉토리 생성
WORKDIR /usr/src/app

# 3. 패키지 파일만 먼저 복사하여 의존성 설치 (캐시 최적화)
COPY package*.json ./
RUN npm install --production

# 4. 나머지 모든 소스 코드 복사
COPY . .

# 5. 컨테이너가 사용할 포트 명시 (코드의 포트와 동일해야 함)
EXPOSE 8080

# 6. 서버 실행 명령어
CMD [ "npm", "start" ]