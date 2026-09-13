# Shared Pathfinder paths for I1850ERACNPRDCTCBC f09 / ERAf09 cases.
# Sourced by the create scripts in this directory. Override any variable
# in the environment before calling a create script.
#
# Cases and runs live under the kmELM tree, not inside the E3SM submodule:
#   ${KMELM_ROOT}/e3sm_cases
#   ${KMELM_ROOT}/e3sm_runs

CLI185PROJ_ROOT="${CLI185PROJ_ROOT:-/projects/hpcl-cli185}"
# Stock files live under inputdata/, matching the pathfinder machine DIN_LOC_ROOT.
E3SM_DIN="${E3SM_DIN:-${CLI185PROJ_ROOT}/world-shared/e3sm/inputdata}"
FORC_ROOT="${FORC_ROOT:-${CLI185PROJ_ROOT}/proj-shared/wangd/kiloCraft}"

if [[ -z "${KMELM_ROOT:-}" ]]; then
  if git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel >/dev/null 2>&1; then
    KMELM_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
  else
    KMELM_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kmELM"
  fi
fi

# Prefer the pinned ERA5 worktree so kmELM/E3SM can track TES_NORTH / other branches.
if [[ -z "${E3SM_SRCROOT:-}" ]]; then
  if [[ -d "${KMELM_ROOT}/E3SM-era5/cime/scripts" ]]; then
    E3SM_SRCROOT="${KMELM_ROOT}/E3SM-era5"
  else
    E3SM_SRCROOT="${KMELM_ROOT}/E3SM"
  fi
fi
CASE_ROOT="${CASE_ROOT:-${KMELM_ROOT}/e3sm_cases}"
RUN_ROOT="${RUN_ROOT:-${KMELM_ROOT}/e3sm_runs}"

MACH="${MACH:-pathfinder}"
COMPILER="${COMPILER:-gnu}"
MPILIB="${MPILIB:-openmpi}"
# Default: parallel, constrained to 128-core high-memory nodes (pfc001-pfc030 class).
# Dedicated 20-node project partition: JOB_QUEUE=hpcl-cli185
JOB_QUEUE="${JOB_QUEUE:-parallel}"
MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE:-128}"

if [[ ! -d "${E3SM_SRCROOT}/cime/scripts" ]]; then
  echo "ERROR: E3SM not found at ${E3SM_SRCROOT}" >&2
  echo "Create the ERA5 tree: bash scripts/setup_e3sm_era5_worktree.sh" >&2
  echo "Or check out lnd/clm_glacier_fixes_era5 (needs ERAf09) and set E3SM_SRCROOT." >&2
  exit 1
fi

if ! grep -q 'DATM_MODE=ERAf09\|%ERAf09' \
     "${E3SM_SRCROOT}/components/data_comps/datm/cime_config/config_component.xml" \
     2>/dev/null; then
  echo "ERROR: ${E3SM_SRCROOT} does not define DATM %ERAf09." >&2
  echo "Use ${KMELM_ROOT}/E3SM-era5 (branch lnd/clm_glacier_fixes_era5)." >&2
  echo "Do not point ERAf09 cases at kmELM/E3SM if that tree is on TESSFA_4km or master." >&2
  exit 1
fi
