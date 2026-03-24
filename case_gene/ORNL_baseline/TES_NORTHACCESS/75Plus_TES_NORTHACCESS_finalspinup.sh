#!/bin/bash

set -e

# Create a test case uELM_TES_SEBOX_I1850uELMCNPRDCTCBC

#E3SM_DIN="/gpfs/wolf2/cades/cli185/proj-shared/pt-e3sm-inputdata"
E3SM_DIN="//gpfs/wolf2/cades/cli185/world-shared/e3sm"
DATA_ROOT="/gpfs/wolf2/cades/cli185/proj-shared/wangd/kiloCraft/TES_cases_data/ACCESS_TESSFA_North/"
E3SM_SRCROOT=$(git rev-parse --show-toplevel)
echo "E3SM_SRCROOT: $E3SM_SRCROOT"
echo "E3SM_DIN: $E3SM_DIN"

EXPID="75Plus"
CASEDIR="$E3SM_SRCROOT/e3sm_cases/uELM_${EXPID}_SPINUP_I1850uELMCNPRDCTCBC"
CASE_DATA="${DATA_ROOT}/${EXPID}"
DOMAIN_FILE="${EXPID}_domain.lnd.TES_NORTHACCESS.4km.1d.c250528.nc"
SURFDATA_FILE="${EXPID}_surfdata.TES_NORTHACCESS.4km.1d.c250528.nc"

\rm -rf "${CASEDIR}"

#${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach summitPlus --compiler pgi --mpilib spectrum-mpi --compset I1850uELMCNPRDCTCBC --res ELM_USRDAT --pecount "${PECOUNT}" --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach cades-baseline --compiler gnu --mpilib openmpi --compset I1850uELMTESCNPRDCTCBC --res ELM_USRDAT  --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange PIO_TYPENAME="pnetcdf"

./xmlchange PIO_NETCDF_FORMAT="64bit_data"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"

./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"

./xmlchange CIME_OUTPUT_ROOT="${E3SM_SRCROOT}/e3sm_runs/"

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

./xmlchange STOP_N="80"
./xmlchange REST_N="20"
./xmlchange STOP_OPTION="nyears"

./xmlchange  ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -nutrient_comp_pathway rd  -soil_decomp ctc -methane"

./xmlchange RUN_TYPE="startup"
./xmlchange RUN_STARTDATE="00001-01-01"
./xmlchange CONTINUE_RUN="FALSE"
./xmlchange RESUBMIT="7"


#### make sure the finidat point to the restart file you want to use from the ai4gbc run directory ###
echo "
finidat = '/gpfs/wolf2/cades/cli185/proj-shared/wangd/kmELM/e3sm_runs/uELM_75Plus_I1850uELMCNPRDCTCBC/run/uELM_75Plus_I1850uELMCNPRDCTCBC.elm.r.0401-01-01-00000.nc'
fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
spinup_state = 0
suplphos = 'NONE'
hist_mfilt=1
     " >> user_nl_elm

./case.setup

./case.build --clean-all

./case.build

./xmlchange --force JOB_QUEUE="batch_ccsi"

#./case.submit

