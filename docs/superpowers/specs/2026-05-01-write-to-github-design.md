# Design: write_to_github.sh

**Date:** 2026-05-01
**Status:** Approved

## Purpose

A bash script for use in application pipelines (e.g., CircleCI) that writes one or more files directly into a GitHub repository using the GitHub API, without cloning the repo. The primary use case is updating Argo CD configuration files in a GitOps repository as part of a CD pipeline.

## Interface

```sh
write_to_github.sh [OPTIONS] <source-pattern> <target-pattern>
```

### Positional Arguments

| Argument | Description |
|---|---|
| `<source-pattern>` | Local path, wildcard optional. E.g., `./deploy/*.yaml` or `./deploy/app.yaml` |
| `<target-pattern>` | Repo path, wildcard optional. E.g., `argocd/apps/*.yaml` or `argocd/apps/frontend.yaml` |

### Named Options

| Option | Required | Default | Description |
|---|---|---|---|
| `--repo` | yes | — | Target repository in `owner/repo` format |
| `--branch` | no | `main` | Branch to commit to |
| `--token` | no | `$GITHUB_TOKEN` | GitHub personal access token |
| `--message` / `-m` | no | — | Text appended to the auto-generated commit message |
| `--message-only` / `-M` | no | — | Replaces the auto-generated commit message entirely |

### Wildcard Stem Mapping

The `*` in the source pattern captures a stem. That stem is substituted into the target pattern wherever `*` appears.

Examples:
- Source `./deploy/*.yaml`, target `argocd/apps/*.yaml` — `app.yaml` → `argocd/apps/app.yaml`
- Source `./deploy/*.yaml`, target `argocd/apps/*-prod.yaml` — `app.yaml` → `argocd/apps/app-prod.yaml`
- Source `./deploy/app.yaml`, target `argocd/apps/frontend.yaml` — simple create/replace with rename
- Source `./deploy/*.yaml`, target `argocd/apps/` (trailing `/`) — preserve filename under the target directory

Mismatched wildcard presence (one side has `*`, the other does not and is not a bare directory path) is an error. Source matches multiple files but target has no `*` and does not end in `/` is also an error (cannot write multiple files to a single path).

## GitHub API Flow

All files are written as a single atomic commit using the GitHub Git Data API:

1. **Resolve branch tip** — `GET /repos/{owner}/{repo}/git/ref/heads/{branch}` → current commit SHA
2. **Get base tree** — `GET /repos/{owner}/{repo}/git/commits/{commit-sha}` → tree SHA
3. **Create blobs** — for each matched file, `POST /repos/{owner}/{repo}/git/blobs` with base64-encoded content → blob SHA (sequential)
4. **Create tree** — `POST /repos/{owner}/{repo}/git/trees` with base tree SHA and array of `{path, mode: "100644", type: "blob", sha}` entries → new tree SHA
5. **Create commit** — `POST /repos/{owner}/{repo}/git/commits` with message, new tree SHA, and parent commit SHA → new commit SHA
6. **Update branch ref** — `PATCH /repos/{owner}/{repo}/git/refs/heads/{branch}` with new commit SHA

Dependencies: `curl` and `jq` must be present on `PATH`.

## Commit Message Logic

The auto-generated standard message is assembled from available runtime context:

```
[pipeline] update via write_to_github

git-sha: <GIT_COMMIT | CIRCLE_SHA1 | $(git rev-parse HEAD)>
build: <CIRCLE_BUILD_NUM | BUILD_NUMBER | CI_BUILD_NUMBER>
```

Fields with no available value are omitted.

| Flags used | Result |
|---|---|
| Neither | Standard message only |
| `--message "foo"` | Standard message + blank line + `foo` |
| `--message-only "foo"` | `foo` only, standard message discarded |
| Both `--message` and `--message-only` | Error |

## Error Handling

The script exits non-zero with a descriptive message to `stderr` for:

- Missing required parameters (`--repo`, source/target patterns, token not in param or `$GITHUB_TOKEN`)
- `--message` and `--message-only` both provided
- Source wildcard matches no files
- Mismatched wildcard presence between source and target (see Wildcard Stem Mapping)
- Any GitHub API call returns non-2xx — prints HTTP status code and response body
- `curl` or `jq` not found on `PATH` at startup

Normal output (confirmation of files committed, resulting commit SHA) is written to `stdout`.
