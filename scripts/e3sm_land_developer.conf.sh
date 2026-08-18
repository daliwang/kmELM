# Shared settings for e3sm_land_developer generate/compare on Frontier.
# Sourced by e3sm_land_developer_generate.sh and e3sm_land_developer_compare.sh.
#
# Active campaign (2026-08-17): maint-3.0 gold + cryosphere-fixes-maint-3.0.
# Prior campaign (2026-08-14, keep gold): BASELINE_NAME=a899004464
#   DEV_BRANCH=lnd/port-clm-cryosphere-fixes-master
#   Gold: ${KMELM_ROOT}/baselines/a899004464/

KMELM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E3SMROOT="${KMELM_ROOT}/E3SM"
MY_BASELINE_DIR="${KMELM_ROOT}/baselines"
LOG_DIR="${KMELM_ROOT}/docs"

# Parent hash used to generate gold files. Keep -b the same for compare.
BASELINE_NAME="34bd782d18"

# Development branch to compare against those gold files.
DEV_BRANCH="lnd/port-clm-cryosphere-fixes-maint-3.0"

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
reset_local_frontier_overlay() {
  cd "${E3SMROOT}"
  git checkout -- \
    cime_config/machines/config_machines.xml \
    components/elm/src/main/controlMod.F90 \
    2>/dev/null || true
  rm -f \
    cime_config/machines/cmake_macros/craygnu.cmake \
    cime_config/machines/Depends.craygnu.cmake
}

# Local-only maint-3.0 Frontier overlay (do not commit to the science branch):
# splice master's Frontier machine block + craygnu macros, Lmod wrapper,
# and the gfortran-14 controlMod USE-line cleanup.
apply_frontier_lmod_workaround() {
  python3 "${KMELM_ROOT}/scripts/workaround_frontier_lmod_reset.py" \
    "${E3SMROOT}/cime_config/machines/config_machines.xml" \
    --e3sm-root "${E3SMROOT}"
}
