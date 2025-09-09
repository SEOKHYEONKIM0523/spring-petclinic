# ----------------------------------------------------------------------------------
# Stage 1: Build the Spring PetClinic application (Build Stage)
# ----------------------------------------------------------------------------------
# 공식 Maven 이미지 사용 (JDK 17 포함, Gradle 대신 Maven 사용)
FROM maven:3.9.5-eclipse-temurin-17-alpine AS builder

# 작업 디렉토리 설정
WORKDIR /app

# Maven 캐싱을 위해 pom.xml 먼저 복사 및 의존성 다운로드 (빌드 속도 최적화)
COPY pom.xml .
RUN mvn dependency:go-offline

# 나머지 소스 코드 복사
COPY src ./src

# 애플리케이션 빌드
# -DskipTests: 개인 프로젝트 시 테스트를 건너뛰어 빌드 시간 단축 (실제 CI에서는 테스트 실행 권장)
RUN mvn package -DskipTests

# ----------------------------------------------------------------------------------
# Stage 2: Create the final lightweight runtime image (Run Stage)
# ----------------------------------------------------------------------------------
# 경량화된 OpenJDK JRE 이미지 사용
FROM eclipse-temurin:17-jre-alpine

# MAINTAINER (선택 사항)
LABEL maintainer="your-email@example.com"

# 타임존 설정 (선택 사항, 로그 시간 등이 한국 시간으로 표기)
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 작업 디렉토리 설정 (옵션)
WORKDIR /app

# builder 스테이지에서 빌드된 JAR 파일 복사
COPY --from=builder /app/target/*.jar app.jar

# 애플리케이션 실행 시 필요한 포트 설정 (Spring PetClinic 기본 8080)
EXPOSE 8080

# 컨테이너 실행 시 사용할 사용자 (보안 강화)
# 일반적으로 root가 아닌 유저를 생성하여 사용합니다.
RUN addgroup --system spring && adduser --system --ingroup spring spring
USER spring

# 애플리케이션 실행 명령
# java -jar 명령으로 Spring PetClinic 애플리케이션을 실행합니다.
# -Djava.security.egd=file:/dev/./urandom: 난수 생성 성능 향상 (Docker 환경에서 권장)
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
