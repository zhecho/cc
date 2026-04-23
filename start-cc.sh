#!/bin/bash
# start-cc.sh — Launch Claude Code + mcp-atlassian pod via podman play kube
#
# Required env vars (Atlassian credentials):
#   JIRA_URL, JIRA_USERNAME, JIRA_API_TOKEN
#   CONFLUENCE_URL, CONFLUENCE_USERNAME, CONFLUENCE_API_TOKEN
#
# Optional:
#   WORKSPACE_DIR   — path to mount as /workspace  (default: current directory)
#
# Dependencies: podman, envsubst (brew install gettext on macOS)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POD_YAML="${SCRIPT_DIR}/cc-pod.yaml"

# ── Preflight checks ───────────────────────────────────────────────────────────
if ! command -v envsubst >/dev/null 2>&1; then
  echo "ERROR: envsubst not found. Install with: brew install gettext"
  exit 1
fi

if ! command -v podman >/dev/null 2>&1; then
  echo "ERROR: podman not found."
  exit 1
fi

# ── Set workspace ──────────────────────────────────────────────────────────────
export WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"

# Warn about unset credentials (don't fail — user may have them in ~/.claude)
for var in JIRA_URL JIRA_USERNAME JIRA_API_TOKEN CONFLUENCE_URL CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN; do
  if [ -z "${!var:-}" ]; then
    echo "WARNING: ${var} is not set — mcp-atlassian may not authenticate"
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Claude Code pod"
echo "  Workspace : ${WORKSPACE_DIR}"
echo "  Config    : ${HOME}/.claude"
echo "  Kube      : ${HOME}/.kube"
echo "  Image     : registry.partizani.eu/zgc/cc:latest"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Start pod ─────────────────────────────────────────────────────────────────
envsubst < "${POD_YAML}" | podman play kube --replace --userns=keep-id -

echo ""
echo "Attaching to claude-code container..."
echo "  Tip: on first run inside the pod, register the MCP SSE server:"
echo "    claude mcp remove atlassian 2>/dev/null"
echo "    claude mcp add --transport sse atlassian http://localhost:9000/sse"
echo ""
echo "  Press Ctrl-P Ctrl-Q to detach without stopping the pod."
echo ""

podman attach cc-claude-code || true

# ── Cleanup ───────────────────────────────────────────────────────────────────
echo "Stopping pod cc..."
podman pod stop cc 2>/dev/null || true
podman pod rm   cc 2>/dev/null || true
echo "Done."
