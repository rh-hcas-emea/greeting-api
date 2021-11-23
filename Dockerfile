####
# This Dockerfile is used in order to build a container that runs the Quarkus application in JVM mode
#
# Before building the container image run:
#
# ./mvnw package
#
# Then, build the image with:
#
# docker build -f src/main/docker/Dockerfile.jvm -t quarkus/greeting-service-jvm .
#
# Then run the container using:
#
# docker run -i --rm -p 8080:8080 quarkus/greeting-service-jvm
#
# If you want to include the debug port into your docker image
# you will have to expose the debug port (default 5005) like this :  EXPOSE 8080 5005
#
# Then run the container using :
#
# docker run -i --rm -p 8080:8080 -p 5005:5005 -e JAVA_ENABLE_DEBUG="true" quarkus/greeting-service-jvm
#
###
FROM registry.redhat.io/ubi8/openjdk-17 as builder

# download dependencies first - improves development speeds due to caching
COPY --chown=jboss .mvn ./.mvn
COPY --chown=jboss pom.xml mvnw ./
RUN ./mvnw dependency:resolve

# build
COPY --chown=jboss src ./src
RUN ./mvnw package -DskipTests

FROM registry.redhat.io/ubi8/openjdk-17-runtime

ARG RUN_JAVA_VERSION=1.3.8

USER 0

# Install the run-java script
RUN ls -la /deployments/ && curl https://repo1.maven.org/maven2/io/fabric8/run-java-sh/${RUN_JAVA_VERSION}/run-java-sh-${RUN_JAVA_VERSION}-sh.sh -o /deployments/run-java.sh \
    && chown jboss /deployments/run-java.sh \
    && chmod 540 /deployments/run-java.sh \
    && echo "securerandom.source=file:/dev/urandom" >> /etc/alternatives/jre/conf/security/java.security \

## Configure the JAVA_OPTIONS, you can add -XshowSettings:vm to also display the heap size.
ENV JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"

## We make four distinct layers so if there are application changes the library layers can be re-used
COPY --chown=1001 --from=builder $HOME/target/quarkus-app/lib/ /deployments/lib/
COPY --chown=1001 --from=builder $HOME/target/quarkus-app/*.jar /deployments/
COPY --chown=1001 --from=builder $HOME/target/quarkus-app/app/ /deployments/app/
COPY --chown=1001 --from=builder $HOME/target/quarkus-app/quarkus/ /deployments/quarkus/

EXPOSE 8080
USER jboss
ENTRYPOINT [ "/deployments/run-java.sh" ]