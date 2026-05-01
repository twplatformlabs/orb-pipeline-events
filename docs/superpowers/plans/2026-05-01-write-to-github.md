# write_to_github.sh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a bash script that atomically writes one or more local files into a GitHub repository using the Git Data API, with wildcard source/target path mapping, auto-generated commit messages, and verbose progress logging.

**Architecture:** Single bash script that reads parameters from environment variables (CircleCI orb convention — parameters are injected as env vars from `<<include(...)>>` inlining). Functions are isolated and independently testable via a sourcing guard. Only `curl` and `jq` required. A CircleCI orb command YAML wraps the script for pipeline use.

**Tech Stack:** bash, curl, jq, bats-core (testing)

---

## File Structure

| File | Purpose |
|---|---|
| `src/scripts/write_to_github.sh` | Main script: validation, glob expansion, target mapping, commit message, GitHub API calls |
| `src/commands/write-to-github.yml` | CircleCI orb command — inlines the script and maps orb params to env vars |
| `src/tests/write_to_github.bats` | bats-core test suite |

## Environment Variables (Script Interface)

| Variable | Required | Default | Description |
|---|---|---|---|
| `REPOSITORY` | yes | — | Target repo in `owner/repo` format |
| `SOURCE` | yes | — | Local path, wildcard optional (e.g. `./deploy/*.yaml`) |
| `DESTINATION` | yes | — | Repo path, wildcard optional (e.g. `argocd/apps/*.yaml`) |
| `BRANCH` | no | `main` | Branch to commit to |
| `GITHUB_TOKEN` or `GH_TOKEN` | yes | — | GitHub personal access token |
| `COMMIT_MESSAGE` | no | `""` | Text appended to (or replaces) the auto-generated message |
| `MESSAGE_ONLY` | no | `false` | When `true`, use `COMMIT_MESSAGE` as the entire commit message |

---

### Task 1: Script skeleton — logging, dependency check, sourcing guard

**Files:**
- Create: `src/scripts/write_to_github.sh`
- Create: `src/tests/write_to_github.bats`

- [ ] **Step 1: Create the script skeleton**

Create `src/scripts/write_to_github.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Logging ---

log() {
  echo "[write_to_github] $*"
}

die() {
  echo "[write_to_github] ERROR: $*" >&2
  exit 1
}

# --- Dependency check ---

check_deps() {
  local missing=()
  for cmd in curl jq base64; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  [[ ${#missing[@]} -gt 0 ]] && die "missing required dependencies: ${missing[*]}"
}

# --- Main (populated in later tasks) ---

main() {
  check_deps
  log "starting"
}

# Sourcing guard: allows functions to be tested without executing main
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
```

- [ ] **Step 2: Make the script executable**

```bash
chmod +x src/scripts/write_to_github.sh
```

- [ ] **Step 3: Install bats-core**

```bash
brew install bats-core
```

- [ ] **Step 4: Create the test file**

Create `src/tests/write_to_github.bats`:

```bash
#!/usr/bin/env bats

SCRIPT="${BATS_TEST_DIRNAME}/../scripts/write_to_github.sh"

setup() {
  # Source the script to make all functions available without running main
  # shellcheck source=/dev/null
  source "$SCRIPT"
}

# --- check_deps ---

@test "check_deps: passes when curl, jq, base64 are present" {
  run check_deps
  [ "$status" -eq 0 ]
}

@test "check_deps: fails with message when a dependency is missing" {
  PATH=/dev/null run check_deps
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing required dependencies"* ]]
}
```

- [ ] **Step 5: Run tests — expect both to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected:
```
 ✓ check_deps: passes when curl, jq, base64 are present
 ✓ check_deps: fails with message when a dependency is missing

2 tests, 0 failures
```

- [ ] **Step 6: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add write_to_github script skeleton with dependency check"
```

---

### Task 2: Input validation

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write failing tests**

Append to `src/tests/write_to_github.bats`:

```bash
# --- validate_inputs ---

@test "validate_inputs: passes with all required vars set" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/app.yaml"
  export DESTINATION="argocd/apps/app.yaml"
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -eq 0 ]
}

@test "validate_inputs: fails when REPOSITORY is missing" {
  unset REPOSITORY
  export SOURCE="./deploy/app.yaml"
  export DESTINATION="argocd/apps/app.yaml"
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"REPOSITORY"* ]]
}

