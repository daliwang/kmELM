#!/bin/bash
set -e

KILOCRAFT_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kiloCraft/"
KMELM_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kmELM/"
KMELM_CASE_ROOT="${KMELM_ROOT}/e3sm_cases/"
KMELM_RUN_ROOT="${KMELM_ROOT}/e3sm_runs/"
E3SM_SRC_ROOT="${KMELM_ROOT}/E3SM/"
E3SM_DIN="//gpfs/wolf2/cades/cli185/world-shared/e3sm"

TES_DATA_ROOT="$KILOCRAFT_ROOT/TES_cases_data/"
TES_DOMAIN_FORCING_GROUP_ID="Daymet_ERA5_TESSFA2"
TES_DATA_GROUP_ID="TES_SE"

EXPID="TVA"
CASE_COMPSET="I1850CNPRDCTCBC"

CASEDIR="$KMELM_CASE_ROOT/${TES_DOMAIN_FORCING_GROUP_ID}/uELM_${EXPID}_${CASE_COMPSET}_finalspin"
#CASE_DATA="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
CASE_DATA="${TES_DATA_ROOT}/${TES_DOMAIN_FORCING_GROUP_ID}/${EXPID}"
echo "CASE_DATA: $CASE_DATA"

DOMAIN_FILE=$(ls -1 ${CASE_DATA}/domain_surfdata/${EXPID}_domain.lnd.${TES_DATA_GROUP_ID}.4km.1d.c*.nc 2>/dev/null | sort | tail -n1 | xargs -r basename)
if [ -z "${DOMAIN_FILE}" ]; then echo 'ERROR: Domain file not found'; exit 2; fi
SURFDATA_FILE=$(ls -1 ${CASE_DATA}/domain_surfdata/${EXPID}_surfdata.${TES_DATA_GROUP_ID}.4km.1d.NLCD.c*.nc 2>/dev/null | sort | tail -n1 | xargs -r basename)
if [ -z "${SURFDATA_FILE}" ]; then echo 'ERROR: Surfdata file not found'; exit 2; fi

rm -rf "${CASEDIR}"

${E3SM_SRC_ROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach cades-baseline --compiler gnu --mpilib openmpi --compset "${CASE_COMPSET}" --res ELM_USRDAT  --handle-preexisting-dirs r --srcroot "${E3SM_SRC_ROOT}"

cd "${CASEDIR}"

./xmlchange PIO_TYPENAME="pnetcdf"
./xmlchange PIO_NETCDF_FORMAT="64bit_data"
./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"
./xmlchange CIME_OUTPUT_ROOT="$KMELM_RUN_ROOT"

# Data mode and domain bindings
./xmlchange DATM_MODE="uELM_TES"
./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"
./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

# Scientific configuration for final spin
./xmlchange STOP_N="800"
./xmlchange REST_N="20"
./xmlchange STOP_OPTION="nyears"
./xmlchange ATM_NCPL="24"
./xmlchange DATM_CLMNCEP_YR_START="1980"
./xmlchange DATM_CLMNCEP_YR_END="1999"
./xmlchange DATM_CLMNCEP_YR_ALIGN="1990"
./xmlchange CONTINUE_RUN="FALSE"
./xmlchange ELM_ACCELERATED_SPINUP="off"
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -nutrient_comp_pathway rd  -soil_decomp ctc -methane"
./xmlchange RUN_TYPE="startup"
./xmlchange RUN_STARTDATE="0401-01-01"

cat >> user_nl_elm <<EOF
finidat = '${KMELM_RUN_ROOT}/uELM_${EXPID}_${CASE_COMPSET}/run/uELM_${EXPID}_${CASE_COMPSET}.elm.r.0401-01-01-00000.nc'
fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      spinup_state = 0
      suplphos = 'NONE'
      hist_nhtfrq=-175200
      hist_mfilt=1
EOF

# Computational resources settings
./xmlchange NTASKS="1"
./xmlchange NTASKS_LND="1280"
./xmlchange NTASKS_ATM="100"
./xmlchange NTASKS_CPL="100"

./xmlchange NTASKS_PER_INST="1"
./xmlchange MAX_MPITASKS_PER_NODE="128"

./xmlchange JOB_WALLCLOCK_TIME="24:00:00"

./case.setup --reset

./case.setup

./case.build --clean-all

./case.build

#./case.submit

