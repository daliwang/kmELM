#!/bin/bash

set -e

# Create a test case uELM_TES_SEBOX_I1850uELMCNPRDCTCBC
# Uses ${KMELM_ROOT}/E3SM (TES / TESSFA_4km). Not E3SM-era5. See README.md.

CLI185PROJ_ROOT="/projects/hpcl-cli185/"
# Same DIN as the successful ERA5REF cases (e3sm parent, not inputdata).
E3SM_DIN="${CLI185PROJ_ROOT}/world-shared/e3sm"
DATA_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH"
KMELM_ROOT="${CLI185PROJ_ROOT}/proj-shared/wangd/kmELM"
E3SM_SRCROOT="${KMELM_ROOT}/E3SM"
echo "E3SM_SRCROOT: $E3SM_SRCROOT"
echo "E3SM_DIN: $E3SM_DIN"

EXPID="NORTHERA5"
CASEDIR="${KMELM_ROOT}/e3sm_cases/uELM_${EXPID}_I1850uELMCNPRDCTCBC"
CASE_DATA="${DATA_ROOT}/entire_domain"
DOMAIN_FILE="${EXPID}_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc"
SURFDATA_FILE="surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc"


\rm -rf "${CASEDIR}"

#${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach summitPlus --compiler pgi --mpilib spectrum-mpi --compset I1850uELMCNPRDCTCBC --res ELM_USRDAT --pecount "${PECOUNT}" --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

${E3SM_SRCROOT}/cime/scripts/create_newcase --case "${CASEDIR}" --mach pathfinder --compiler gnu --mpilib openmpi --compset I1850uELMTESCNPRDCTCBC --res ELM_USRDAT  --handle-preexisting-dirs r --srcroot "${E3SM_SRCROOT}"

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
./xmlchange NTASKS_LND="640"
./xmlchange NTASKS_ATM="50"
./xmlchange NTASKS_CPL="50"

./xmlchange NTASKS_PER_INST="1"

./xmlchange MAX_MPITASKS_PER_NODE="128"

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"

./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"

./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange JOB_WALLCLOCK_TIME="06:00:00"

./xmlchange ATM_NCPL="24"

./xmlchange DATM_CLMNCEP_YR_START="1980"
./xmlchange DATM_CLMNCEP_YR_END="1999"
./xmlchange DATM_CLMNCEP_YR_ALIGN="1990"

./xmlchange STOP_N="20"
./xmlchange REST_N="20"
./xmlchange STOP_OPTION="nyears"

./xmlchange ELM_FORCE_COLDSTART="on"

./xmlchange CONTINUE_RUN="FALSE"
./xmlchange ELM_ACCELERATED_SPINUP="on"
./xmlchange  --append ELM_BLDNML_OPTS="-bgc_spinup on"

echo "fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      hist_dov2xy = .true.,.true.
!      hist_fincl2 = 'FSDS', 'GPP', 'FLDS', 'TBOT', 'RH2M'
!      hist_mfilt = 1,8760
!      hist_nhtfrq = 0,-1
      hist_nhtfrq=-175200
      hist_mfilt=1
      spinup_state = 1
      suplphos = 'ALL'
      nyears_ad_carbon_only = 25
      spinup_mortality_factor = 10
     " >> user_nl_elm

./case.setup --reset

./case.setup

./case.build --clean-all

./case.build

# Queue from the pathfinder Slurm definition (not CADES batch_ccsi).
./xmlchange JOB_QUEUE="parallel"

#./case.submit

