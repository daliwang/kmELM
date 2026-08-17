#!/bin/bash
set -euo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
exec bash "${ROOT}/case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh" "$@"
