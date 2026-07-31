#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${RELEASE_NAME:-}" ]]; then
  RELEASE_NAME="${TAG_NAME}"
fi

API_HEADERS=(
  --header "Accept: application/vnd.github+json"
  --header "Authorization: Bearer ${GITHUB_API_TOKEN}"
  --header "X-GitHub-Api-Version: 2026-03-10"
)

CREATE_PAYLOAD=$(jq --null-input \
  --arg tag_name "${TAG_NAME}" \
  --arg name "${RELEASE_NAME}" \
  --arg target_commitish "${GITHUB_SHA}" \
  '{
    tag_name: $tag_name,
    name: $name,
    target_commitish: $target_commitish,
    draft: true,
    generate_release_notes: true
  }')

RELEASE_JSON=$(curl --silent --show-error --fail-with-body \
  --request POST \
  "${API_HEADERS[@]}" \
  --header "Content-Type: application/json" \
  --data "${CREATE_PAYLOAD}" \
  "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/releases")

RELEASE_ID=$(jq -er '.id' <<<"${RELEASE_JSON}")
UPLOAD_URL=$(jq -er '.upload_url | sub("\\{.*$"; "")' <<<"${RELEASE_JSON}")

echo "release-id=${RELEASE_ID}" >> "${GITHUB_OUTPUT}"
echo "upload-url=${UPLOAD_URL}" >> "${GITHUB_OUTPUT}"
