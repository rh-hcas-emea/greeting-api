# builder image
FROM registry.access.redhat.com/ubi9/openjdk-17 as builder

# download dependencies first - improves development speeds due to caching
COPY --chown=default .mvn ./.mvn
COPY --chown=default pom.xml mvnw ./
RUN ./mvnw -B dependency:resolve

# build
COPY src ./src
COPY --chown=default src ./src
RUN ./mvnw package -B -DskipTests


# runtime image
FROM registry.access.redhat.com/ubi9/openjdk-17-runtime

## We make four distinct layers so if there are application changes the library layers can be re-used
COPY --chown=default --from=builder $HOME/target/quarkus-app/lib/ /deployments/lib/
COPY --chown=default --from=builder $HOME/target/quarkus-app/*.jar /deployments/
COPY --chown=default --from=builder $HOME/target/quarkus-app/app/ /deployments/app/
COPY --chown=default --from=builder $HOME/target/quarkus-app/quarkus/ /deployments/quarkus/
