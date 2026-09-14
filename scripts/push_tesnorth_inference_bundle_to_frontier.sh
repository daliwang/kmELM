#!/bin/bash
# Copy TES_NORTH inference bundle from Pathfinder to Frontier Orion (~51 GiB).
# 20-year AD restart, h0, clm_params, domain, surfdata.
#
# Run in an interactive Pathfinder terminal. Enter OLCF RSA once.
# Re-run the same command to resume.
#
#   DEST_HOST=dtn101.ccs.ornl.gov bash scripts/push_tesnorth_inference_bundle_to_frontier.sh

set -euo pipefail

SRC="${SRC:-/projects/hpcl-cli185/proj-shared/wangd/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_TESNORTH_inference}"
DEST_HOST="${DEST_HOST:-dtn101.ccs.ornl.gov}"
DEST_USER="${DEST_USER:-wangd}"
# Parent already exists on Orion. Do not use --mkpath: DTN rsync is 3.1.3.
DEST="${DEST:-/lustre/orion/cli115/world-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH}"
REMOTE="${DEST_USER}@${DEST_HOST}"

if [[ "${DEST_HOST}" == "dtn.olcf.ornl.gov" || "${DEST_HOST}" == "frontier.olcf.ornl.gov" ]]; then
  echo "ERROR: pin a single DTN, e.g. DEST_HOST=dtn101.ccs.ornl.gov" >&2
  exit 1
fi

echo "SRC:  ${SRC}/{history_restart_files,domain_surfdata}"
echo "DEST: ${REMOTE}:${DEST}"
echo "Enter OLCF PIN + RSA when rsync/ssh prompts."
echo

rsync -a --info=stats1,progress2 --partial --append-verify \
  -e "ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=12 -o ControlMaster=no -o PreferredAuthentications=keyboard-interactive,publickey" \
  --exclude 'history_restart_files/visualizations/' \
  "${SRC}/history_restart_files" \
  "${SRC}/domain_surfdata" \
  "${REMOTE}:${DEST}/"

echo
echo "Done. Destination: ${REMOTE}:${DEST}"
echo "  ${DEST}/history_restart_files/  elm.r.0021 (49G), elm.h0.0021 (1.6G), clm_params_c211124.nc"
echo "  ${DEST}/domain_surfdata/        domain + NALCMS surfdata"
echo "CNP_parameters is already on Frontier:"
echo "  /lustre/orion/cli115/world-shared/e3sm/inputdata/lnd/clm2/paramdata/CNP_parameters_c180529.nc"
