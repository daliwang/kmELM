#!/bin/bash
set -euo pipefail

# Frontier 30-node (240 MPI = 30 x 8) 1-year AD segment starting from
# Jinyun's AD restart elm.r.0021 (startup + ELM finidat only; gridcell=94838).
#
# 8 MPI/node is required. Job 5994423 (128 ranks at 64/node) read the 57 GB
# elm.r then aborted in MCT map init (MaxRSS ~44 GiB/rank, ~8 GiB available).
# Job 6005996 (128 ranks at 8/node, PIO=netcdf) finished a 5-day CONTINUE.
# See docs/AI4ELM_mct_restart_memory.md.
#
# Matches Pathfinder ad0021_15node science: GSWP3 TOP/crop, spinup_state=1,
# ELM_FORCE_COLDSTART=off. Coupler/MOSART/DATM are cold (do not CONTINUE_RUN
# from Perlmutter — PE layout differs).
#
# Do NOT use flat ai4elm_spinup/20261015…elm.r.0020 (gridcell=94935) — that
# aborted job 5988293. See docs/AI4ELM_finidat_gridcell_mismatch.md.
#
# MCT driver (MOAB failed on Frontier during ATM mesh / Zoltan).
# Frontier walltimemax is 2:00:00 below 92 nodes.
#
#   bash case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_30node.sh
#   cd E3SM-ai4elm/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_30node
#   ./case.build && ./case.submit

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
FORC_ROOT="${E3SM_DIN}/atm/datm7"
CUSTOM_DATA="${CUSTOM_DATA:-/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup}"

KMELM_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
E3SM_SRCROOT="${E3SM_SRCROOT:-${KMELM_ROOT}/E3SM-ai4elm}"
PIN_SHA="48d8ff20ccb32d6cddcb2fcd6d83fddaf03ee53a"

if [[ ! -d "${E3SM_SRCROOT}/cime/scripts" ]]; then
  echo "ERROR: E3SM-ai4elm not found at ${E3SM_SRCROOT}" >&2
  exit 1
fi

HEAD_SHA="$(git -C "${E3SM_SRCROOT}" rev-parse HEAD)"
if [[ "${HEAD_SHA}" != "${PIN_SHA}" ]]; then
  echo "WARNING: E3SM-ai4elm HEAD is ${HEAD_SHA}, expected pin ${PIN_SHA}" >&2
fi

CASE_NAME="${CASE_NAME:-I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_30node}"
CASEDIR="${E3SM_SRCROOT}/e3sm_cases/${CASE_NAME}"

# 30 nodes x 8 MPI/node = 240. Do not raise MPI/node above 10.
NTASKS_ALL="${NTASKS_ALL:-240}"
MAX_MPITASKS_PER_NODE="${MAX_MPITASKS_PER_NODE:-8}"
WALLTIME="${WALLTIME:-02:00:00}"
STOP_N="${STOP_N:-1}"
RUN_STARTDATE="${RUN_STARTDATE:-0021-01-01}"

# Canonical Jinyun AD restart (gridcell=94838). Override AD_FINIDAT only with
# another 94838 file — never the 20261015 0018/0020/0022 set (94935).
AD_FINIDAT="${AD_FINIDAT:-${E3SM_SRCROOT}/AI_restart_files_Jinyun/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0021-01-01-00000.nc}"

echo "E3SM_SRCROOT:  ${E3SM_SRCROOT}"
echo "CASEDIR:       ${CASEDIR}"
echo "CUSTOM_DATA:   ${CUSTOM_DATA}"
echo "AD_FINIDAT:    ${AD_FINIDAT}"
echo "NTASKS_ALL:    ${NTASKS_ALL}  (MAX_MPITASKS_PER_NODE=${MAX_MPITASKS_PER_NODE})"
echo "STOP_N:        ${STOP_N} year(s) from ${RUN_STARTDATE}"
echo "WALLTIME:      ${WALLTIME}"

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
  echo "WARNING: custom inputs incomplete — see DATA.md in this directory"
