# Repository Guidelines

## Project Structure & Module Organization

This repository currently contains planning and architecture documentation for a self-hosted video manager; application code, tests, and runtime assets have not been added.

- `README.md` describes product goals and the initial operating model.
- `api/` and `app/` contain placeholder READMEs. Their descriptions appear reversed: `api/README.md` describes React/Yarn, while `app/README.md` describes Kotlin/Gradle. Resolve this mismatch before scaffolding either module.
- `processor/` is the planned service for processing and creating videos. It currently contains only `README.md`; its implementation language, dependencies, and runtime commands are not yet defined.
- `docs/pages/` contains AsciiDoc pages, including C4, data, and sequence diagrams.
- `docs/partials/diagrams/c4/` holds shared Structurizr models and styles.
- `docs/antora.yml` defines documentation metadata; `docs/partials/nav.adoc` lists navigation links.

## Build, Test, and Development Commands

No build, local-server, test, or documentation-rendering command is configured. There is no package manifest, Gradle wrapper, or Antora playbook checked in.

Useful checks from the repository root:

- `git ls-files` — inspect tracked project files.
- `git diff --check` — check tracked edits for whitespace errors.
- `git diff --stat` — review the scope of tracked changes.

When introducing executable modules, document their setup, build, run, and test commands in the corresponding README.

## Coding Style & Naming Conventions

Use Markdown for READMEs and AsciiDoc for documentation pages. Follow existing heading and diagram-block conventions. Use descriptive, lowercase, hyphenated page names, such as `system-context.adoc`. Preserve four-space indentation in Structurizr DSL and reuse shared models and styles through includes. Update navigation when adding or renaming pages.

No formatter, linter, or application-language style configuration is present.

## Testing Guidelines

No automated testing framework, test naming convention, or coverage threshold exists yet. For documentation changes, verify relative includes, cross-references, and consistency between diagrams and product requirements. Existing navigation references `media-lineage.adoc`, but the tracked data page is `erd.adoc`; account for this mismatch when validating links. Add tests and document their conventions when introducing application behavior.

## Commit & Pull Request Guidelines

History uses short, plain-language subjects, such as “Update readme” and “Fixed typo”; no structured commit prefix convention is evident. Use concise, action-oriented messages describing the change.

For pull requests, describe the purpose, affected files, and validation performed. Link relevant issues when available, and include rendered previews for visual diagram changes when possible. Distinguish planned architecture from implemented behavior.
