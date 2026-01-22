#!/usr/bin/env bash
set -eo pipefail

echo "append sbom information from image manifest to notes"

if [[ ! -f "$BAKEFILE" ]]; then
  echo "Bake file not found: $BAKEFILE" >&2
  exit 1
fi

echo "Pulling manifests from bake file configuration."
echo "Using bake file: $BAKEFILE"
echo "Using TAG=${TAG}"

echo "<details>" > "$OUTFILE"
echo "<summary>Installed packages</summary>" >> "$OUTFILE"
echo "" >> "$OUTFILE"

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

  # Replace bake file var reference with actual VAR value.
  # We define it twice to support both ${TAG} and $TAG
  image_ref="${image_ref//\$\{TAG\}/$TAG}"
  image_ref="${image_ref//\$TAG/$TAG}"

  # pick up any other ENV should they exist in the defition (allows more customization)
  image_ref="$(eval echo "$image_ref")"

  # Obtain manifest index digest
  digest=$(oras manifest fetch --descriptor "${image_ref}" | jq -r '.digest')

  if [[ -z "$digest" ]]; then
    echo "❌ Unable to resolve digest for ${image_ref}"
    exit 1
  fi

  echo "<details>" >> "$OUTFILE"
  echo "<summary>Package details from $target_name SBOM</summary>" >> "$OUTFILE"
  echo "" >> "$OUTFILE"

  digest_ref="${image_ref%@*}@${digest}"
  echo "Digest reference: ${digest_ref}"

  TMP_DIR=$(mktemp -d)
  oras copy "$digest_ref" --to-oci-layout "$TMP_DIR"

  # get an SBOM for each target
  for BLOB in "$TMP_DIR"/blobs/sha256/*; do
    if jq -e . "$BLOB" >/dev/null 2>&1; then
      PREDICATE=$(jq -r '.predicateType // empty' "$BLOB")

      if [[ "$PREDICATE" == "https://spdx.dev/Document" ]]; then
          FILE="$TMP_DIR/sbom-$(basename $BLOB).json"
          echo "Saving SBOM -> $FILE"
          cp "$BLOB" "$FILE"
          break
      fi
    fi
  done
  PACKAGES=$(jq -r '.predicate.packages[] | "\(.name) \(.versionInfo)"' "$FILE")
  echo '```' >> "$OUTFILE"
  echo "$PACKAGES" >> "$OUTFILE"
  echo '```' >> "$OUTFILE"
  echo "" >> "$OUTFILE"
  echo "</details>" >> "$OUTFILE"
  echo "" >> "$OUTFILE"
  rm -rf "$TMP_DIR"

done
echo "</details>" >> "$OUTFILE"