fi

if [[ ! -f "${AD_FINIDAT}" ]]; then
  echo "ERROR: AD finidat not found: ${AD_FINIDAT}" >&2
  echo "Set AD_FINIDAT=/path/to/....elm.r....nc" >&2
  exit 1
fi
if command -v ncdump >/dev/null 2>&1; then
  gc="$(ncdump -h "${AD_FINIDAT}" 2>/dev/null | sed -n 's/.*gridcell = \([0-9]*\).*/\1/p' | head -1)"
  echo "AD_FINIDAT gridcell=${gc:-unknown} (expect 94838)"
  if [[ -n "${gc}" && "${gc}" != "94838" ]]; then
    echo "ERROR: finidat gridcell=${gc} != 94838. See docs/AI4ELM_finidat_gridcell_mismatch.md" >&2
    exit 1
  fi
fi

if [[ "${MAX_MPITASKS_PER_NODE}" -gt 10 ]]; then
  echo "ERROR: MAX_MPITASKS_PER_NODE=${MAX_MPITASKS_PER_NODE} OOMs after the elm.r read (~42 GiB/rank)." >&2
  echo "Use 8. See docs/AI4ELM_mct_restart_memory.md" >&2
  exit 1
fi
expected_nodes=$(( (NTASKS_ALL + MAX_MPITASKS_PER_NODE - 1) / MAX_MPITASKS_PER_NODE ))
if [[ "${expected_nodes}" -ne 30 ]]; then
  echo "WARNING: NTASKS_ALL=${NTASKS_ALL} / ${MAX_MPITASKS_PER_NODE} → ${expected_nodes} nodes (want 30)."
fi

rm -rf "${CASEDIR}"
mkdir -p "${E3SM_SRCROOT}/e3sm_cases"

"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach frontier \
  --compiler craygnu \
  --compset I1850GSWCNPRDCTCBCTOPPHSWFMCROP \
  --res ne30pg2_r05_IcoswISC30E3r5 \
  --driver mct \
  --project cli115 \
  --walltime "${WALLTIME}" \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"

./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${FORC_ROOT}"
./xmlchange CIME_OUTPUT_ROOT="${E3SM_SRCROOT}/e3sm_runs"

# Code start: startup + ELM finidat (not coldstart, not CONTINUE_RUN)
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

# Serial NetCDF PIO, same as the CONTINUE that finished (job 6005996).
./xmlchange PIO_TYPENAME=netcdf

# 8 MPI/node → 30 nodes for 240 ranks. 60/node OOMs after the elm.r read.
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
./preview_namelists

echo "==== 30-node AD-from-0021 code-start config ===="
./xmlquery COMPSET,GRID,COMP_INTERFACE
./xmlquery RUN_TYPE,RUN_STARTDATE,STOP_OPTION,STOP_N,REST_N
./xmlquery ELM_ACCELERATED_SPINUP,ELM_FORCE_COLDSTART
./xmlquery NTASKS,MAX_MPITASKS_PER_NODE,PIO_TYPENAME,JOB_WALLCLOCK_TIME
echo "finidat / spinup_state:"
grep -E 'finidat|spinup_state' user_nl_elm || true
if command -v ncdump >/dev/null 2>&1; then
  echo -n "finidat gridcell: "
  ncdump -h "${AD_FINIDAT}" 2>/dev/null | grep -E '^\s*gridcell =' || true
fi

echo
echo "Case created: ${CASEDIR}"
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
echo "Note: Frontier max walltime at 30 nodes is 2:00:00; raise RESUBMIT if the year does not finish."
echo "Mesh note: docs/AI4ELM_finidat_gridcell_mismatch.md (must be gridcell=94838)."
echo "Memory note: docs/AI4ELM_mct_restart_memory.md (8 MPI/node, PIO=netcdf)."
