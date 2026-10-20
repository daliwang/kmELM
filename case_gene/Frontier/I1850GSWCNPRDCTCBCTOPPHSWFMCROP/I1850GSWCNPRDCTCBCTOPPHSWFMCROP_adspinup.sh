#!/bin/bash
set -euo pipefail

# Frontier AD (accelerated-decomposition) spinup for
# I1850GSWCNPRDCTCBCTOPPHSWFMCROP @ ne30pg2_r05_IcoswISC30E3r5
#
# Science settings follow docs/AI4ELM_Spinup_repeat.md (Perlmutter as-run).
# Machine/PE/walltime adapted for Frontier (craygnu, 2 h max below 92 nodes).
#
# Source: E3SM-ai4elm @ 48d8ff20cc (jinyuntang/elm/fix-top-crop-compsets pin).
# Custom NetCDFs: see DATA.md in this directory.

# CIME needs Python >= 3.9. Frontier login default is 3.6.
if [[ -f /opt/cray/pe/lmod/lmod/init/bash ]]; then
  # shellcheck disable=SC1091
  source /opt/cray/pe/lmod/lmod/init/bash
elif [[ -f /usr/share/lmod/lmod/init/bash ]]; then
  # shellcheck disable=SC1091
  source /usr/share/lmod/lmod/init/bash
fi
if command -v module >/dev/null 2>&1; then
  module load cray-python/3.11.7
fi
python3 - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit(
        "ERROR: CIME needs Python >= 3.9, found %s (%s).\n"
        "Load cray-python first: module load cray-python/3.11.7"
        % (sys.version.split()[0], sys.executable)
    )
print("Using Python %s (%s)" % (sys.version.split()[0], sys.executable))
PY

E3SM_DIN="/lustre/orion/cli115/world-shared/e3sm/inputdata"
# GSWP3 lives under DIN_LOC_ROOT/atm/datm7; keep CLMFORC at the datm7 root.
FORC_ROOT="${E3SM_DIN}/atm/datm7"
CUSTOM_DATA="${CUSTOM_DATA:-/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup}"

KMELM_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
E3SM_SRCROOT="${E3SM_SRCROOT:-${KMELM_ROOT}/E3SM-ai4elm}"
PIN_SHA="48d8ff20ccb32d6cddcb2fcd6d83fddaf03ee53a"

if [[ ! -d "${E3SM_SRCROOT}/cime/scripts" ]]; then
  echo "ERROR: E3SM-ai4elm not found at ${E3SM_SRCROOT}" >&2
  echo "Create it first (from kmELM root):" >&2
  echo "  git -C E3SM fetch upstream ${PIN_SHA}" >&2
  echo "  git -C E3SM branch -f ai4elm-spinup-pin ${PIN_SHA}" >&2
  echo "  git -C E3SM worktree add E3SM-ai4elm ai4elm-spinup-pin" >&2
  echo "  git -C E3SM-ai4elm submodule update --init --reference E3SM cime externals/mct externals/scorpio externals/scorpio_classic" >&2
  exit 1
fi

HEAD_SHA="$(git -C "${E3SM_SRCROOT}" rev-parse HEAD)"
if [[ "${HEAD_SHA}" != "${PIN_SHA}" ]]; then
  echo "WARNING: E3SM-ai4elm HEAD is ${HEAD_SHA}, expected pin ${PIN_SHA}" >&2
fi

CASE_NAME="I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup"
CASEDIR="${E3SM_SRCROOT}/e3sm_cases/${CASE_NAME}"

# ~24 Perlmutter nodes x 128 ranks ≈ 3072; on Frontier use 64 MPI/node → 48 nodes.
# Stay under 92 nodes so default batch walltimemax is 2:00:00.
NTASKS_ALL="${NTASKS_ALL:-3072}"
MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE:-64}"
# 2 model years fits a 2 h Frontier slot at ~Perlmutter SYPD; tune after smoke.
STOP_N="${STOP_N:-2}"