@test "validate_inputs: fails when SOURCE is missing" {
  export REPOSITORY="owner/repo"
  unset SOURCE
  export DESTINATION="argocd/apps/app.yaml"
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"SOURCE"* ]]
}

@test "validate_inputs: fails when DESTINATION is missing" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/app.yaml"
  unset DESTINATION
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"DESTINATION"* ]]
}

@test "validate_inputs: accepts GH_TOKEN when GITHUB_TOKEN is absent" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/app.yaml"
  export DESTINATION="argocd/apps/app.yaml"
  unset GITHUB_TOKEN
  export GH_TOKEN="ghp_fallback"
  run validate_inputs
  [ "$status" -eq 0 ]
}

@test "validate_inputs: fails when no token is set" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/app.yaml"
  export DESTINATION="argocd/apps/app.yaml"
  unset GITHUB_TOKEN
  unset GH_TOKEN
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"token"* ]]
}

@test "validate_inputs: fails when source has wildcard but destination has none and is not a directory path" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/*.yaml"
  export DESTINATION="argocd/apps/app.yaml"
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"wildcard"* ]]
}

@test "validate_inputs: passes when source has wildcard and destination ends with /" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/*.yaml"
  export DESTINATION="argocd/apps/"
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -eq 0 ]
}

@test "validate_inputs: fails when destination has wildcard but source does not" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/app.yaml"
  export DESTINATION="argocd/apps/*.yaml"
  export GITHUB_TOKEN="tok"
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"wildcard"* ]]
}

@test "validate_inputs: fails when MESSAGE_ONLY is true but COMMIT_MESSAGE is empty" {
  export REPOSITORY="owner/repo"
  export SOURCE="./deploy/app.yaml"
  export DESTINATION="argocd/apps/app.yaml"
  export GITHUB_TOKEN="tok"
  export MESSAGE_ONLY="true"
  export COMMIT_MESSAGE=""
  run validate_inputs
  [ "$status" -ne 0 ]
  [[ "$output" == *"COMMIT_MESSAGE"* ]]
}
```

- [ ] **Step 2: Run to confirm failures**

```bash
bats src/tests/write_to_github.bats
```

Expected: all new tests fail with `validate_inputs: command not found`.

- [ ] **Step 3: Implement `validate_inputs` in the script**

Add after `check_deps` in `src/scripts/write_to_github.sh`:

```bash
# --- Input validation ---

validate_inputs() {
  [[ -z "${REPOSITORY:-}" ]]  && die "REPOSITORY is required (owner/repo)"
  [[ -z "${SOURCE:-}" ]]      && die "SOURCE is required"
  [[ -z "${DESTINATION:-}" ]] && die "DESTINATION is required"

  # Consolidate token: GITHUB_TOKEN takes precedence, fall back to GH_TOKEN
  GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  [[ -z "${GITHUB_TOKEN:-}" ]] && die "a GitHub token is required: set GITHUB_TOKEN or GH_TOKEN"

  BRANCH="${BRANCH:-main}"
  COMMIT_MESSAGE="${COMMIT_MESSAGE:-}"
  MESSAGE_ONLY="${MESSAGE_ONLY:-false}"

  # MESSAGE_ONLY requires a message
  [[ "$MESSAGE_ONLY" == "true" && -z "$COMMIT_MESSAGE" ]] \
    && die "MESSAGE_ONLY=true requires COMMIT_MESSAGE to be set"

  # Wildcard consistency
  local src_glob=false tgt_glob=false
  [[ "$SOURCE"      == *"*"* ]] && src_glob=true
  [[ "$DESTINATION" == *"*"* ]] && tgt_glob=true

  if [[ "$src_glob" == true && "$tgt_glob" == false && "$DESTINATION" != */ ]]; then
    die "SOURCE has a wildcard but DESTINATION has no wildcard and is not a directory path (ending in /)"
  fi
  if [[ "$src_glob" == false && "$tgt_glob" == true ]]; then
    die "DESTINATION has a wildcard but SOURCE does not"
  fi
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add validate_inputs with wildcard and token checks"
```

---

### Task 3: Source expansion and target mapping

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write failing tests**

Append to `src/tests/write_to_github.bats`:

```bash
# --- expand_sources ---

