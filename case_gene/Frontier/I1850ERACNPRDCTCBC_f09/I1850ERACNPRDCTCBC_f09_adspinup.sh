#!/bin/bash
set -euo pipefail

# AD (accelerated decomposition) spinup for I1850ERACNPRDCTCBC on f09_f09
# with ERA5 6hr remapped to f09 (DATM_MODE=ERAf09).
#
# Forcing cycle: 20 years (1980-1999)
# Simulation length: 400 years (20-year segments x 20 via RESUBMIT)
#
# Do not submit until ERA5_6hr_f09 has all months for 1980-1999 (incl. 1994).

E3SM_DIN="/lustre/orion/cli115/world-shared/e3sm/inputdata"
FORC_ROOT="/lustre/orion/cli115/world-shared/wangd/kiloCraft"
# Resolve kmELM root (works from case_gene/Frontier/... or scripts/frontier/)
KMELM_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
E3SM_SRCROOT="${KMELM_ROOT}/E3SM"
if [ ! -d "${E3SM_SRCROOT}/cime/scripts" ]; then
  echo "ERROR: E3SM not found at ${E3SM_SRCROOT}" >&2
  exit 1
fi

CASE_NAME="I1850ERACNPRDCTCBC_f09_adspinup"
CASEDIR="${E3SM_SRCROOT}/e3sm_cases/${CASE_NAME}"

# PE layout (tune as needed). Smoke used 128; production f09 needs more.
NTASKS_ALL="${NTASKS_ALL:-1024}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR: ${CASEDIR}"
echo "FORC_ROOT: ${FORC_ROOT}"
echo "NTASKS_ALL: ${NTASKS_ALL}"

# Quick forcing completeness check for the 20-year cycle
FORC_DIR="${FORC_ROOT}/ERA5_6hr_f09"
NEXP=$((20 * 12 * 9))  # years * months * stream vars
NHAVE=$(find "${FORC_DIR}" -name 'elmforc.ERA5.c2018.0.9x1.25.*.19[89][0-9]-*.nc' | wc -l)
echo "Forcing files 1980-1999 found: ${NHAVE} (expect ${NEXP})"
if [ "${NHAVE}" -lt "${NEXP}" ]; then
  echo "WARNING: incomplete 1980-1999 forcing (missing 1994?). Continue creating case, but do not submit until complete."
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

# Model clock starts at year 0001; DATM cycles 1980-1999
./xmlchange RUN_STARTDATE=0001-01-01
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1999

# 6-hourly ERA forcing
./xmlchange ATM_NCPL=4
./xmlchange LND_NCPL=4
./xmlchange ROF_NCPL=4
./xmlchange ICE_NCPL=4

# 400 years total: 20-year segments, first + 19 resubmits
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=20
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=20
./xmlchange RESUBMIT=19
./xmlchange CONTINUE_RUN=FALSE

./xmlchange ELM_FORCE_COLDSTART=on
./xmlchange ELM_ACCELERATED_SPINUP=on
./xmlchange --append ELM_BLDNML_OPTS="-bgc_spinup on"

# Frontier batch max walltime is typically 6 hours
./xmlchange JOB_WALLCLOCK_TIME=06:00:00
./xmlchange USER_REQUESTED_WALLTIME=06:00:00

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
./preview_namelists

echo "==== AD spinup config ===="
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,DATM_CLMNCEP_YR_ALIGN
./xmlquery RUN_STARTDATE,STOP_OPTION,STOP_N,REST_N,RESUBMIT,ELM_ACCELERATED_SPINUP,ATM_NCPL

echo "Case created: ${CASEDIR}"
echo "Expected end restart: ${CASE_NAME}.elm.r.0401-01-01-00000.nc"
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
echo "Only submit after 1980-1999 forcing is complete (1080 files)."
