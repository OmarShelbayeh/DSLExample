#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Usage:
#   ./scripts/structurizr-export-static.sh [dsl-file] [output-dir]
# Example:
#   ./scripts/structurizr-export-static.sh docs/workspace-system1-to-5.dsl docs/export-static
INPUT_PATH="${1:-docs/workspace-system1-to-5.dsl}"
OUTPUT_DIR="${2:-docs/export-static}"

if [[ "${INPUT_PATH}" != /* ]]; then
  INPUT_ABS="${ROOT_DIR}/${INPUT_PATH}"
else
  INPUT_ABS="${INPUT_PATH}"
fi

if [[ "${OUTPUT_DIR}" != /* ]]; then
  OUTPUT_ABS="${ROOT_DIR}/${OUTPUT_DIR}"
else
  OUTPUT_ABS="${OUTPUT_DIR}"
fi

INPUT_ABS="$(realpath "${INPUT_ABS}")"
OUTPUT_ABS="$(realpath -m "${OUTPUT_ABS}")"
ROOT_ABS="$(realpath "${ROOT_DIR}")"

if [[ "${INPUT_ABS}" != "${ROOT_ABS}"/* ]]; then
  echo "Error: Input DSL must be inside project root: ${ROOT_ABS}" >&2
  exit 1
fi

if [[ "${OUTPUT_ABS}" != "${ROOT_ABS}"/* ]]; then
  echo "Error: Output directory must be inside project root: ${ROOT_ABS}" >&2
  exit 1
fi

INPUT_REL="${INPUT_ABS#${ROOT_ABS}/}"
OUTPUT_REL="${OUTPUT_ABS#${ROOT_ABS}/}"

if [[ ! -f "${INPUT_ABS}" ]]; then
  echo "Error: DSL file not found: ${INPUT_ABS}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_ABS}"

echo "Exporting static site from: ${INPUT_ABS}"
echo "Output directory: ${OUTPUT_ABS}"

author_uid_gid="$(id -u):$(id -g)"
sudo docker run --rm \
  --user "${author_uid_gid}" \
  -v "${ROOT_DIR}:/work" \
  structurizr/structurizr export \
  -w "/work/${INPUT_REL}" \
  -f static \
  -o "/work/${OUTPUT_REL}"

echo "Done. Open ${OUTPUT_ABS}/index.html"
