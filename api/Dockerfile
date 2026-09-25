# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /workspace/api
COPY gradlew gradlew.bat settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
RUN chmod +x gradlew
COPY src ./src
RUN --mount=type=cache,target=/root/.gradle ./gradlew --no-daemon bootJar

FROM eclipse-temurin:21-jre-jammy AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 iota \
    && useradd --uid 10001 --gid iota --no-create-home --shell /usr/sbin/nologin iota
WORKDIR /app
COPY --from=build --chown=iota:iota /workspace/api/build/libs/api.jar /app/api.jar
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=8s --start-period=60s --retries=6 \
    CMD curl --fail --silent --show-error --max-time 7 http://localhost:8080/actuator/health/readiness || exit 1
ENTRYPOINT ["java", "-jar", "/app/api.jar"]
