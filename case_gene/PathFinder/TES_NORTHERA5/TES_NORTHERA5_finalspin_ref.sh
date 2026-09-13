#!/bin/bash

set -e

# Create the final (normal) spinup case for TES NORTHERA5 ERA5REF.
# Uses ${KMELM_ROOT}/E3SM (TES branch). Not E3SM-era5. See README.md.
# Companion to TES_NORTHERA5_ref.sh (accelerated / AD spinup).
# finidat points at the year-0401 AD-spinup restart (may be produced later,
# e.g. via AI model) from:
#   uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC
# Case creation does not require that restart file to exist yet.

CLI185PROJ_ROOT="/projects/hpcl-cli185/"

E3SM_DIN="${CLI185PROJ_ROOT}/world-shared/e3sm/inputdata"
DATA_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH"
KMELM_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kmELM"
E3SM_SRCROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kmELM/E3SM"

echo "E3SM_SRCROOT: $E3SM_SRCROOT"
echo "E3SM_DIN: $E3SM_DIN"

EXPID="NORTHERA5"
ADSPIN_CASE="uELM_${EXPID}_ERA5REF_I1850uELMCNPRDCTCBC"
CASEDIR="$KMELM_ROOT/e3sm_cases/${ADSPIN_CASE}_finalspin"
CASE_DATA="${DATA_ROOT}/entire_domain"
DOMAIN_FILE="${EXPID}_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc"
# Match the surfdata used by the AD-spinup reference case
SURFDATA_FILE="surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc"

# AD-spinup restart date / file (finidat target; may be created later via AI model)
ADSPIN_RESTART_DATE="0401-01-01"
ADSPIN_RESTART="${KMELM_ROOT}/e3sm_runs/${ADSPIN_CASE}/run/${ADSPIN_CASE}.elm.r.${ADSPIN_RESTART_DATE}-00000.nc"

if [ ! -f "${ADSPIN_RESTART}" ]; then
  echo "WARNING: AD-spinup restart not found yet:"
  echo "  ${ADSPIN_RESTART}"
  echo "Case will still be created; place the year-${ADSPIN_RESTART_DATE} restart before submit."
fi

\rm -rf "${CASEDIR}"

${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach pathfinder --compiler gnu --mpilib openmpi --compset I1850CNPRDCTCBC --res ELM_USRDAT  --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

# Pathfinder has no MOAB; the share build fails if the case stays on driver-moab.
./xmlchange COMP_INTERFACE=mct

./xmlchange PIO_TYPENAME="pnetcdf"

./xmlchange PIO_NETCDF_FORMAT="64bit_data"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"

./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"

./xmlchange CIME_OUTPUT_ROOT="${KMELM_ROOT}/e3sm_runs/"

./xmlchange DATM_MODE="uELM_TES"

./xmlchange NTASKS="1"
./xmlchange NTASKS_LND="1280"
./xmlchange NTASKS_ATM="100"
./xmlchange NTASKS_CPL="100"

./xmlchange NTASKS_PER_INST="1"

./xmlchange MAX_MPITASKS_PER_NODE="128"

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"

./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"

./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange JOB_WALLCLOCK_TIME="24:00:00"

./xmlchange ATM_NCPL="24"

./xmlchange DATM_CLMNCEP_YR_START="1980"
./xmlchange DATM_CLMNCEP_YR_END="1999"
./xmlchange DATM_CLMNCEP_YR_ALIGN="1990"

# Final / normal spinup: no accelerated BGC spinup
./xmlchange STOP_N="200"
./xmlchange REST_N="20"
./xmlchange STOP_OPTION="nyears"

./xmlchange CONTINUE_RUN="FALSE"
./xmlchange ELM_ACCELERATED_SPINUP="off"
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -nutrient_comp_pathway rd  -soil_decomp ctc -methane"
./xmlchange RUN_TYPE="startup"
./xmlchange RUN_STARTDATE="${ADSPIN_RESTART_DATE}"

echo "finidat = '${ADSPIN_RESTART}'
fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      hist_dov2xy = .true.,.true.
      hist_nhtfrq=-175200
      hist_mfilt=1
      spinup_state = 0
      suplphos = 'NONE'
     " >> user_nl_elm

./case.setup --reset

./case.setup

./case.build --clean-all

./case.build

# Queue from the pathfinder Slurm definition (partition parallel, QOS normal).
./xmlchange JOB_QUEUE="parallel"

#./case.submit
