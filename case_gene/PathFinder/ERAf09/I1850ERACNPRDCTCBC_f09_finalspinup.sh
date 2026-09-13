#!/bin/bash
set -euo pipefail

# Pathfinder final (normal BGC) spinup after AD for I1850ERACNPRDCTCBC
# on f09_f09 with ERA5 6hr remapped to f09 (DATM_MODE=ERAf09).
#
# Science settings match the completed Frontier case:
#   800 years, NCPL=24, DATM 1980-1999, finidat from AD 0401 restart
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

AD_CASE_NAME="I1850ERACNPRDCTCBC_f09_adspinup"
CASE_NAME="I1850ERACNPRDCTCBC_f09_finalspinup"
CASEDIR="${CASE_ROOT}/${CASE_NAME}"
AD_FINIDAT="${RUN_ROOT}/${AD_CASE_NAME}/run/${AD_CASE_NAME}.elm.r.0401-01-01-00000.nc"
NTASKS_ALL="${NTASKS_ALL:-1280}"
WALLTIME="${WALLTIME:-06:00:00}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR: ${CASEDIR}"
echo "AD_FINIDAT: ${AD_FINIDAT}"
echo "NTASKS_ALL: ${NTASKS_ALL}"

if [ ! -f "${AD_FINIDAT}" ]; then
  echo "WARNING: AD finidat not found yet:"
  echo "  ${AD_FINIDAT}"
  echo "Case will still be created; submit only after AD completes."
fi

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

./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE=0401-01-01
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1999

./xmlchange ATM_NCPL=24
./xmlchange LND_NCPL=24
./xmlchange ROF_NCPL=24
./xmlchange ICE_NCPL=24

./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=10
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=10
./xmlchange RESUBMIT=79
./xmlchange CONTINUE_RUN=FALSE

./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_ACCELERATED_SPINUP=off

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
 finidat = '${AD_FINIDAT}'
 spinup_state = 0
 suplphos = 'NONE'
 hist_nhtfrq = -175200
 hist_mfilt  = 1
EOF

./case.setup
./xmlchange --force JOB_QUEUE="${JOB_QUEUE}"
./preview_namelists

echo "==== final spinup config ===="
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,DATM_CLMNCEP_YR_ALIGN
./xmlquery RUN_TYPE,RUN_STARTDATE,STOP_OPTION,STOP_N,REST_N,RESUBMIT,ELM_ACCELERATED_SPINUP,ATM_NCPL

echo "Case created: ${CASEDIR}"
echo "finidat (from AD): ${AD_FINIDAT}"
echo "Next (after AD finishes): cd ${CASEDIR} && ./case.build && ./case.submit"
