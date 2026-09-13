#!/bin/bash
set -euo pipefail

# Pathfinder 5-day smoke for I1850ERACNPRDCTCBC on f09_f09 with ERAf09.
# Uses NCPL=24 to match production AD/final (not the Frontier smoke NCPL=4).
#
# Cases are created under ${KMELM_ROOT}/e3sm_cases, not under E3SM/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pathfinder_eraf09_env.sh
source "${SCRIPT_DIR}/pathfinder_eraf09_env.sh"

python3 - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit(
        "ERROR: CIME needs Python >= 3.9, found %s (%s)."
        % (sys.version.split()[0], sys.executable)
    )
print("Using Python %s (%s)" % (sys.version.split()[0], sys.executable))
PY

CASE_NAME="I1850ERACNPRDCTCBC_f09_smoke1980"
CASEDIR="${CASE_ROOT}/${CASE_NAME}"
NTASKS_ALL="${NTASKS_ALL:-128}"
WALLTIME="${WALLTIME:-02:00:00}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR: ${CASEDIR}"
echo "FORC_ROOT: ${FORC_ROOT}"
echo "NTASKS_ALL: ${NTASKS_ALL}"

rm -rf "${CASEDIR}"
mkdir -p "${CASE_ROOT}" "${RUN_ROOT}"

"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach "${MACH}" \
  --compiler "${COMPILER}" \
  --mpilib "${MPILIB}" \
  --compset I1850ERACNPRDCTCBC \
  --res f09_f09 \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange COMP_INTERFACE=mct
./xmlchange PIO_TYPENAME=pnetcdf
./xmlchange PIO_NETCDF_FORMAT=64bit_data
./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${RUN_ROOT}"

./xmlchange RUN_STARTDATE=1980-01-01
./xmlchange DATM_CLMNCEP_YR_ALIGN=1980
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1980

./xmlchange ATM_NCPL=24
./xmlchange LND_NCPL=24
./xmlchange ROF_NCPL=24
./xmlchange ICE_NCPL=24

./xmlchange STOP_OPTION=ndays
./xmlchange STOP_N=5
./xmlchange REST_OPTION=ndays
./xmlchange REST_N=5

./xmlchange ELM_FORCE_COLDSTART=on

./xmlchange JOB_WALLCLOCK_TIME="${WALLTIME}"
./xmlchange USER_REQUESTED_WALLTIME="${WALLTIME}"

./xmlchange MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE}"
./xmlchange NTASKS="${NTASKS_ALL}"
./xmlchange NTASKS_ATM="${NTASKS_ALL}"
./xmlchange NTASKS_LND="${NTASKS_ALL}"
./xmlchange NTASKS_ROF="${NTASKS_ALL}"
./xmlchange NTASKS_ICE="${NTASKS_ALL}"
./xmlchange NTASKS_OCN="${NTASKS_ALL}"
./xmlchange NTASKS_CPL="${NTASKS_ALL}"
./xmlchange NTASKS_GLC="${NTASKS_ALL}"
./xmlchange NTASKS_WAV="${NTASKS_ALL}"

cat >> user_nl_elm <<EOF
 hist_nhtfrq = -24
 hist_mfilt  = 6
EOF

./case.setup
./xmlchange --force JOB_QUEUE="${JOB_QUEUE}"
./preview_namelists

echo "==== DATM mode / years ===="
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,ATM_NCPL,RUN_STARTDATE
./xmlquery ATM_NCPL,LND_NCPL,ROF_NCPL,ICE_NCPL,DATM_MODE
ls CaseDocs/datm.streams.txt.ERAf09* 2>/dev/null | head || true

echo "Case created: ${CASEDIR}"
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
