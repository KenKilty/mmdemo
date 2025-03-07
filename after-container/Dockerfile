# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn package -DskipTests

# Run stage
FROM tomcat:9-jre17
RUN rm -rf /usr/local/tomcat/webapps/* && \
    apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copy application WAR and PostgreSQL driver
COPY --from=build /build/target/todo.war /usr/local/tomcat/webapps/todo.war
COPY --from=build /build/target/dependency/postgresql-42.7.2.jar /usr/local/tomcat/lib/

# Configure Tomcat
COPY docker/tomcat/server.xml /usr/local/tomcat/conf/
COPY docker/tomcat/logging.properties /usr/local/tomcat/conf/

EXPOSE 8080
CMD ["catalina.sh", "run"] 