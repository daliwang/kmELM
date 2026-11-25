#!/bin/bash
# DEPRECATED: the 20261015 elm.r.0020 restart has gridcell=94935 and does not
# match the current GSW TOP/crop case mesh (94838). Job 5988293 aborted with
# check_dim ERROR. Use ad0021_30node instead.
#
# See docs/AI4ELM_finidat_gridcell_mismatch.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "ERROR: I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0020_30node.sh is deprecated." >&2
echo "       Use: bash ${SCRIPT_DIR}/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_30node.sh" >&2
echo "       Reason: elm.r.0020 flat copy is gridcell=94935; case expects 94838." >&2
exit 1
