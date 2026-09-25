# Application API

The API foundation is a standalone Kotlin/Spring Boot project with MySQL connectivity, Liquibase initialization, and health endpoints. Catalog, draft, output-lineage, and YouTube monitoring features remain planned.

See the [foundation plan](../docs/plans/api-foundation-plan.md), [YouTube follow-up plan](../docs/plans/api-youtube-monitoring-plan.md), and [YouTube monitoring design](../docs/pages/api/youtube-monitoring.adoc).

## Prerequisites

- Java 21 for host development. Gradle 9.3.0 is provided by the committed wrapper; no global Gradle installation is needed.
- Docker Engine with Compose v2 or later, or a compatible Docker Desktop/Rancher Desktop installation. Docker must be running for integration tests.
- Available localhost ports 8080 and 3306 when using Compose.

The build uses Kotlin 2.3.20 and Spring Boot 4.1.1. Versions and dependency aliases live in `gradle/libs.versions.toml`. The `Makefile` uses ktlint to format Kotlin source, tests, and Gradle scripts.

## Configuration

From the repository root:

```sh
cp .env.example .env
```

Edit `.env` and set distinct, nonempty `MYSQL_PASSWORD` and `MYSQL_ROOT_PASSWORD` values. Neither password has a default. For compatibility with both Compose and the shell commands below, single-quote password values; avoid single quotes within the values. Keep `.env` local: Git ignores it and Docker excludes it from the build context.

| Variable | Default | Purpose |
| --- | --- | --- |
| `MYSQL_DATABASE` | `iota_video_manager` | Database created on first MySQL startup |
| `MYSQL_USER` | `iota` | Application database user |
| `MYSQL_HOST_PORT` | `3306` | MySQL's published host port for Compose and `make run` |
| `MYSQL_PASSWORD` | Required | Application database password |
| `MYSQL_ROOT_PASSWORD` | Required by Compose | MySQL initialization password; never passed to the API container |
| `SPRING_DATASOURCE_URL` | Derived from the configured host port and database name | Optional API connection override; Compose sets its own internal URL |

Compose supplies a JDBC URL using the `mysql` service hostname. `make run` uses `MYSQL_HOST_PORT` to connect from the host. If another local MySQL server occupies port 3306, set `MYSQL_HOST_PORT` to an available port in `.env` before starting Compose. JDBC timestamps use UTC. Changing configuration requires restarting the API. YouTube configuration is not needed for this milestone.

## Run API and database in Docker

From the repository root:

```sh
docker compose up --build --wait
curl --fail http://localhost:8080/actuator/health/readiness
docker compose logs -f api mysql
```

Compose starts MySQL 8.4, waits until the application user can query its database, and starts the API. Both services bind to localhost; the database uses `MYSQL_HOST_PORT` (default 3306). The API image runs as UID/GID 10001 and checks readiness automatically.

To stop services:

```sh
docker compose down
```

MySQL data persists in the named `mysql-data` volume across container recreation and ordinary shutdown. Updated password variables do not change users in an existing volume: update credentials in MySQL as well, or deliberately reset the disposable development database. `docker compose down --volumes` deletes that project's database data.

## Run the API on the host

From the repository root, stop any Compose API to free port 8080 and start only MySQL:

```sh
docker compose stop api
docker compose up -d --wait mysql
set -a
. ./.env
set +a
unset MYSQL_ROOT_PASSWORD
cd api
make run
```

`make run` formats Kotlin and runs `bootRun` with the `local` profile, which binds the API to `127.0.0.1`. It uses port 8080 by default; set `SERVER_PORT` to choose another port. Spring reads exported environment variables; it does not automatically load `.env`. The root password is only needed by the MySQL container. To return to container execution, stop `make run` and run `docker compose up --build --wait` from the repository root.

## Build and test

From `api/`:

```sh
make help
make format
make check
make build
```

`make check` formats and runs Gradle verification, including ktlint checks and integration tests. `make build` formats and runs the full Gradle build; its executable artifact is `build/libs/api.jar`. `make clean` removes build output, while `make dependencies` lists resolved dependencies. The same Gradle tasks can be run directly with `./gradlew`. With the environment exported as for `make run`, start the packaged JAR using `java -jar build/libs/api.jar --spring.profiles.active=local`.

Tests use JUnit and MySQL Testcontainers with random database ports and temporary credentials. They require a working Docker daemon, without `.env`, a manually started database, or external API credentials. `ApiApplicationTest` checks first and repeated startup, the empty business schema, restricted health exposure, and database failure making readiness fail while liveness remains healthy. Test reports are in `build/reports/tests/test/index.html`.

Build the container independently from the repository root:

```sh
docker build -t iota-video-manager-api ./api
```

The image build packages the application without running Docker-dependent integration tests. Run `./gradlew check` separately before using the image. To run a standalone image, supply the database URL and application credentials for a reachable MySQL instance:

```sh
docker run --rm -p 127.0.0.1:8080:8080 --env SPRING_DATASOURCE_URL --env MYSQL_USER --env MYSQL_PASSWORD iota-video-manager-api
```

Export these three variables first; `localhost` inside this container refers to the container itself. Compose handles service networking automatically and is the simplest local setup.

## Health and schema

| Endpoint | Meaning |
| --- | --- |
| `/actuator/health` | Overall application health, including MySQL |
| `/actuator/health/liveness` | Application lifecycle health, independent of MySQL |
| `/actuator/health/readiness` | Application readiness and successful database connectivity |

Probe responses expose status only (`{"status":"UP"}` on success), with HTTP 503 for unhealthy readiness. Overall health also lists the probe group names; no endpoint exposes component details. Other Actuator endpoints are not exposed. Authentication and business REST endpoints are deferred; the supplied Compose configuration binds only to localhost.

Liquibase runs during startup using `src/main/resources/db/changelog/db.changelog-master.yml`. The initial changelog is empty: only Liquibase bookkeeping tables are created. Add future schema changes as immutable, numbered changesets and include them explicitly in order. Hibernate validates the resulting schema and does not create or update it. Open Session in View is disabled.
