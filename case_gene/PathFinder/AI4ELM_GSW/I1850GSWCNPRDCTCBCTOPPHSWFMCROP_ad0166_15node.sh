#!/bin/bash
set -euo pipefail

# Pathfinder 15-node (1920 MPI) 1-year AD segment starting from Jinyun's
# Perlmutter AD restart (0166-01-01).
#
# Science matches the smoke / AD scripts (GSWP3 TOP/crop, spinup_state=1).
# Queue: parallel (CIME adds --constraint=NDR). Slurm memory: 500g/node.
#
#   bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node.sh
#   cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node
#   ./case.build && ./case.submit
#
# user_nl_elm is written into the case directory (not under E3SM-ai4elm):
#   ${KMELM_ROOT}/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node/user_nl_elm
# After preview_namelists, the resolved file is CaseDocs/lnd_in (finidat=...).
#
# Jinyun restart (Perlmutter; copy the elm.r here before submit):
#   /pscratch/sd/j/jinyun/e3sm_scratch/pm-cpu/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup/run/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0166-01-01-00000.nc
#
# Do not CONTINUE_RUN from the Perlmutter run dir: that coupler restart is
# 3072 ranks. This case is startup + ELM finidat only (MOSART/DATM/cpl cold).

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

CASE_NAME="${CASE_NAME:-I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node}"
CASEDIR="${CASE_ROOT}/${CASE_NAME}"
NTASKS_ALL="${NTASKS_ALL:-1920}"   # 15 nodes x 128
WALLTIME="${WALLTIME:-12:00:00}"
STOP_N="${STOP_N:-1}"
MEM_GB="${MEM_GB:-500}"
JOB_QUEUE="${JOB_QUEUE:-parallel}"
RUN_STARTDATE="${RUN_STARTDATE:-0166-01-01}"

AD_FINIDAT="${AD_FINIDAT:-${CUSTOM_DATA}/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0166-01-01-00000.nc}"

echo "E3SM_SRCROOT:  ${E3SM_SRCROOT}"
echo "CASEDIR:       ${CASEDIR}"
echo "CUSTOM_DATA:   ${CUSTOM_DATA}"
echo "AD_FINIDAT:    ${AD_FINIDAT}"
echo "NTASKS_ALL:    ${NTASKS_ALL}  (15 nodes x 128 if default)"
echo "JOB_QUEUE:     ${JOB_QUEUE}"
echo "MEM_GB:        ${MEM_GB}"
echo "STOP_N:        ${STOP_N} year(s) from ${RUN_STARTDATE}"
echo "user_nl_elm:   ${CASEDIR}/user_nl_elm"

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

if [[ ! -f "${AD_FINIDAT}" ]]; then
  echo "WARNING: Jinyun AD restart is not on Pathfinder yet:"
  echo "  ${AD_FINIDAT}"
  echo "Copy from Perlmutter before ./case.submit, for example:"
  echo "  scp wangd@perlmutter.nersc.gov:/pscratch/sd/j/jinyun/e3sm_scratch/pm-cpu/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup/run/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0166-01-01-00000.nc \\"
  echo "    ${AD_FINIDAT}"
  echo "Or set AD_FINIDAT=/path/to/the.elm.r.0166-01-01-00000.nc"
fi

if [[ "${NTASKS_ALL}" -ne 1920 ]]; then
  echo "WARNING: NTASKS_ALL=${NTASKS_ALL} (default 1920 = 15 nodes). Nodes = ceil(NTASKS/128)."
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
./xmlchange RUN_STARTDATE="${RUN_STARTDATE}"
./xmlchange CONTINUE_RUN=FALSE
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920

./xmlchange ATM_NCPL=48
./xmlchange ROF_NCPL=8

./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_ACCELERATED_SPINUP=on
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -bgc_spinup on -nutrient_comp_pathway rd -soil_decomp ctc -methane -hydrstress -irrig .true. -tw_irr_on -crop -solar_rad_scheme top"

./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N="${STOP_N}"
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=1
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

# user_nl_elm lives in this case directory. The only science change vs smoke
# is finidat -> Jinyun elm.r.0166 (and coldstart off in XML above).
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
 finidat = '${AD_FINIDAT}'
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

# Machine default is --mem=400g. Raise per-node request (NDR nodes have ~2.2 TiB).
for envf in env_batch.xml LockedFiles/env_batch.xml; do
  if [[ -f "${envf}" ]]; then
    sed -i -E "s/--mem=[0-9]+[gG]/--mem=${MEM_GB}g/" "${envf}"
  fi
done
if ! grep -q -- "--mem=${MEM_GB}g" env_batch.xml; then
  echo "WARNING: failed to set --mem=${MEM_GB}g in env_batch.xml; edit it before submit." >&2
fi

./preview_namelists

echo "==== 15-node AD-from-0166 config ===="
./xmlquery COMPSET,GRID,COMP_INTERFACE,DATM_MODE
./xmlquery RUN_STARTDATE,STOP_OPTION,STOP_N,NTASKS,JOB_QUEUE,JOB_WALLCLOCK_TIME
echo "Slurm mem directive:"
grep -E -- '--mem=' env_batch.xml || true
echo "finidat in user_nl_elm:"
grep -E 'finidat' user_nl_elm || true

echo
echo "Case created: ${CASEDIR}"
echo "user_nl_elm:  ${CASEDIR}/user_nl_elm"
echo "Next:"
echo "  1. Place Jinyun elm.r.0166 at:"
echo "       ${AD_FINIDAT}"
echo "  2. cd ${CASEDIR} && ./case.build && ./case.submit"
echo "NDR (parallel --constraint=NDR) is often busy; 15 exclusive nodes will queue."
