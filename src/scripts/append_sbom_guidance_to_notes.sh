#!/bin/bash
set -euo pipefail

echo "Run all bake file images, passing container name to local bash script to extract sbom guidance."

if [[ ! -f "$BAKEFILE" ]]; then
  echo "Bake file not found: $BAKEFILE" >&2
  exit 1
fi

if [[ ! -f "$GUIDANCE_PATH" ]]; then
  echo "custom notes content script not found: $GUIDANCE_PATH" >&2
  exit 1
fi

echo "Using bake file: $BAKEFILE"
echo "Using TAG=${TAG}"

cat << 'EOF' >> "$OUTFILE"
<details>
<summary>SBOM guidance</summary>

EOF


# Extract all targets and their tags
jq -r '
  .target
  | to_entries[]
  | select(.value.tags != null)
  | .key as $name
  | .value.tags[]
  | [$name, .]
  | @tsv
' "$BAKEFILE" | 
while IFS=$'\t' read -r target_name raw_tag; do
  image_ref="$raw_tag"

  # Replace bakefile var reference with actual VAR value.
  # We define it twice to support both ${TAG} and $TAG
  image_ref="${image_ref//\$\{TAG\}/$TAG}"
  image_ref="${image_ref//\$TAG/$TAG}"

  # pick up any other ENV should they exist in the defition (allow more customization)
  image_ref="$(eval echo "$image_ref")"

  if ! docker buildx imagetools inspect "$image_ref" >/dev/null 2>&1; then
      echo "❌ $image_ref not found in registry"
      exit 1
  fi

  # Run bats scan against targets
  # requires bats files to contain any target specific logic
  docker run -it -d --name "${target_name}-container" --entrypoint "${ENTRY_POINT}" "${image_ref}"
  {
    echo "===== Target: ${target_name}  Image: ${image_ref} ====="
    echo
    TEST_CONTAINER="${target_name}-container" bash "$GUIDANCE_PATH"
    echo
  } >> "$OUTFILE"
done
cat << 'EOF' >> "$OUTFILE"
</details>

EOF

echo "Success"
