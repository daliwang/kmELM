#!/bin/bash
set -euo pipefail

# Create I1850ERACNPRDCTCBC smoke-test case on f09_f09 with ERA5 6hr->f09 forcing.

E3SM_DIN="/lustre/orion/cli115/world-shared/e3sm/inputdata"
FORC_ROOT="/lustre/orion/cli115/world-shared/wangd/kiloCraft"
E3SM_SRCROOT="$(cd "$(dirname "$0")/../.." && pwd)/E3SM"
if [ ! -d "${E3SM_SRCROOT}/cime/scripts" ]; then
  E3SM_SRCROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)/E3SM"
fi

CASE_NAME="I1850ERACNPRDCTCBC_f09_smoke1980"
CASEDIR="${E3SM_SRCROOT}/e3sm_cases/${CASE_NAME}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR: ${CASEDIR}"
echo "FORC_ROOT: ${FORC_ROOT}"

rm -rf "${CASEDIR}"

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
# namelist paths are $DIN_LOC_ROOT_CLMFORC/ERA5_6hr_f09/...
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${E3SM_SRCROOT}/e3sm_runs"

./xmlchange RUN_STARTDATE=1980-01-01
./xmlchange DATM_CLMNCEP_YR_ALIGN=1980
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1980

# 6-hourly forcing (match ATM coupling for LND/ROF/ICE)
./xmlchange ATM_NCPL=4
./xmlchange LND_NCPL=4
./xmlchange ROF_NCPL=4
./xmlchange ICE_NCPL=4

./xmlchange STOP_OPTION=ndays
./xmlchange STOP_N=5
./xmlchange REST_OPTION=ndays
./xmlchange REST_N=5

./xmlchange ELM_FORCE_COLDSTART=on

./xmlchange JOB_WALLCLOCK_TIME=02:00:00
./xmlchange USER_REQUESTED_WALLTIME=02:00:00

# Modest PE layout for smoke test
./xmlchange NTASKS=128
./xmlchange NTASKS_ATM=128
./xmlchange NTASKS_LND=128
./xmlchange NTASKS_ROF=128
./xmlchange NTASKS_ICE=128
./xmlchange NTASKS_OCN=128
./xmlchange NTASKS_CPL=128
./xmlchange NTASKS_GLC=128
./xmlchange NTASKS_WAV=128

cat >> user_nl_elm <<EOF
 hist_nhtfrq = -24
 hist_mfilt  = 6
EOF

./case.setup
./preview_namelists

echo "==== DATM mode / years ===="
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,ATM_NCPL,RUN_STARTDATE

echo "==== stream sample (ERAf09 / ROF_NCPL=4) ===="
./xmlquery ATM_NCPL,LND_NCPL,ROF_NCPL,ICE_NCPL,DATM_MODE
ls CaseDocs/datm.streams.txt.ERAf09* 2>/dev/null | head
head -40 CaseDocs/datm.streams.txt.ERAf09.t2m 2>/dev/null || \
  head -40 Buildconf/datmconf/datm.streams.txt.ERAf09.t2m 2>/dev/null || true

echo "Case created and setup complete."
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
