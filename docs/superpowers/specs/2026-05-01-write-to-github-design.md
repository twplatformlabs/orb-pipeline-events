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

## Progress & Debug Logging

The script emits step-by-step progress to `stdout` throughout execution so that pipeline logs provide a full audit trail. Each log line is prefixed with `[write_to_github]` for easy grepping. Example output for a four-file run:

```
[write_to_github] repo: owner/repo  branch: main
[write_to_github] resolved source pattern: ./deploy/*.yaml
[write_to_github] matched 4 files: app.yaml, web.yaml, worker.yaml, cron.yaml
[write_to_github] resolving branch tip for main...
[write_to_github] base commit: abc1234  base tree: def5678
[write_to_github] (1/4) preparing blob: app.yaml -> argocd/apps/app.yaml
[write_to_github] (1/4) blob created: sha=aaa111...
[write_to_github] (2/4) preparing blob: web.yaml -> argocd/apps/web.yaml
[write_to_github] (2/4) blob created: sha=bbb222...
[write_to_github] (3/4) preparing blob: worker.yaml -> argocd/apps/worker.yaml
[write_to_github] (3/4) blob created: sha=ccc333...
[write_to_github] (4/4) preparing blob: cron.yaml -> argocd/apps/cron.yaml
[write_to_github] (4/4) blob created: sha=ddd444...
[write_to_github] creating tree...
[write_to_github] tree created: sha=eee555...
[write_to_github] creating commit...
[write_to_github] commit created: sha=fff666...
[write_to_github] updating branch ref main...
[write_to_github] done. 4 file(s) committed to owner/repo@main as fff666...
```

**Token safety:** The GitHub token is never printed, logged, or included in any error output. API calls are constructed so the token appears only in the `Authorization` header, which is not echoed. If a `curl` command is logged (e.g., for debugging a failed call), the header value is redacted as `Authorization: Bearer ***`.
