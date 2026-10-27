# Shared Pathfinder paths for AI4ELM GSWP3 TOP/crop cases.
# Sourced by create scripts in this directory.
#
# Cases/runs under kmELM (not inside E3SM-ai4elm):
#   ${KMELM_ROOT}/e3sm_cases
#   ${KMELM_ROOT}/e3sm_runs

CLI185PROJ_ROOT="${CLI185PROJ_ROOT:-/projects/hpcl-cli185}"
E3SM_DIN="${E3SM_DIN:-${CLI185PROJ_ROOT}/world-shared/e3sm/inputdata}"
# GSWP3 stock path under DIN; CLMFORC points at atm/datm7 parent of the GSWP3 dir.
FORC_ROOT="${FORC_ROOT:-${E3SM_DIN}/atm/datm7}"
CUSTOM_DATA="${CUSTOM_DATA:-${CLI185PROJ_ROOT}/proj-shared/wangd/input_data/ai4elm_spinup}"

if [[ -z "${KMELM_ROOT:-}" ]]; then
  if git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel >/dev/null 2>&1; then
    KMELM_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
  else
    KMELM_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kmELM"
  fi
fi

E3SM_SRCROOT="${E3SM_SRCROOT:-${KMELM_ROOT}/E3SM-ai4elm}"
CASE_ROOT="${CASE_ROOT:-${KMELM_ROOT}/e3sm_cases}"
RUN_ROOT="${RUN_ROOT:-${KMELM_ROOT}/e3sm_runs}"

MACH="${MACH:-pathfinder}"
COMPILER="${COMPILER:-gnu}"
MPILIB="${MPILIB:-openmpi}"
JOB_QUEUE="${JOB_QUEUE:-parallel}"
MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE:-128}"
PIN_SHA="${PIN_SHA:-48d8ff20ccb32d6cddcb2fcd6d83fddaf03ee53a}"

if [[ ! -d "${E3SM_SRCROOT}/cime/scripts" ]]; then
  echo "ERROR: E3SM-ai4elm not found at ${E3SM_SRCROOT}" >&2
  echo "On Pathfinder: bash scripts/setup_e3sm_ai4elm_worktree.sh" >&2
  echo "(that script overlays Pathfinder machine files into the pin)." >&2
  exit 1
fi

if ! grep -q 'I1850GSWCNPRDCTCBCTOPPHSWFMCROP' \
     "${E3SM_SRCROOT}/components/elm/cime_config/config_compsets.xml" 2>/dev/null; then
  echo "ERROR: ${E3SM_SRCROOT} lacks compset I1850GSWCNPRDCTCBCTOPPHSWFMCROP." >&2
  echo "Expected pin ${PIN_SHA} (jinyuntang/elm/fix-top-crop-compsets)." >&2
  exit 1
fi

if ! grep -q 'MACH="pathfinder"' \
     "${E3SM_SRCROOT}/cime_config/machines/config_machines.xml" 2>/dev/null; then
  echo "ERROR: ${E3SM_SRCROOT} has no Pathfinder machine entry." >&2
  echo "Re-run: OVERLAY_PATHFINDER=1 bash scripts/setup_e3sm_ai4elm_worktree.sh" >&2
  exit 1
fi

HEAD_SHA="$(git -C "${E3SM_SRCROOT}" rev-parse HEAD)"
if [[ "${HEAD_SHA}" != "${PIN_SHA}" ]]; then
  echo "WARNING: E3SM-ai4elm HEAD is ${HEAD_SHA}, expected pin ${PIN_SHA}" >&2
fi
