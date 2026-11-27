#!/bin/bash
set -euo pipefail

# Pathfinder 15-node (120 MPI = 15 x 8) 1-year AD segment starting from Jinyun's
# AD restart elm.r.0021 (on Pathfinder under AI_restart_files_Jinyun/).
# Requires gridcell=94838 (same mesh as smoke / Frontier MCT case).
#
# 8 MPI/node matches the Frontier CONTINUE that finished (job 6005996).
# The shared env default of 128 MPI/node leaves only a few GiB/rank under
# --mem=450g and will abort after the ~57 GB elm.r read.
# See docs/AI4ELM_mct_restart_memory.md.
#
# Science matches the smoke / AD scripts (GSWP3 TOP/crop, spinup_state=1).
# Queue: hpcl-cli185. Slurm memory: 450g/node (nodes ~503 GB; 500g is rejected).
#
#   bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node.sh
#   cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node
#   ./case.build && ./case.submit
#
# user_nl_elm is written into the case directory (not under E3SM-ai4elm):
#   ${KMELM_ROOT}/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node/user_nl_elm
# After preview_namelists, the resolved file is CaseDocs/lnd_in (finidat=...).
#
# Do not CONTINUE_RUN from the Perlmutter run dir: that coupler restart is
# 3072 ranks. This case is startup + ELM finidat only (MOSART/DATM/cpl cold).
#
# Do NOT use Frontier flat ai4elm_spinup/20261015…elm.r.0018/0020/0022
# (gridcell=94935). See docs/AI4ELM_finidat_gridcell_mismatch.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Capture before env.sh defaults JOB_QUEUE=parallel.
_USER_JOB_QUEUE="${JOB_QUEUE:-}"
# shellcheck source=pathfinder_ai4elm_env.sh
source "${SCRIPT_DIR}/pathfinder_ai4elm_env.sh"
# This case defaults to hpcl-cli185; honor an explicit JOB_QUEUE=... on the command line.
JOB_QUEUE="${_USER_JOB_QUEUE:-hpcl-cli185}"
unset _USER_JOB_QUEUE

python3 - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit(
        "ERROR: CIME needs Python >= 3.9, found %s (%s)."
        % (sys.version.split()[0], sys.executable)
    )
print("Using Python %s (%s)" % (sys.version.split()[0], sys.executable))
PY

CASE_NAME="${CASE_NAME:-I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node}"
CASEDIR="${CASE_ROOT}/${CASE_NAME}"
# env.sh defaults MAX_MPITASKS_PER_NODE=128. Override for this restart case.
MAX_MPITASKS_PER_NODE="${AI4ELM_PPN:-8}"
NTASKS_ALL="${NTASKS_ALL:-120}"   # 15 nodes x 8
WALLTIME="${WALLTIME:-12:00:00}"
STOP_N="${STOP_N:-1}"
MEM_GB="${MEM_GB:-450}"
RUN_STARTDATE="${RUN_STARTDATE:-0021-01-01}"

AD_FINIDAT="${AD_FINIDAT:-${CUSTOM_DATA}/AI_restart_files_Jinyun/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0021-01-01-00000.nc}"

echo "E3SM_SRCROOT:  ${E3SM_SRCROOT}"
echo "CASEDIR:       ${CASEDIR}"
echo "CUSTOM_DATA:   ${CUSTOM_DATA}"
echo "AD_FINIDAT:    ${AD_FINIDAT}"
echo "NTASKS_ALL:    ${NTASKS_ALL}  (MAX_MPITASKS_PER_NODE=${MAX_MPITASKS_PER_NODE})"
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
  echo "WARNING: Jinyun AD restart elm.r.0021 not found:"
  echo "  ${AD_FINIDAT}"
  echo "Or set AD_FINIDAT=/path/to/the.elm.r.0021-01-01-00000.nc"
elif command -v ncdump >/dev/null 2>&1; then
  gc="$(ncdump -h "${AD_FINIDAT}" 2>/dev/null | sed -n 's/.*gridcell = \([0-9]*\).*/\1/p' | head -1)"
  echo "AD_FINIDAT gridcell=${gc:-unknown} (expect 94838)"
  if [[ -n "${gc}" && "${gc}" != "94838" ]]; then
    echo "ERROR: finidat gridcell=${gc} != 94838. See docs/AI4ELM_finidat_gridcell_mismatch.md" >&2
    exit 1
  fi
