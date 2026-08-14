# Shared settings for e3sm_land_developer generate/compare on Frontier.
# Sourced by e3sm_land_developer_generate.sh and e3sm_land_developer_compare.sh.

KMELM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E3SMROOT="${KMELM_ROOT}/E3SM"
MY_BASELINE_DIR="${KMELM_ROOT}/baselines"
LOG_DIR="${KMELM_ROOT}/docs"

# Parent master hash used to generate gold files. Keep -b the same for compare.
BASELINE_NAME="a899004464"

# Development branch to compare against those gold files.
DEV_BRANCH="lnd/port-clm-cryosphere-fixes-master"

SUITE="e3sm_land_developer"
MACHINE="frontier"
COMPILER="craygnu"
PROJECT="cli115"
WALLTIME="00:45:00"
CREATE_TEST_JOBS=4
MAIL_USER="${MAIL_USER:-wangd@ornl.gov}"
PYTHON_MODULE="cray-python/3.11.7"

SCRATCH_ROOT="/lustre/orion/cli115/proj-shared/${USER}/e3sm_scratch"
CREATE_TEST="${E3SMROOT}/cime/scripts/create_test"

load_python() {
  if [[ -f /opt/cray/pe/lmod/lmod/init/bash ]]; then
    # shellcheck disable=SC1091
    source /opt/cray/pe/lmod/lmod/init/bash
  fi
  if command -v module >/dev/null 2>&1; then
    module load "${PYTHON_MODULE}"
  fi
  python3 - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit(f"CIME needs Python >= 3.9, found {sys.version}")
print(f"Using Python {sys.version.split()[0]} ({sys.executable})")
PY
}
