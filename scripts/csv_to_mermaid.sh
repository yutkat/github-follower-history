#!/usr/bin/env bash

set -Eeuo pipefail

# Check required arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <csv_file> [output_file] [start_date] [max_x_labels]" >&2
  echo "Example: $0 follower_history.csv chart.md" >&2
  echo "Example: $0 follower_history.csv chart.md 2024-01-01" >&2
  echo "Example: $0 follower_history.csv chart.md 2024-01-01 10" >&2
  exit 1
fi

CSV_FILE="${1}"
OUTPUT_FILE="${2:-chart.md}"
START_DATE="${3:-}"
MAX_X_LABELS="${4:-}"

if [[ ! -f "${CSV_FILE}" ]]; then
  echo "Error: CSV file '${CSV_FILE}' not found" >&2
  exit 1
fi

# Extract dates and followers, sort by date (ascending)
data=$(tail -n +2 "${CSV_FILE}" | grep -v "N/A" | sort -t',' -k1)

# Filter by start date if specified
if [[ -n "${START_DATE}" ]]; then
  data=$(echo "${data}" | awk -F',' -v start="${START_DATE}" '$1 >= start')
fi

# Apply thinning if max_x_labels is specified
if [[ -n "${MAX_X_LABELS}" ]]; then
  total_lines=$(echo "${data}" | wc -l)
  if [[ ${total_lines} -gt ${MAX_X_LABELS} ]]; then
    step=$(awk "BEGIN {print int(${total_lines} / ${MAX_X_LABELS}) + 1}")
    data=$(echo "${data}" | awk "NR == 1 || NR % ${step} == 0 || NR == ${total_lines}")
  fi
fi

dates=$(echo "${data}" | cut -d',' -f1 | cut -d' ' -f1 | sed 's/-[0-9][0-9]$//' | sed 's/^[0-9][0-9]//' | sed 's/^/"/' | sed 's/$/"/' | paste -sd ',' -)
followers=$(echo "${data}" | cut -d',' -f2 | paste -sd ',' -)

# Create mermaid chart
cat > "${OUTPUT_FILE}" << EOF
\`\`\`mermaid
xychart-beta
  title "GitHub Followers History"
  x-axis [${dates}]
  y-axis "Followers"
  line [${followers}]
\`\`\`
EOF

echo "Mermaid chart saved to ${OUTPUT_FILE}" >&2
cat "${OUTPUT_FILE}"