fi

if [[ "${MAX_MPITASKS_PER_NODE}" -gt 10 ]]; then
  echo "ERROR: MAX_MPITASKS_PER_NODE=${MAX_MPITASKS_PER_NODE} OOMs after the elm.r read (~42 GiB/rank)." >&2
  echo "Use AI4ELM_PPN=8. See docs/AI4ELM_mct_restart_memory.md" >&2
  exit 1
fi
expected_nodes=$(( (NTASKS_ALL + MAX_MPITASKS_PER_NODE - 1) / MAX_MPITASKS_PER_NODE ))
if [[ "${expected_nodes}" -ne 15 ]]; then
  echo "WARNING: NTASKS_ALL=${NTASKS_ALL} / ${MAX_MPITASKS_PER_NODE} → ${expected_nodes} nodes (want 15)."
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

# Serial NetCDF PIO, same as Frontier job 6005996.
./xmlchange PIO_TYPENAME=netcdf

# 8 MPI/node. Also set MAX_TASKS_PER_NODE so the node count is N/8.
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

# AD continue from Jinyun elm.r.0021: spinup_state=1, coldstart off in XML above.
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

# Machine default is --mem=400g. Raise for hpcl-cli185 (~503 GB RealMemory).
for envf in env_batch.xml LockedFiles/env_batch.xml; do
  if [[ -f "${envf}" ]]; then
    sed -i -E "s/--mem=[0-9]+[gG]/--mem=${MEM_GB}g/" "${envf}"
  fi
done
if ! grep -q -- "--mem=${MEM_GB}g" env_batch.xml; then
  echo "WARNING: failed to set --mem=${MEM_GB}g in env_batch.xml; edit it before submit." >&2
fi

# case.setup may leave .case.run with parallel/NDR/-q normal; rewrite for this queue.
if [[ -f .case.run ]]; then
  python3 - "${MEM_GB}" "${JOB_QUEUE}" <<'PY'
import sys
from pathlib import Path
mem_gb, queue = sys.argv[1], sys.argv[2]
p = Path(".case.run")
lines = p.read_text().splitlines(True)
out = []
i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith("#SBATCH") and "--mem=" in line:
        out.append(f"#SBATCH  --mem={mem_gb}g\n")
    elif line.startswith("#SBATCH") and ("-q " in line or "--qos" in line):
        out.append(f"#SBATCH  -q {queue}\n")
    elif line.startswith("#SBATCH") and "--constraint=" in line:
        pass  # drop NDR constraint on hpcl-cli185
    else:
        out.append(line)
    i += 1
p.write_text("".join(out))
print(f"Patched .case.run for queue={queue} mem={mem_gb}g")
PY
fi

./preview_namelists

echo "==== 15-node AD-from-0021 config ===="
./xmlquery COMPSET,GRID,COMP_INTERFACE,DATM_MODE
./xmlquery RUN_STARTDATE,STOP_OPTION,STOP_N,NTASKS,MAX_MPITASKS_PER_NODE,PIO_TYPENAME,JOB_QUEUE,JOB_WALLCLOCK_TIME
./xmlquery ELM_ACCELERATED_SPINUP,ELM_FORCE_COLDSTART
echo "Slurm mem directive:"
grep -E -- '--mem=' env_batch.xml || true
echo "finidat / spinup_state in user_nl_elm:"
grep -E 'finidat|spinup_state' user_nl_elm || true

echo
echo "Case created: ${CASEDIR}"
echo "user_nl_elm:  ${CASEDIR}/user_nl_elm"
echo "finidat:      ${AD_FINIDAT}"
echo "Next: cd ${CASEDIR} && ./case.build && ./case.submit"
echo "Queue hpcl-cli185: 15 of 20 nodes; --mem=${MEM_GB}g per node; 8 MPI/node."
echo "Memory note: docs/AI4ELM_mct_restart_memory.md"
