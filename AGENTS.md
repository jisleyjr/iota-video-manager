# Repository Guidelines

## Project Structure & Module Organization

This repository contains a runnable Kotlin/Spring Boot API foundation and planning/architecture documentation for a self-hosted video manager. Business workflows remain planned.

- `README.md` describes product goals and the initial operating model.
- `api/` is a standalone Kotlin/Gradle Spring Boot project with source, MySQL integration tests, a committed wrapper, and a version catalog. Its README documents setup, build, run, and test commands.
- `app/` contains the planned React/Yarn Creator Portal README; no frontend is scaffolded.
- `api/Dockerfile` packages the API using `api/` as its build context; root `docker-compose.yml` starts the API and MySQL 8.4. Local passwords belong in ignored `.env` files.
- `docs/plans/` contains the foundation plan and the deferred YouTube monitoring plan.
- `processor/` is the planned service for processing and creating videos. It currently contains only `README.md`; its implementation language, dependencies, and runtime commands are not yet defined.
- `docs/pages/` contains AsciiDoc pages, including C4, data, and sequence diagrams.
- `docs/partials/diagrams/c4/` holds shared Structurizr models and styles.
- `docs/antora.yml` defines documentation metadata; `docs/partials/nav.adoc` lists navigation links.

## Build, Test, and Development Commands

From `api/`, use `make help` to list commands, `make run` to format and start the local-profile API, `make check` for ktlint plus JUnit/MySQL Testcontainers tests, and `make build` to package the executable JAR. `make format`, `make clean`, and `make dependencies` cover formatting, build cleanup, and dependency listing. Tests require a running Docker daemon.

From the root, configure `.env` and use `docker compose up --build --wait` to start the API and database, or `docker compose up -d --wait mysql` for host API development. No frontend or documentation-rendering command is configured; no Antora playbook is checked in.

Useful checks from the repository root:

- `git ls-files` — inspect tracked project files.
- `git diff --check` — check tracked edits for whitespace errors.
- `git diff --stat` — review the scope of tracked changes.

When introducing executable modules, document their setup, build, run, and test commands in the corresponding README.

## Coding Style & Naming Conventions

Use Markdown for READMEs and AsciiDoc for documentation pages. Follow existing heading and diagram-block conventions. Use descriptive, lowercase, hyphenated page names, such as `system-context.adoc`. Preserve four-space indentation in Structurizr DSL and reuse shared models and styles through includes. Update navigation when adding or renaming pages.

Use four-space indentation in Kotlin and constructor injection. Keep dependencies/plugins in the Gradle version catalog. KtLint is configured through the Gradle plugin and `api/.editorconfig`; `formatKotlin` delegates to `ktlintFormat`.

## Testing Guidelines

API tests use JUnit and MySQL Testcontainers under `api/src/test/kotlin`, with `*Test` class names and descriptive Kotlin test names. No coverage threshold is configured. Test actual MySQL integration rather than substituting an in-memory database. For documentation changes, verify relative includes, cross-references, and consistency between diagrams and product requirements; the data page is `erd.adoc`.

## Commit & Pull Request Guidelines

History uses short, plain-language subjects, such as “Update readme” and “Fixed typo”; no structured commit prefix convention is evident. Use concise, action-oriented messages describing the change.

For pull requests, describe the purpose, affected files, and validation performed. Link relevant issues when available, and include rendered previews for visual diagram changes when possible. Distinguish planned architecture from implemented behavior.
