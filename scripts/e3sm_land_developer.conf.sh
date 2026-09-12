# Shared settings for e3sm_land_developer generate/compare on Frontier.
# Sourced by e3sm_land_developer_generate.sh and e3sm_land_developer_compare.sh.
#
# Active campaign (2026-09-03): current master gold + cryosphere-fixes-master2.
# Do not open the master PR until this campaign finishes.
# Prior gold (keep, do not reuse):
#   34bd782d18  maint-3.0 / lnd/port-clm-cryosphere-fixes-maint-3.0
#   a899004464  older master / lnd/port-clm-cryosphere-fixes-master

KMELM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Worktree with current master + cherry-picks. Do not use kmELM/E3SM
# (other branch) or E3SM-pr (maint-3.0 + dirty overlay).
E3SMROOT="${KMELM_ROOT}/E3SM-master-pr"
MY_BASELINE_DIR="${KMELM_ROOT}/baselines"
LOG_DIR="${KMELM_ROOT}/docs"

# Parent hash used to generate gold files. Keep -b the same for compare.
BASELINE_NAME="34fb1e111e"

# Development branch to compare against those gold files.
DEV_BRANCH="lnd/port-clm-cryosphere-fixes-master2"

# Current master already ships craygnu. The maint-3.0 Lmod overlay is off.
APPLY_FRONTIER_OVERLAY=0

SUITE="e3sm_land_developer"
MACHINE="frontier"
COMPILER="craygnu"
PROJECT="cli115"
# 01:30:00: two r05 tests hit 45 min on the 2026-08-14 master campaign.
WALLTIME="01:30:00"
CREATE_TEST_JOBS=4
# Cheap Frontier smoke on DEV_BRANCH before the full suite.
SMOKE_WALLTIME="00:30:00"
SMOKE_TESTS=(
  SMS_Ly2_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-force_netcdf_pio
  ERS.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-snowveg_arctic
)
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

# Drop previous local overlay so git checkout of the parent/branch is clean.
# Only remove craygnu cmake files when they are untracked overlay copies
# (maint-3.0). On current master those files are tracked — do not delete them.
reset_local_frontier_overlay() {
  cd "${E3SMROOT}"
  git checkout -- \
    cime_config/machines/config_machines.xml \
    components/elm/src/main/controlMod.F90 \
    2>/dev/null || true
  if [[ "${APPLY_FRONTIER_OVERLAY}" == "1" ]]; then
    rm -f \
      cime_config/machines/cmake_macros/craygnu.cmake \
      cime_config/machines/Depends.craygnu.cmake
  fi
}

# Local-only maint-3.0 Frontier overlay (do not commit to the science branch):
# splice master's Frontier machine block + craygnu macros, Lmod wrapper,
# and the gfortran-14 controlMod USE-line cleanup.
apply_frontier_lmod_workaround() {
  python3 "${KMELM_ROOT}/scripts/workaround_frontier_lmod_reset.py" \
    "${E3SMROOT}/cime_config/machines/config_machines.xml" \
    --e3sm-root "${E3SMROOT}"
}
