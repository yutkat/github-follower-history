#!/usr/bin/env bash

set -Eeuo pipefail

# Check required arguments
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <country> <username> [output_file]" >&2
  echo "Example: $0 japan yutkat follower_history.csv" >&2
  exit 1
fi

# Variables
REPO_URL="https://github.com/gayanvoice/top-github-users.git"
WORK_DIR="$(mktemp -d)"
COUNTRY="${1}"
USERNAME="${2}"
OUTPUT_FILE="${3:-follower_history.csv}"

function cleanup() {
  rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

echo "Cloning repository with sparse-checkout..." >&2
cd "${WORK_DIR}"
git clone --filter=blob:none --no-checkout "${REPO_URL}" .
git sparse-checkout init --cone
git sparse-checkout set "./cache/${COUNTRY}.json"
git checkout main

echo "Extracting follower data for ${USERNAME} in ${COUNTRY}..." >&2

# Convert country name to title case for grep pattern
COUNTRY_TITLE=$(echo "${COUNTRY}" | sed 's/\b\(.\)/\u\1/')

# Get commit hashes for "Update [Country]" commits
COMMIT_HASHES=$(git log --grep="Update ${COUNTRY_TITLE}" --format="%H")

# Extract date and follower count for each commit
echo "date,followers" > "${OUTPUT_FILE}"

while IFS= read -r commit_hash; do
  commit_date=$(git show -s --format="%ci" "${commit_hash}")
  follower_count=$(git show "${commit_hash}:cache/${COUNTRY}.json" | jq -r --arg user "${USERNAME}" '[.[] | select(.login == $user) | .followers] | if length == 0 then "N/A" else .[0] end')
  echo "${commit_date},${follower_count}"
done <<< "${COMMIT_HASHES}" >> "${OUTPUT_FILE}"

echo "Data saved to ${OUTPUT_FILE}" >&2
cat "${OUTPUT_FILE}"