setup_files() {
  TMPFILES=$(mktemp -d)
  touch "$TMPFILES/app.yaml" "$TMPFILES/web.yaml" "$TMPFILES/worker.yaml"
}

teardown_files() {
  rm -rf "$TMPFILES"
}

@test "expand_sources: returns matching files for wildcard SOURCE" {
  setup_files
  export SOURCE="$TMPFILES/*.yaml"
  run expand_sources
  [ "$status" -eq 0 ]
  [[ "$output" == *"app.yaml"* ]]
  [[ "$output" == *"web.yaml"* ]]
  teardown_files
}

@test "expand_sources: returns single file when SOURCE has no wildcard" {
  setup_files
  export SOURCE="$TMPFILES/app.yaml"
  run expand_sources
  [ "$status" -eq 0 ]
  [[ "$output" == *"app.yaml"* ]]
  teardown_files
}

@test "expand_sources: fails when wildcard matches nothing" {
  export SOURCE="/nonexistent/*.yaml"
  run expand_sources
  [ "$status" -ne 0 ]
  [[ "$output" == *"no files matched"* ]]
}

@test "expand_sources: fails when single file does not exist" {
  export SOURCE="/nonexistent/app.yaml"
  run expand_sources
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

# --- map_target ---

@test "map_target: no wildcard in either — returns destination as-is" {
  run map_target "./deploy/app.yaml" "./deploy/app.yaml" "argocd/apps/frontend.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "argocd/apps/frontend.yaml" ]
}

@test "map_target: wildcard in both — substitutes stem" {
  run map_target "./deploy/app.yaml" "./deploy/*.yaml" "argocd/apps/*.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "argocd/apps/app.yaml" ]
}

@test "map_target: wildcard with rename — stem substituted into new name" {
  run map_target "./deploy/app.yaml" "./deploy/*.yaml" "argocd/apps/*-prod.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "argocd/apps/app-prod.yaml" ]
}

@test "map_target: destination ends with / — preserves source filename" {
  run map_target "./deploy/app.yaml" "./deploy/*.yaml" "argocd/apps/"
  [ "$status" -eq 0 ]
  [ "$output" = "argocd/apps/app.yaml" ]
}

@test "map_target: stem with no extension in source pattern" {
  run map_target "./deploy/web-service.yaml" "./deploy/*.yaml" "argocd/apps/*-prod.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "argocd/apps/web-service-prod.yaml" ]
}
```

- [ ] **Step 2: Run to confirm failures**

```bash
bats src/tests/write_to_github.bats
```

Expected: new tests fail with `expand_sources: command not found` and `map_target: command not found`.

- [ ] **Step 3: Implement `expand_sources` and `map_target`**

Add after `validate_inputs` in `src/scripts/write_to_github.sh`:

```bash
# --- Source expansion ---

expand_sources() {
  if [[ "$SOURCE" == *"*"* ]]; then
    local files=()
    shopt -s nullglob
    # shellcheck disable=SC2206
    files=( $SOURCE )
    shopt -u nullglob
    [[ ${#files[@]} -eq 0 ]] && die "no files matched source pattern: $SOURCE"
    printf '%s\n' "${files[@]}"
  else
    [[ -f "$SOURCE" ]] || die "source file not found: $SOURCE"
    echo "$SOURCE"
  fi
}

# map_target <file> <source_pattern> <destination_pattern>
# Outputs the target repo path for the given local file.
map_target() {
  local file="$1"
  local src_pat="$2"
  local tgt_pat="$3"

  # No wildcard in either side: destination is literal
  if [[ "$src_pat" != *"*"* && "$tgt_pat" != *"*"* ]]; then
    echo "$tgt_pat"
    return
  fi

  # Destination is a directory path: preserve the source filename
  if [[ "$tgt_pat" == */ ]]; then
    echo "${tgt_pat}$(basename "$file")"
    return
  fi

  # Extract stem: strip the prefix and suffix defined by the source pattern's *
  local prefix="${src_pat%%\**}"
  local suffix="${src_pat##*\*}"
  local stem="${file#"$prefix"}"
  stem="${stem%"$suffix"}"

  # Substitute stem into the target pattern
  echo "${tgt_pat/\*/$stem}"
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add source expansion and wildcard target mapping"
```

---

### Task 4: Commit message builder

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write failing tests**

Append to `src/tests/write_to_github.bats`:

```bash
# --- build_commit_message ---

@test "build_commit_message: returns standard message when COMMIT_MESSAGE and MESSAGE_ONLY are unset" {
  unset COMMIT_MESSAGE GIT_COMMIT CIRCLE_SHA1 CIRCLE_BUILD_NUM BUILD_NUMBER CI_BUILD_NUMBER
  export MESSAGE_ONLY="false"
  export COMMIT_MESSAGE=""
  run build_commit_message
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pipeline] update via write_to_github"* ]]
}

@test "build_commit_message: includes git sha from GIT_COMMIT when set" {
  export MESSAGE_ONLY="false"
  export COMMIT_MESSAGE=""
  export GIT_COMMIT="abc1234"
  unset CIRCLE_SHA1
  run build_commit_message
  [ "$status" -eq 0 ]
  [[ "$output" == *"git-sha: abc1234"* ]]
}

@test "build_commit_message: falls back to CIRCLE_SHA1 when GIT_COMMIT is absent" {
  export MESSAGE_ONLY="false"
  export COMMIT_MESSAGE=""
  unset GIT_COMMIT
  export CIRCLE_SHA1="sha999"
  run build_commit_message
  [ "$status" -eq 0 ]
  [[ "$output" == *"git-sha: sha999"* ]]
}

@test "build_commit_message: includes build number from CIRCLE_BUILD_NUM" {
  export MESSAGE_ONLY="false"
  export COMMIT_MESSAGE=""
  unset GIT_COMMIT CIRCLE_SHA1
  export CIRCLE_BUILD_NUM="42"
  unset BUILD_NUMBER CI_BUILD_NUMBER
  run build_commit_message
  [ "$status" -eq 0 ]
  [[ "$output" == *"build: 42"* ]]
}

@test "build_commit_message: appends COMMIT_MESSAGE when MESSAGE_ONLY is false" {
  export MESSAGE_ONLY="false"
  export COMMIT_MESSAGE="deploy app v1.2.3"
  unset GIT_COMMIT CIRCLE_SHA1 CIRCLE_BUILD_NUM BUILD_NUMBER CI_BUILD_NUMBER
  run build_commit_message
  [ "$status" -eq 0 ]
  [[ "$output" == *"[pipeline] update via write_to_github"* ]]
  [[ "$output" == *"deploy app v1.2.3"* ]]
}

@test "build_commit_message: returns only COMMIT_MESSAGE when MESSAGE_ONLY is true" {
  export MESSAGE_ONLY="true"
  export COMMIT_MESSAGE="custom message only"
  run build_commit_message
  [ "$status" -eq 0 ]
  [ "$output" = "custom message only" ]
}

@test "build_commit_message: omits git-sha line when no SHA env var is set and not in git repo" {
  export MESSAGE_ONLY="false"
  export COMMIT_MESSAGE=""
  unset GIT_COMMIT CIRCLE_SHA1
  # Run from a temp dir that is not a git repo so git rev-parse HEAD fails
  cd "$(mktemp -d)"
  run build_commit_message
  [ "$status" -eq 0 ]
  [[ "$output" != *"git-sha:"* ]]
}
```

- [ ] **Step 2: Run to confirm failures**

```bash
bats src/tests/write_to_github.bats
```

Expected: new tests fail with `build_commit_message: command not found`.

- [ ] **Step 3: Implement `build_commit_message`**

Add after `map_target` in `src/scripts/write_to_github.sh`:

```bash
# --- Commit message ---

build_commit_message() {
  if [[ "${MESSAGE_ONLY:-false}" == "true" ]]; then
    echo "$COMMIT_MESSAGE"
    return
  fi

  # Resolve git SHA from available env vars or local git
  local git_sha=""
  if [[ -n "${GIT_COMMIT:-}" ]]; then
    git_sha="$GIT_COMMIT"
  elif [[ -n "${CIRCLE_SHA1:-}" ]]; then
    git_sha="$CIRCLE_SHA1"
  else
    git_sha=$(git rev-parse HEAD 2>/dev/null || true)
  fi

  # Resolve build number from available CI env vars
  local build_num=""
  for var in CIRCLE_BUILD_NUM BUILD_NUMBER CI_BUILD_NUMBER; do
    if [[ -n "${!var:-}" ]]; then
      build_num="${!var}"
      break
    fi
  done

  local msg="[pipeline] update via write_to_github"
  [[ -n "$git_sha"   ]] && msg+=$'\n'"git-sha: ${git_sha}"
  [[ -n "$build_num" ]] && msg+=$'\n'"build: ${build_num}"
  [[ -n "${COMMIT_MESSAGE:-}" ]] && msg+=$'\n\n'"${COMMIT_MESSAGE}"

  echo "$msg"
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add commit message builder with env var resolution"
```

---

### Task 5: GitHub API curl wrapper

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write failing tests**

Append to `src/tests/write_to_github.bats`:

```bash
# --- github_api ---

setup_mock_curl() {
  MOCK_DIR=$(mktemp -d)
  cat > "$MOCK_DIR/curl" << 'CURLEOF'
#!/usr/bin/env bash
# Minimal curl mock: writes MOCK_CURL_BODY to -o file, prints MOCK_CURL_STATUS
out_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out_file="$2"; shift 2 ;;
    -w) shift 2 ;;   # consume -w and its format string
    *)  shift ;;
  esac
done
[[ -n "$out_file" ]] && echo "${MOCK_CURL_BODY:-{}}" > "$out_file"
echo "${MOCK_CURL_STATUS:-200}"
CURLEOF
  chmod +x "$MOCK_DIR/curl"
  export PATH="$MOCK_DIR:$PATH"
}

@test "github_api: returns response body on 2xx" {
  setup_mock_curl
  export GITHUB_TOKEN="test-token"
  export MOCK_CURL_STATUS="201"
  export MOCK_CURL_BODY='{"sha":"abc123"}'
  run github_api POST "/repos/owner/repo/git/blobs" '{"content":"Zm9v","encoding":"base64"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"sha":"abc123"'* ]]
}

@test "github_api: dies with status and body on non-2xx" {
  setup_mock_curl
  export GITHUB_TOKEN="test-token"
  export MOCK_CURL_STATUS="404"
  export MOCK_CURL_BODY='{"message":"Not Found"}'
  run github_api GET "/repos/owner/repo/git/ref/heads/missing"
  [ "$status" -ne 0 ]
  [[ "$output" == *"404"* ]]
  [[ "$output" == *"Not Found"* ]]
}

@test "github_api: does not expose GITHUB_TOKEN in log output" {
  setup_mock_curl
  export GITHUB_TOKEN="super-secret-token"
  export MOCK_CURL_STATUS="200"
  export MOCK_CURL_BODY='{}'
  run github_api GET "/repos/owner/repo/git/ref/heads/main"
  [[ "$output" != *"super-secret-token"* ]]
}
```

- [ ] **Step 2: Run to confirm failures**

```bash
bats src/tests/write_to_github.bats
```

Expected: new tests fail with `github_api: command not found`.

- [ ] **Step 3: Implement `github_api`**

Add after `build_commit_message` in `src/scripts/write_to_github.sh`:

```bash
# --- GitHub API ---
# github_api <METHOD> <path> [body]
# Calls the GitHub API, logs the request (without exposing the token),
# and returns the response body. Dies on non-2xx.

github_api() {
  local method="$1"
  local path="$2"
  local body="${3:-}"

  local resp_file
  resp_file=$(mktemp)

  local curl_args=(
    -s
    -o "$resp_file"
    -w "%{http_code}"
    -X "$method"
    -H "Authorization: Bearer ${GITHUB_TOKEN}"
    -H "Content-Type: application/json"
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
  )
  [[ -n "$body" ]] && curl_args+=(--data "$body")
  curl_args+=("https://api.github.com${path}")

  log "  -> ${method} https://api.github.com${path}"

  local http_code
  http_code=$(curl "${curl_args[@]}")

  if [[ ! "$http_code" =~ ^2 ]]; then
    local resp_body
    resp_body=$(cat "$resp_file")
    rm -f "$resp_file"
    die "GitHub API error (HTTP ${http_code}) for ${method} ${path}: ${resp_body}"
  fi

  cat "$resp_file"
  rm -f "$resp_file"
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add github_api curl wrapper with token safety"
```

---

### Task 6: Branch tip, base tree, and blob creation

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write failing tests**

Append to `src/tests/write_to_github.bats`:

```bash
# --- get_branch_tip, get_base_tree, create_blob ---

@test "get_branch_tip: returns commit SHA from branch ref response" {
  # Direct call (no run) so the mock survives in the same shell context
  github_api() { echo '{"object":{"sha":"commit-abc123"}}'; }
  export REPOSITORY="owner/repo"
  export BRANCH="main"
  result=$(get_branch_tip)
  [ "$result" = "commit-abc123" ]
}

@test "get_base_tree: returns tree SHA from commit response" {
  github_api() { echo '{"tree":{"sha":"tree-def456"}}'; }
  export REPOSITORY="owner/repo"
  result=$(get_base_tree "commit-abc123")
  [ "$result" = "tree-def456" ]
}

@test "create_blob: returns blob SHA from blobs API response" {
  github_api() { echo '{"sha":"blob-ghi789"}'; }
  export REPOSITORY="owner/repo"
  local tmpfile
  tmpfile=$(mktemp)
  echo "hello" > "$tmpfile"
  result=$(create_blob "$tmpfile")
  [ "$result" = "blob-ghi789" ]
  rm -f "$tmpfile"
}
```

- [ ] **Step 2: Run to confirm failures**

```bash
bats src/tests/write_to_github.bats
```

Expected: new tests fail with command not found errors.

- [ ] **Step 3: Implement the three functions**

Add after `github_api` in `src/scripts/write_to_github.sh`:

```bash
# Returns the current commit SHA for $BRANCH in $REPOSITORY
get_branch_tip() {
  local response
  response=$(github_api GET "/repos/${REPOSITORY}/git/ref/heads/${BRANCH}")
  jq -r '.object.sha' <<< "$response"
}

# Returns the tree SHA for the given commit SHA
get_base_tree() {
  local commit_sha="$1"
  local response
  response=$(github_api GET "/repos/${REPOSITORY}/git/commits/${commit_sha}")
  jq -r '.tree.sha' <<< "$response"
}

# Creates a blob for the given local file; returns the blob SHA
create_blob() {
  local file="$1"
  local content
  content=$(base64 < "$file" | tr -d '\n')
  local payload
  payload=$(jq -n --arg content "$content" --arg encoding "base64" \
    '{"content": $content, "encoding": $encoding}')
  local response
  response=$(github_api POST "/repos/${REPOSITORY}/git/blobs" "$payload")
  jq -r '.sha' <<< "$response"
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add get_branch_tip, get_base_tree, create_blob API calls"
```

---

### Task 7: Tree creation, commit creation, and ref update

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write failing tests**

Append to `src/tests/write_to_github.bats`:

```bash
# --- create_tree, create_commit, update_ref ---

@test "create_tree: returns new tree SHA" {
  # Direct call so the github_api mock is visible in the same shell context
  github_api() { echo '{"sha":"newtree-abc"}'; }
  export REPOSITORY="owner/repo"
  local entries
  entries=$(jq -n '[{"path":"argocd/app.yaml","mode":"100644","type":"blob","sha":"blobsha"}]')
  result=$(create_tree "basetree-sha" "$entries")
  [ "$result" = "newtree-abc" ]
}

@test "create_commit: returns new commit SHA" {
  github_api() { echo '{"sha":"newcommit-def"}'; }
  export REPOSITORY="owner/repo"
  result=$(create_commit "newtree-abc" "parent-commit-sha" "my commit message")
  [ "$result" = "newcommit-def" ]
}

@test "update_ref: succeeds without error" {
  github_api() { echo '{"ref":"refs/heads/main"}'; }
  export REPOSITORY="owner/repo"
  export BRANCH="main"
  # Direct call; failure would cause a non-zero exit and fail the test
  update_ref "newcommit-def"
}
```

- [ ] **Step 2: Run to confirm failures**

```bash
bats src/tests/write_to_github.bats
```

Expected: new tests fail with command not found errors.

- [ ] **Step 3: Implement the three functions**

Add after `create_blob` in `src/scripts/write_to_github.sh`:

```bash
# Creates a new tree from a base tree SHA and a JSON array of tree entries.
# Returns the new tree SHA.
create_tree() {
  local base_tree_sha="$1"
  local tree_entries_json="$2"
  local payload
  payload=$(jq -n \
    --arg base_tree "$base_tree_sha" \
    --argjson tree "$tree_entries_json" \
    '{"base_tree": $base_tree, "tree": $tree}')
  local response
  response=$(github_api POST "/repos/${REPOSITORY}/git/trees" "$payload")
  jq -r '.sha' <<< "$response"
}

# Creates a commit from a tree SHA, a parent commit SHA, and a message.
# Returns the new commit SHA.
create_commit() {
  local tree_sha="$1"
  local parent_sha="$2"
  local message="$3"
  local payload
  payload=$(jq -n \
    --arg message "$message" \
    --arg tree "$tree_sha" \
    --arg parent "$parent_sha" \
    '{"message": $message, "tree": $tree, "parents": [$parent]}')
  local response
  response=$(github_api POST "/repos/${REPOSITORY}/git/commits" "$payload")
  jq -r '.sha' <<< "$response"
}

# Updates the branch ref to point to the given commit SHA.
update_ref() {
  local commit_sha="$1"
  local payload
  payload=$(jq -n --arg sha "$commit_sha" '{"sha": $sha}')
  github_api PATCH "/repos/${REPOSITORY}/git/refs/heads/${BRANCH}" "$payload" > /dev/null
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: add create_tree, create_commit, update_ref API calls"
```

---

### Task 8: Main orchestration

**Files:**
- Modify: `src/scripts/write_to_github.sh`
- Modify: `src/tests/write_to_github.bats`

- [ ] **Step 1: Write a failing integration test**

Append to `src/tests/write_to_github.bats`:

```bash
# --- main (integration) ---

@test "main: full run with two files produces a commit and logs progress" {
  # Setup temp source files
  local tmpdir
  tmpdir=$(mktemp -d)
  echo "content-a" > "$tmpdir/app.yaml"
  echo "content-b" > "$tmpdir/web.yaml"

  # Set required env vars
  export REPOSITORY="owner/repo"
  export SOURCE="$tmpdir/*.yaml"
  export DESTINATION="argocd/apps/"
  export BRANCH="main"
  export GITHUB_TOKEN="test-token"
  export COMMIT_MESSAGE=""
  export MESSAGE_ONLY="false"

  # Mock all GitHub API calls; export -f so the mock survives into run's subshell
  github_api() {
    local method="$1" path="$2"
    case "$path" in
      */git/ref/heads/*)   echo '{"object":{"sha":"commit-parent"}}' ;;
      */git/commits/*)     echo '{"tree":{"sha":"base-tree"}}' ;;
      */git/blobs)         echo '{"sha":"blob-stub"}' ;;
      */git/trees)         echo '{"sha":"new-tree"}' ;;
      */git/commits)       echo '{"sha":"new-commit-abc"}' ;;
      */git/refs/*)        echo '{"ref":"refs/heads/main"}' ;;
    esac
  }
  export -f github_api
  export -f log die check_deps validate_inputs expand_sources map_target build_commit_message create_blob create_tree create_commit update_ref

  run main
  [ "$status" -eq 0 ]
  [[ "$output" == *"(1/2)"* ]]
  [[ "$output" == *"(2/2)"* ]]
  [[ "$output" == *"new-commit-abc"* ]]
  [[ "$output" == *"2 file(s) committed"* ]]

  rm -rf "$tmpdir"
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
bats src/tests/write_to_github.bats
```

Expected: test fails (main does not yet do anything useful).

- [ ] **Step 3: Implement `main`**

Replace the placeholder `main()` in `src/scripts/write_to_github.sh`:

```bash
main() {
  check_deps
  validate_inputs

  log "repo: ${REPOSITORY}  branch: ${BRANCH}"
  log "resolved source pattern: ${SOURCE}"

  # Expand source files
  local -a files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(expand_sources)

  local total=${#files[@]}
  log "matched ${total} file(s): $(IFS=', '; echo "${files[*]}")"

  # Resolve branch tip and base tree
  log "resolving branch tip for ${BRANCH}..."
  local commit_sha
  commit_sha=$(get_branch_tip)
  local base_tree_sha
  base_tree_sha=$(get_base_tree "$commit_sha")
  log "base commit: ${commit_sha}  base tree: ${base_tree_sha}"

  # Create blobs for each file
  local tree_entries='[]'
  local i=1
  for file in "${files[@]}"; do
    local target
    target=$(map_target "$file" "$SOURCE" "$DESTINATION")
    log "(${i}/${total}) preparing blob: $(basename "$file") -> ${target}"
    local blob_sha
    blob_sha=$(create_blob "$file")
    log "(${i}/${total}) blob created: sha=${blob_sha}"
    tree_entries=$(jq -n \
      --argjson entries "$tree_entries" \
      --arg path "$target" \
      --arg sha "$blob_sha" \
      '$entries + [{"path": $path, "mode": "100644", "type": "blob", "sha": $sha}]')
    i=$((i + 1))
  done

  # Build commit message
  local message
  message=$(build_commit_message)

  # Create tree, commit, and update ref
  log "creating tree..."
  local new_tree_sha
  new_tree_sha=$(create_tree "$base_tree_sha" "$tree_entries")
  log "tree created: sha=${new_tree_sha}"

  log "creating commit..."
  local new_commit_sha
  new_commit_sha=$(create_commit "$new_tree_sha" "$commit_sha" "$message")
  log "commit created: sha=${new_commit_sha}"

  log "updating branch ref ${BRANCH}..."
  update_ref "$new_commit_sha"

  log "done. ${total} file(s) committed to ${REPOSITORY}@${BRANCH} as ${new_commit_sha}"
}
```

- [ ] **Step 4: Run all tests — expect all to pass**

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add src/scripts/write_to_github.sh src/tests/write_to_github.bats
git commit -m "feat: implement main orchestration for write_to_github"
```

---

### Task 9: CircleCI orb command YAML

**Files:**
- Modify: `src/commands/write-to-github.yml`

- [ ] **Step 1: Replace the existing stub with the full command definition**

Write `src/commands/write-to-github.yml`:

```yaml
# src/commands/write-to-github.yml
# yamllint disable rule:line-length
---
description: |
  Write files directly into a GitHub repository using the GitHub API.

  Supports wildcard patterns for source and target paths. All matched files
  are written as a single atomic commit. The GitHub token must be available
  as an environment variable (GITHUB_TOKEN or GH_TOKEN).

parameters:

  source:
    description: |
      Local path to the file(s) to write. Supports wildcards.
      Example: ./deploy/*.yaml
    type: string

  repository:
    description: Target repository in owner/repo format.
    type: string

  destination:
    description: |
      Target path in the repository. Supports wildcards for stem substitution,
      a trailing / to preserve the source filename, or a literal path to rename.
      Example: argocd/apps/*.yaml
    type: string

  branch:
    description: Branch to commit to.
    type: string
    default: "main"

  commit-message:
    description: |
      Additional text to append to the auto-generated commit message.
      When message-only is true, this becomes the entire commit message.
    type: string
    default: ""

  message-only:
    description: |
      When true, commit-message replaces the auto-generated message entirely.
    type: boolean
    default: false

steps:
  - run:
      name: Write files to GitHub repository
      environment:
        SOURCE: << parameters.source >>
        REPOSITORY: << parameters.repository >>
        DESTINATION: << parameters.destination >>
        BRANCH: << parameters.branch >>
        COMMIT_MESSAGE: << parameters.commit-message >>
        MESSAGE_ONLY: << parameters.message-only >>
      command: <<include(scripts/write_to_github.sh)>>
```

- [ ] **Step 2: Validate YAML syntax**

```bash
yamllint src/commands/write-to-github.yml 2>/dev/null || python3 -c "import yaml,sys; yaml.safe_load(open('src/commands/write-to-github.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add src/commands/write-to-github.yml
git commit -m "feat: add write-to-github orb command with full parameter set"
```

---

## Final Verification

- [ ] Run the full test suite one last time

```bash
bats src/tests/write_to_github.bats
```

Expected: all tests pass, 0 failures.

- [ ] Verify the script is executable and runs the help path cleanly

```bash
# Should die immediately with missing REPOSITORY error (no GitHub calls made)
REPOSITORY="" SOURCE="" DESTINATION="" bash src/scripts/write_to_github.sh 2>&1 | head -5
```

Expected: `[write_to_github] ERROR: REPOSITORY is required (owner/repo)`
