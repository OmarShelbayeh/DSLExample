#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="${ROOT_DIR}/docs"

# Usage:
#   ./scripts/structurizr-local.sh [dsl-file] [port]
# Example:
#   ./scripts/structurizr-local.sh workspace-system1-to-5.dsl 8080
DSL_FILE="${1:-workspace-system1-to-5.dsl}"
PORT="${2:-8080}"

if [[ "${DSL_FILE}" != /* ]]; then
  DSL_PATH="${DOCS_DIR}/${DSL_FILE}"
else
  DSL_PATH="${DSL_FILE}"
fi

if [[ ! -f "${DSL_PATH}" ]]; then
  echo "Error: DSL file not found: ${DSL_PATH}" >&2
  exit 1
fi

RUNTIME_DIR="${DOCS_DIR}/.local-runtime"
mkdir -p "${RUNTIME_DIR}"
cp "${DSL_PATH}" "${RUNTIME_DIR}/workspace.dsl"

echo "Starting Structurizr Local on http://localhost:${PORT}/workspace/1"
echo "Using DSL: ${DSL_PATH}"

author_uid_gid="$(id -u):$(id -g)"
sudo docker run -it --rm \
  -p "${PORT}:8080" \
  --user "${author_uid_gid}" \
  -v "${RUNTIME_DIR}:/usr/local/structurizr" \
  structurizr/structurizr local