echo "E3SM_SRCROOT: ${E3SM_SRCROOT}"
echo "CASEDIR:      ${CASEDIR}"
echo "CUSTOM_DATA:  ${CUSTOM_DATA}"
echo "NTASKS_ALL:   ${NTASKS_ALL}  (MAX_MPITASKS_PER_NODE=${MAX_MPITASKS_PER_NODE})"
echo "STOP_N:       ${STOP_N} years"

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
  echo "WARNING: custom inputs incomplete — see case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md"
  echo "         Creating case anyway; do not submit multi-year AD until staged."
fi

rm -rf "${CASEDIR}"
mkdir -p "${E3SM_SRCROOT}/e3sm_cases"

"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach frontier \
  --compiler craygnu \
  --compset I1850GSWCNPRDCTCBCTOPPHSWFMCROP \
  --res ne30pg2_r05_IcoswISC30E3r5 \
  --driver moab \
  --project cli115 \
  --walltime 02:00:00 \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${E3SM_SRCROOT}/e3sm_runs"

# Match Perlmutter science clock / forcing cycle
./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE=0001-01-01
./xmlchange CONTINUE_RUN=FALSE
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920

# Land dtime 1800 s → ATM_NCPL=48; ROF coupling 10800 s → ROF_NCPL=8
./xmlchange ATM_NCPL=48
./xmlchange ROF_NCPL=8

./xmlchange ELM_FORCE_COLDSTART=on
./xmlchange ELM_ACCELERATED_SPINUP=on
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -bgc_spinup on -nutrient_comp_pathway rd -soil_decomp ctc -methane -hydrstress -irrig .true. -tw_irr_on -crop -solar_rad_scheme top"

./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N="${STOP_N}"
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=1
./xmlchange RESUBMIT=0
./xmlchange DOUT_S=FALSE
./xmlchange SAVE_TIMING=FALSE

./xmlchange JOB_WALLCLOCK_TIME=02:00:00
./xmlchange USER_REQUESTED_WALLTIME=02:00:00

# CPU land layout (override Frontier GPU default of 8 MPI/node).
# Keep MAX_TASKS_PER_NODE == MAX_MPITASKS_PER_NODE so node count is N/64, not N/56.
./xmlchange MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE}"
./xmlchange MAX_TASKS_PER_NODE="${MAX_MPITASKS_PER_NODE}"
./xmlchange NTASKS="${NTASKS_ALL}"
./xmlchange NTASKS_ATM="${NTASKS_ALL}"
./xmlchange NTASKS_LND="${NTASKS_ALL}"
./xmlchange NTASKS_ROF="${NTASKS_ALL}"
./xmlchange NTASKS_ICE="${NTASKS_ALL}"
./xmlchange NTASKS_OCN="${NTASKS_ALL}"
./xmlchange NTASKS_CPL="${NTASKS_ALL}"
./xmlchange NTASKS_GLC="${NTASKS_ALL}"
./xmlchange NTASKS_WAV="${NTASKS_ALL}"

# Cold start via ELM_FORCE_COLDSTART=on; do not set finidat (incompatible with start_type=cold).
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

# Empty user_nl for datm/cpl placeholders (extend after comparing Perlmutter CaseDocs)
touch user_nl_datm user_nl_cpl

./case.setup
./preview_namelists

echo "==== AD spinup config ===="
./xmlquery COMPSET,GRID,COMP_INTERFACE
./xmlquery DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,DATM_CLMNCEP_YR_ALIGN
./xmlquery RUN_STARTDATE,STOP_OPTION,STOP_N,REST_N,RESUBMIT,ELM_ACCELERATED_SPINUP,ATM_NCPL,ROF_NCPL
./xmlquery NTASKS,MAX_MPITASKS_PER_NODE,JOB_WALLCLOCK_TIME,DIN_LOC_ROOT

echo
echo "Case created: ${CASEDIR}"
echo "Next:"
echo "  1. Stage custom inputs (DATA.md) into ${CUSTOM_DATA}"
echo "  2. cd ${CASEDIR} && ./case.build"
echo "  3. Short smoke (optional): ./xmlchange STOP_OPTION=ndays,STOP_N=5 && ./case.submit"
echo "  4. Restore STOP_OPTION=nyears,STOP_N=${STOP_N} for AD segments; raise RESUBMIT as needed"
echo "Do not expect bit-for-bit match to Perlmutter (intel → craygnu)."
