#!/bin/bash
set -euo pipefail

# Normal (final) BGC spinup after AD for I1850ERACNPRDCTCBC on f09_f09
# with ERA5 6hr remapped to f09 (DATM_MODE=ERAf09).
#
# Forcing cycle: 20 years (1980-1999) — same as AD
# Simulation length: 800 years (100-year segments x 8 via RESUBMIT)
# Initial condition: AD restart at 0401-01-01 from adspinup case

E3SM_DIN="/lustre/orion/cli115/world-shared/e3sm/inputdata"
FORC_ROOT="/lustre/orion/cli115/world-shared/wangd/kiloCraft"
# Resolve kmELM root (works from case_gene/Frontier/... or scripts/frontier/)
KMELM_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
E3SM_SRCROOT="${KMELM_ROOT}/E3SM"
if [ ! -d "${E3SM_SRCROOT}/cime/scripts" ]; then
  echo "ERROR: E3SM not found at ${E3SM_SRCROOT}" >&2
  exit 1
fi

AD_CASE_NAME="I1850ERACNPRDCTCBC_f09_adspinup"
CASE_NAME="I1850ERACNPRDCTCBC_f09_finalspinup"
CASEDIR="${E3SM_SRCROOT}/e3sm_cases/${CASE_NAME}"

AD_FINIDAT="${E3SM_SRCROOT}/e3sm_runs/${AD_CASE_NAME}/run/${AD_CASE_NAME}.elm.r.0401-01-01-00000.nc"

NTASKS_ALL="${NTASKS_ALL:-1280}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR: ${CASEDIR}"
echo "AD_FINIDAT: ${AD_FINIDAT}"
echo "NTASKS_ALL: ${NTASKS_ALL}"

if [ ! -f "${AD_FINIDAT}" ]; then
  echo "WARNING: AD finidat not found yet:"
  echo "  ${AD_FINIDAT}"
  echo "Case will still be created; update user_nl_elm finidat and submit only after AD completes."
fi

rm -rf "${CASEDIR}"
mkdir -p "${E3SM_SRCROOT}/e3sm_cases"

"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach frontier \
  --compiler craygnu \
  --compset I1850ERACNPRDCTCBC \
  --res f09_f09 \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${E3SM_SRCROOT}/e3sm_runs"

# Continue model clock from end of AD (year 0401)
./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE=0401-01-01
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1999

./xmlchange ATM_NCPL=4
./xmlchange LND_NCPL=4
./xmlchange ROF_NCPL=4
./xmlchange ICE_NCPL=4

# 800 years total: 100-year segments, first + 7 resubmits
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=100
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=100
./xmlchange RESUBMIT=7
./xmlchange CONTINUE_RUN=FALSE

./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_ACCELERATED_SPINUP=off

# Frontier batch max walltime is 2 hours
./xmlchange JOB_WALLCLOCK_TIME=02:00:00
./xmlchange USER_REQUESTED_WALLTIME=02:00:00

./xmlchange MAX_MPITASKS_PER_NODE=64
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
./preview_namelists

echo "==== final spinup config ===="
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,DATM_CLMNCEP_YR_ALIGN
./xmlquery RUN_TYPE,RUN_STARTDATE,STOP_OPTION,STOP_N,REST_N,RESUBMIT,ELM_ACCELERATED_SPINUP,ATM_NCPL

echo "Case created: ${CASEDIR}"
echo "finidat (from AD): ${AD_FINIDAT}"
echo "Next (after AD finishes): cd ${CASEDIR} && ./case.build && ./case.submit"
