#!/usr/bin/env bash
# Deletes the kind cluster (and everything in it).
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require kind
kind delete cluster --name "$CLUSTER"
