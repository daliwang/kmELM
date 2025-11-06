#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

# Ensure submodules exist
git submodule update --init --recursive

# Update E3SM to its configured remote-tracking branch (from .gitmodules or git config)
git submodule update --remote -- E3SM

sha=$(git -C E3SM rev-parse --short HEAD)

# Commit only if submodule pointer changed
if ! git diff --quiet -- E3SM; then
  git add E3SM
  git commit -m "Update E3SM submodule to ${sha}"
  git push
else
  echo "E3SM submodule already up-to-date at ${sha}"
fi
