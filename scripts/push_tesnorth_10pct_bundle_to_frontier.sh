#!/bin/bash
# Copy TES_NORTH 10% training bundle (ERA5_10PCTSITES) to Frontier Orion (~16 GiB).
# Writes a dedicated ERA5_10PCTSITES/ directory so files do not mix with the
# full-domain history_restart_files / domain_surfdata.
#
#   DEST_HOST=dtn101.ccs.ornl.gov bash scripts/push_tesnorth_10pct_bundle_to_frontier.sh

set -euo pipefail

SRC="${SRC:-/projects/hpcl-cli185/proj-shared/wangd/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_10PCTSITES}"
DEST_HOST="${DEST_HOST:-dtn101.ccs.ornl.gov}"
DEST_USER="${DEST_USER:-wangd}"
DEST="${DEST:-/lustre/orion/cli115/world-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/ERA5_10PCTSITES}"
REMOTE="${DEST_USER}@${DEST_HOST}"

if [[ "${DEST_HOST}" == "dtn.olcf.ornl.gov" || "${DEST_HOST}" == "frontier.olcf.ornl.gov" ]]; then
  echo "ERROR: pin a single DTN, e.g. DEST_HOST=dtn101.ccs.ornl.gov" >&2
  exit 1
fi

if [[ ! -d "${SRC}/history_restart_files" || ! -d "${SRC}/domain_surfdata" ]]; then
  echo "ERROR: 10% bundle missing under ${SRC}" >&2
  exit 1
fi

echo "SRC:  ${SRC}"
echo "DEST: ${REMOTE}:${DEST}"
echo "Enter OLCF PIN + RSA when rsync/ssh prompts."
echo

# One source tree so DTN rsync 3.1.3 can create ERA5_10PCTSITES without --mkpath.
rsync -a --info=stats1,progress2 --partial --append-verify \
  -e "ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=12 -o ControlMaster=no -o PreferredAuthentications=keyboard-interactive,publickey" \
  "${SRC}/" \
  "${REMOTE}:${DEST}/"

echo
echo "Done. Destination: ${REMOTE}:${DEST}"
echo "  history_restart_files/  0021 AD r/h0, 1101 finalspin r/h0, clm_params"
echo "  domain_surfdata/        TESNorthERA510PCT domain + NLCD surfdata"
echo "  AIrestart/              AI-updated 10% elm.r.0021"
