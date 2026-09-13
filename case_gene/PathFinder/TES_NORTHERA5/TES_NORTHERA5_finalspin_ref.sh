#!/bin/bash
set -e

# Recreate the successful Pathfinder continuous / final-spin case:
#   uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC_finalspin
# As-run finidat is the AI 0021 restart (not an AD 0401 file).
# Source: ${KMELM_ROOT}/E3SM (not E3SM-era5). See README.md.
#
# Deletes CASEROOT unless you set FORCE_RECREATE=1.

CLI185PROJ_ROOT="/projects/hpcl-cli185"
E3SM_DIN="${CLI185PROJ_ROOT}/world-shared/e3sm"
DATA_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH"
KMELM_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kmELM"
E3SM_SRCROOT="${KMELM_ROOT}/E3SM"

echo "E3SM_SRCROOT: $E3SM_SRCROOT"
echo "E3SM_DIN: $E3SM_DIN"

EXPID="NORTHERA5"
ADSPIN_CASE="uELM_${EXPID}_ERA5REF_I1850uELMCNPRDCTCBC"
CASEDIR="${KMELM_ROOT}/e3sm_cases/${ADSPIN_CASE}_finalspin"
CASE_DATA="${DATA_ROOT}/entire_domain"
DOMAIN_FILE="${EXPID}_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc"
SURFDATA_FILE="surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc"

# As-run: AI-updated restart (year 0021). The AD 0401 path was never used.
AD_RESTART_0401="${KMELM_ROOT}/e3sm_runs/${ADSPIN_CASE}/run/${ADSPIN_CASE}.elm.r.0401-01-01-00000.nc"
AI_RESTART="${CLI185PROJ_ROOT}/proj-shared/wangd/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_TESNORTH_inference/AI_restartfile/updated_restart_normal_spinup_${ADSPIN_CASE}.elm.r.0021-01-01-00000.nc"
FINIDAT="${AI_RESTART}"
RUN_STARTDATE="0401-01-01"

if [[ -d "${CASEDIR}" && "${FORCE_RECREATE:-0}" != "1" ]]; then
  echo "ERROR: ${CASEDIR} already exists (successful finalspin case)." >&2
  echo "Set FORCE_RECREATE=1 if you intend to delete and recreate it." >&2
  exit 1
fi

if [[ ! -f "${FINIDAT}" ]]; then
  echo "WARNING: AI restart not found yet:"
  echo "  ${FINIDAT}"
  echo "Case will still be created; place that file before submit."
fi

echo "CASEDIR: ${CASEDIR}"
echo "FINIDAT: ${FINIDAT}"
echo "SURFDATA: ${SURFDATA_FILE}"

\rm -rf "${CASEDIR}"

"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach pathfinder \
  --compiler gnu \
  --mpilib openmpi \
  --compset I1850CNPRDCTCBC \
  --res ELM_USRDAT \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange COMP_INTERFACE=mct
./xmlchange PIO_TYPENAME=pnetcdf
./xmlchange PIO_NETCDF_FORMAT=64bit_data
./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"
./xmlchange CIME_OUTPUT_ROOT="${KMELM_ROOT}/e3sm_runs/"
./xmlchange DATM_MODE=uELM_TES

# As-run PE: 1920 ATM/CPL/LND, 128 MPI/node.
./xmlchange NTASKS=1
./xmlchange NTASKS_ATM=1920
./xmlchange NTASKS_CPL=1920
./xmlchange NTASKS_LND=1920
./xmlchange NTASKS_PER_INST=1
./xmlchange MAX_MPITASKS_PER_NODE=128

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"
./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange JOB_WALLCLOCK_TIME=12:00:00
./xmlchange USER_REQUESTED_WALLTIME=12:00:00

./xmlchange ATM_NCPL=24
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1999
./xmlchange DATM_CLMNCEP_YR_ALIGN=1990

# As-run: 10-year segments, restart every 2 years (not 200/20).
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=10
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=2

./xmlchange CONTINUE_RUN=FALSE
./xmlchange ELM_ACCELERATED_SPINUP=off
./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -nutrient_comp_pathway rd  -soil_decomp ctc -methane"
./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE="${RUN_STARTDATE}"

cat >> user_nl_elm <<EOF
!finidat = '${AD_RESTART_0401}'
finidat = '${FINIDAT}'
fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      hist_dov2xy = .true.,.true.
      hist_nhtfrq=-175200
      hist_mfilt=1
      spinup_state = 0
      suplphos = 'NONE'
EOF

./case.setup --reset
./case.setup
./case.build --clean-all
./case.build

# As-run queue for the 1920-task continuous run.
./xmlchange --force JOB_QUEUE=hpcl-cli185
./xmlchange USER_REQUESTED_QUEUE=hpcl-cli185

echo "Case created: ${CASEDIR}"
echo "Submit is left to you: cd ${CASEDIR} && ./case.submit"
#./case.submit
