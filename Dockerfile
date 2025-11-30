# ---------- STAGE 1: build the jar using Maven ----------
FROM maven:3.9.4-eclipse-temurin-17 AS build
WORKDIR /workspace

# Copy only the files needed for dependency resolution first (cache)
COPY pom.xml .
# If you have other modules or parent poms, copia los que hagan falta
RUN mvn -B -DskipTests dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn -B -DskipTests package

# ---------- STAGE 2: create runtime image ----------
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Optional: create non-root user
# RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup
# USER appuser

# Copy jar from build stage
COPY --from=build /workspace/target/*.jar app.jar

# Optional: set JAVA_OPTS via environment
ENV JAVA_OPTS=" -Xms128m -Xmx512m "

EXPOSE 8080

# Healthcheck (simple)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
