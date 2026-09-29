#!/usr/bin/env bash
# shellcheck shell=bash
# Shared helpers for the scripts in this folder. Works in Git Bash on Windows, macOS and Linux.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER="${CLUSTER:-pgs}"
NAMESPACE="${NAMESPACE:-pgs}"
# Sibling checkouts of the application repos (override if yours live elsewhere).
GATEWAY_DIR="${GATEWAY_DIR:-$ROOT/../payment-gateway-sim}"
DASHBOARD_DIR="${DASHBOARD_DIR:-$ROOT/../merchant-dashboard}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || fail "'$cmd' is not installed (see README > Prerequisites)"
  done
}
