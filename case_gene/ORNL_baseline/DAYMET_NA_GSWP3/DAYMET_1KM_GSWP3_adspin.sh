#!/bin/bash

set -e

# Create a test case uELM_TES_SEBOX_I1850uELMCNPRDCTCBC

#E3SM_DIN="/gpfs/wolf2/cades/cli185/proj-shared/pt-e3sm-inputdata"
E3SM_DIN="//gpfs/wolf2/cades/cli185/world-shared/e3sm"
DATA_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kiloCraft/NA_cases_data/"
E3SM_SRCROOT=$(git rev-parse --show-toplevel)
echo "E3SM_SRCROOT: $E3SM_SRCROOT"
echo "E3SM_DIN: $E3SM_DIN"

EXPID="WDRUN1"
CASEDIR="$E3SM_SRCROOT/e3sm_cases/uELM_${EXPID}_I1850uELMCNPRDCTCBC"
CASE_DATA="${DATA_ROOT}/${EXPID}"
DOMAIN_FILE="domain.lnd.Daymet_NA.1km.1d.c250330.nc"
SURFDATA_FILE="surfdata.Daymet_NA.1km.1d.c250330.nc"

\rm -rf "${CASEDIR}"

#${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach summitPlus --compiler pgi --mpilib spectrum-mpi --compset I1850uELMCNPRDCTCBC --res ELM_USRDAT --pecount "${PECOUNT}" --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach cades-baseline --compiler gnu --mpilib openmpi --compset I1850uELMTESCNPRDCTCBC --res ELM_USRDAT  --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange PIO_TYPENAME="pnetcdf"

./xmlchange PIO_NETCDF_FORMAT="64bit_data"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"

./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"

./xmlchange CIME_OUTPUT_ROOT="${E3SM_SRCROOT}/e3sm_runs/"

./xmlchange DATM_MODE="uELM_NA"

./xmlchange NTASKS="1"
./xmlchange NTASKS_LND="640"
./xmlchange NTASKS_ATM="50"
./xmlchange NTASKS_CPL="50"

./xmlchange NTASKS_PER_INST="1"

./xmlchange MAX_MPITASKS_PER_NODE="128"

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"

./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"

./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange JOB_WALLCLOCK_TIME="04:00:00"

./xmlchange ATM_NCPL="24"

./xmlchange DATM_CLMNCEP_YR_START="2014"
./xmlchange DATM_CLMNCEP_YR_END="2014"
./xmlchange DATM_CLMNCEP_YR_ALIGN="2014"

./xmlchange STOP_N="5"
./xmlchange REST_N="10"
./xmlchange STOP_OPTION="nhours"

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

./case.setup

./case.build --clean-all

./case.build

./xmlchange --force JOB_QUEUE="batch_ccsi"

#./case.submit

