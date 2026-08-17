#!/bin/bash
# Thin wrappers: canonical Frontier ERA5-f09 scripts live under case_gene/Frontier/
# (same pattern as case_gene/PathFinder and case_gene/ORNL_baseline).
set -euo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
exec bash "${ROOT}/case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_smoke.sh" "$@"
