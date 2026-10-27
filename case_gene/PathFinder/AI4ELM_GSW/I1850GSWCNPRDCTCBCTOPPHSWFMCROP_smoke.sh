#!/bin/bash
set -euo pipefail

# Pathfinder 5-day smoke for AI4ELM GSWP3 TOP/crop AD setup.
# Science matches Frontier/Perlmutter; PE sized for Pathfinder.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pathfinder_ai4elm_env.sh
source "${SCRIPT_DIR}/pathfinder_ai4elm_env.sh"

python3 - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit(
        "ERROR: CIME needs Python >= 3.9, found %s (%s)."
        % (sys.version.split()[0], sys.executable)
    )
print("Using Python %s (%s)" % (sys.version.split()[0], sys.executable))
PY

CASE_NAME="I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke"
CASEDIR="${CASE_ROOT}/${CASE_NAME}"
NTASKS_ALL="${NTASKS_ALL:-128}"
WALLTIME="${WALLTIME:-02:00:00}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR:      ${CASEDIR}"
echo "CUSTOM_DATA:  ${CUSTOM_DATA}"
echo "E3SM_DIN:     ${E3SM_DIN}"
echo "NTASKS_ALL:   ${NTASKS_ALL}"

missing=0
for f in \
  surfdata_0.5x0.5_50pfts_20250528.nc \
  clm_params_c251006.nc \
  ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc \
  MOSART_Global_half_20250523.nc \
  global_reservoir_halfdegree_c20200917.nc
do
  if [[ ! -f "${CUSTOM_DATA}/${f}" ]]; then
    echo "WARNING: missing custom input ${CUSTOM_DATA}/${f}"
    missing=1
  fi
done
if [[ "${missing}" -eq 1 ]]; then
  echo "WARNING: stage inputs first: bash ${SCRIPT_DIR}/stage_ai4elm_inputs.sh"
fi

rm -rf "${CASEDIR}"
mkdir -p "${CASE_ROOT}" "${RUN_ROOT}"

"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach "${MACH}" \
  --compiler "${COMPILER}" \
  --mpilib "${MPILIB}" \
  --compset I1850GSWCNPRDCTCBCTOPPHSWFMCROP \
  --res ne30pg2_r05_IcoswISC30E3r5 \
  --driver moab \
  --walltime "${WALLTIME}" \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${RUN_ROOT}"

./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE=0001-01-01
./xmlchange CONTINUE_RUN=FALSE
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920

./xmlchange ATM_NCPL=48
./xmlchange ROF_NCPL=8

./xmlchange ELM_FORCE_COLDSTART=on
./xmlchange ELM_ACCELERATED_SPINUP=on
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -bgc_spinup on -nutrient_comp_pathway rd -soil_decomp ctc -methane -hydrstress -irrig .true. -tw_irr_on -crop -solar_rad_scheme top"

./xmlchange STOP_OPTION=ndays
./xmlchange STOP_N=5
./xmlchange REST_OPTION=ndays
./xmlchange REST_N=5
./xmlchange RESUBMIT=0
./xmlchange DOUT_S=FALSE
./xmlchange SAVE_TIMING=FALSE

./xmlchange JOB_WALLCLOCK_TIME="${WALLTIME}"
./xmlchange USER_REQUESTED_WALLTIME="${WALLTIME}"

./xmlchange MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE}"
./xmlchange NTASKS="${NTASKS_ALL}"
./xmlchange NTASKS_ATM="${NTASKS_ALL}"
./xmlchange NTASKS_LND="${NTASKS_ALL}"
./xmlchange NTASKS_ROF="${NTASKS_ALL}"
./xmlchange NTASKS_ICE="${NTASKS_ALL}"
./xmlchange NTASKS_OCN="${NTASKS_ALL}"
./xmlchange NTASKS_CPL="${NTASKS_ALL}"
./xmlchange NTASKS_GLC="${NTASKS_ALL}"
./xmlchange NTASKS_WAV="${NTASKS_ALL}"

cat > user_nl_elm <<EOF
 spinup_state = 1
 suplnitro = 'NONE'
 suplphos = 'NONE'
 h2osfcflag = 0
 create_crop_landunit = .true.
 use_crop = .true.
 firrig_data = .true.
 check_finidat_fsurdat_consistency = .false.
 check_finidat_year_consistency = .false.
 hist_dov2xy = .true.,.true.
 fsurdat = '${CUSTOM_DATA}/surfdata_0.5x0.5_50pfts_20250528.nc'
 paramfile = '${CUSTOM_DATA}/clm_params_c251006.nc'
 stream_fldfilename_ndep = '${CUSTOM_DATA}/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc'
EOF

cat > user_nl_mosart <<EOF
 frivinp_rtm = '${CUSTOM_DATA}/MOSART_Global_half_20250523.nc'
 paraFile = '${CUSTOM_DATA}/global_reservoir_halfdegree_c20200917.nc'
 wrmflag = .true.
 inundflag = .true.
 opt_elevprof = 1
 damconstructionflag = 1
 data_bgc_fluxes_to_ocean_flag = .true.
EOF

touch user_nl_datm user_nl_cpl

./case.setup
./xmlchange --force JOB_QUEUE="${JOB_QUEUE}"
./preview_namelists

echo "==== smoke config ===="
./xmlquery COMPSET,GRID,COMP_INTERFACE,DATM_MODE
./xmlquery DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,ATM_NCPL,ROF_NCPL
./xmlquery STOP_OPTION,STOP_N,NTASKS,JOB_WALLCLOCK_TIME

echo "Case created: ${CASEDIR}"
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
echo "Require staged GSWP3 1901-1920 + custom files (see DATA.md)."
