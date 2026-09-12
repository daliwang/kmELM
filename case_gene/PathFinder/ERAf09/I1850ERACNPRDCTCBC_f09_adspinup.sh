#!/bin/bash
set -euo pipefail

# Pathfinder AD (accelerated decomposition) spinup for I1850ERACNPRDCTCBC
# on f09_f09 with ERA5 6hr remapped to f09 (DATM_MODE=ERAf09).
#
# Science settings match the completed Frontier case:
#   400 years, NCPL=24, DATM 1980-1999, cold start, spinup_state=1
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

CASE_NAME="I1850ERACNPRDCTCBC_f09_adspinup"
CASEDIR="${CASE_ROOT}/${CASE_NAME}"
NTASKS_ALL="${NTASKS_ALL:-1280}"
WALLTIME="${WALLTIME:-06:00:00}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR: ${CASEDIR}"
echo "RUN_ROOT: ${RUN_ROOT}"
echo "FORC_ROOT: ${FORC_ROOT}"
echo "NTASKS_ALL: ${NTASKS_ALL}"

FORC_DIR="${FORC_ROOT}/ERA5_6hr_f09"
NEXP=$((20 * 12 * 9))
NHAVE=0
if [[ -d "${FORC_DIR}" ]]; then
  NHAVE=$(find "${FORC_DIR}" -name 'elmforc.ERA5.c2018.0.9x1.25.*.19[89][0-9]-*.nc' | wc -l)
fi
echo "Forcing files 1980-1999 found: ${NHAVE} (expect ${NEXP})"
if [ "${NHAVE}" -lt "${NEXP}" ]; then
  echo "WARNING: incomplete 1980-1999 forcing. Continue creating case, but do not submit until complete."
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

./xmlchange PIO_TYPENAME=pnetcdf
./xmlchange PIO_NETCDF_FORMAT=64bit_data
./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${RUN_ROOT}"

./xmlchange RUN_STARTDATE=0001-01-01
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
./xmlchange RESUBMIT=39
./xmlchange CONTINUE_RUN=FALSE

./xmlchange ELM_FORCE_COLDSTART=on
./xmlchange ELM_ACCELERATED_SPINUP=on
./xmlchange --append ELM_BLDNML_OPTS="-bgc_spinup on"

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
 spinup_state = 1
 suplphos = 'ALL'
 hist_nhtfrq = -175200
 hist_mfilt  = 1
 nyears_ad_carbon_only = 25
 spinup_mortality_factor = 10
EOF

./case.setup
./xmlchange --force JOB_QUEUE="${JOB_QUEUE}"
./preview_namelists

echo "==== AD spinup config ===="
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,DATM_CLMNCEP_YR_ALIGN
./xmlquery RUN_STARTDATE,STOP_OPTION,STOP_N,REST_N,RESUBMIT,ELM_ACCELERATED_SPINUP,ATM_NCPL

echo "Case created: ${CASEDIR}"
echo "Expected end restart: ${RUN_ROOT}/${CASE_NAME}/run/${CASE_NAME}.elm.r.0401-01-01-00000.nc"
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
echo "Only submit after 1980-1999 forcing is complete (${NEXP} files)."
