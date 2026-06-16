# 톰캣 이미지 사용
FROM tomcat:10.0

# 기존 톰캣의 기본 페이지 삭제
RUN rm -rf /usr/local/tomcat/webapps/*

# 우리가 넣은 war 파일을 톰캣이 실행하는 경로로 복사
# deploy 폴더에 있는 파일을 복사해라!
COPY deploy/ROOT_260612.war /usr/local/tomcat/webapps/ROOT.war

# 톰캣 실행
CMD ["catalina.sh", "run"]