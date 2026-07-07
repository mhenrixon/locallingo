#!/usr/bin/env bash
# Run a command in the docs app with a clean bundler env and cosmos-2's binstub
# dir removed from PATH (it shadows the global `rails`). Used during authoring:
#   bin/dev-env.sh bin/rails runner "puts Doc.all.size"
# This file is a local dev convenience; not shipped or deployed.
set -euo pipefail
cd "$(dirname "$0")/.."
CLEAN_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v 'cosmos-2/bin' | paste -sd: -)
exec env -u BUNDLE_GEMFILE -u BUNDLE_BIN_PATH -u BUNDLE_APP_CONFIG PATH="$CLEAN_PATH" "$@"
