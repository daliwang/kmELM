#!/bin/bash

set -e

# Create a test kmELMcase with dataset created by kiloCraft for DATM with I1850CNPRDCTCBC compset

KILOCRAFT_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kiloCraft/"
KMELM_ROOT=$(git rev-parse --show-toplevel)
KMELM_CASE_ROOT="${KMELM_ROOT}/e3sm_cases/"
KMELM_RUN_ROOT="${KMELM_ROOT}/e3sm_runs/"

# Define the root directories for the E3SM data and source code
E3SM_SRC_ROOT="${KMELM_ROOT}/E3SM/"
E3SM_DIN="//gpfs/wolf2/cades/cli185/world-shared/e3sm"

echo "KILOCRAFT_ROOT: $KILOCRAFT_ROOT"
echo "KMELM_ROOT: $KMELM_ROOT"
echo "KMELM_CASE_ROOT: $KMELM_CASE_ROOT"
echo "KMELM_RUN_ROOT: $KMELM_RUN_ROOT"
echo "E3SM_SRC_ROOT: $E3SM_SRC_ROOT"
echo "E3SM_DIN: $E3SM_DIN"

# Define the root directory for the kmELM case data
TES_DATA_ROOT="$KILOCRAFT_ROOT/TES_cases_data/"
# Define the forcing data tag
TES_DOMAIN_FORCING_GROUP_ID="Daymet_ERA5_TESSFA2"
# Define the data group ID (Used in the domain and surface data file names)
TES_DATA_GROUP_ID="TES_SE"

# Define the root directory for the kmELM case experiments
#EXP_CASE_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kmELM/e3sm_cases/"
# Define the root directory for the kmELM case experiments
#EXP_RUN_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kmELM/e3sm_runs/"

# Define the experiment ID
EXPID="NC1PT"
# Define the experiment data group (Domain and forcing data specific group)

# Define the case directory
CASEDIR="$KMELM_CASE_ROOT/${TES_DOMAIN_FORCING_GROUP_ID}/uELM_${EXPID}_IBC1850CNPRDCTCBC"
# Define the case data directory
CASE_DATA="${TES_DATA_ROOT}/${TES_DOMAIN_FORCING_GROUP_ID}/${EXPID}"
# Define the domain file
DOMAIN_FILE="${EXPID}_domain.lnd.${TES_DATA_GROUP_ID}.4km.1d.c251003.nc"
# Define the surface data file
SURFDATA_FILE="${EXPID}_surfdata.${TES_DATA_GROUP_ID}.4km.1d.NLCD.c251003.nc"

echo "EXPID: $EXPID"
echo "EXP_DATA_GROUP: $EXP_DATA_GROUP"
echo "CASEDIR: $CASEDIR"
echo "CASE_DATA: $CASE_DATA"
echo "DOMAIN_FILE: $DOMAIN_FILE"
echo "SURFDATA_FILE: $SURFDATA_FILE"

\rm -rf "${CASEDIR}"

${E3SM_SRC_ROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach cades-baseline --compiler gnu --mpilib openmpi --compset I1850CNPRDCTCBC --res ELM_USRDAT  --handle-preexisting-dirs r --srcroot "${E3SM_SRC_ROOT}"

cd "${CASEDIR}"

# Define the case configuration

./xmlchange PIO_TYPENAME="pnetcdf"
./xmlchange PIO_NETCDF_FORMAT="64bit_data"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"

./xmlchange CIME_OUTPUT_ROOT="$KMELM_RUN_ROOT"

# Define the data mode, particial cleaunp unless there are calibration-related fields
# The forcing data is stored in $CASE_DATA/atm_forcing.datm7.km.1d/
# The domain and surface data file are stored in $CASE_DATA/domain_surfdata/

./xmlchange DATM_MODE="uELM_TES"

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"


# Define the Scientific Experiment Configuration
./xmlchange STOP_N="400"
./xmlchange REST_N="20"
./xmlchange STOP_OPTION="nyears"

./xmlchange ATM_NCPL="24"
./xmlchange DATM_CLMNCEP_YR_START="1980"
./xmlchange DATM_CLMNCEP_YR_END="1999"
./xmlchange DATM_CLMNCEP_YR_ALIGN="1990"

./xmlchange ELM_FORCE_COLDSTART="on"

./xmlchange CONTINUE_RUN="FALSE"
./xmlchange ELM_ACCELERATED_SPINUP="on"
./xmlchange  --append ELM_BLDNML_OPTS="-bgc_spinup on"

echo "fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      spinup_state = 1
      suplphos = 'ALL'
      hist_nhtfrq=-175200
      hist_mfilt=1
      nyears_ad_carbon_only = 25
      spinup_mortality_factor = 10
     " >> user_nl_elm

# Computational resources settings
./xmlchange NTASKS="1"
./xmlchange NTASKS_PER_INST="1"
./xmlchange MAX_MPITASKS_PER_NODE="1"
./xmlchange JOB_WALLCLOCK_TIME="2:00:00"

./case.setup --reset

./case.setup

./case.build --clean-all

./case.build

./case.submit

