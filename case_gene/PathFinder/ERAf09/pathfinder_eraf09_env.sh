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

E3SM_SRCROOT="${E3SM_SRCROOT:-${KMELM_ROOT}/E3SM}"
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
  echo "Check out lnd/clm_glacier_fixes_era5 (or equivalent with ERAf09) there." >&2
  exit 1
fi
