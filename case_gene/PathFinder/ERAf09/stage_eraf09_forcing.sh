#!/bin/bash
set -euo pipefail

# Pull ERA5_6hr_f09 forcing from Frontier/Orion onto this Pathfinder node.
# Run on Pathfinder (pflogin). SSH user is wangd@frontier.olcf.ornl.gov.
# You will be prompted for OLCF SSH + RSA once; later rsyncs reuse that connection.
#
#   MODE=smoke|spinup|full  (default: spinup)
#   WITH_STOCK=1            also pull ~1.4 GB stock ELM/MOSART/mapping files
#   DRY_RUN=1               print commands only
#
# Examples (on Pathfinder):
#   cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
#   MODE=smoke bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh
#   MODE=spinup bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh
#   MODE=spinup WITH_STOCK=1 bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh

SRC_HOST="${SRC_HOST:-frontier.olcf.ornl.gov}"
# Pathfinder login user is not the Frontier account (7xw vs wangd).
SRC_USER="${SRC_USER:-wangd}"
SRC_FORC="${SRC_FORC:-/lustre/orion/cli115/world-shared/wangd/kiloCraft/ERA5_6hr_f09}"
SRC_DIN="${SRC_DIN:-/lustre/orion/cli115/world-shared/e3sm/inputdata}"
DEST_FORC="${DEST_FORC:-/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/ERA5_6hr_f09}"
DEST_DIN="${DEST_DIN:-/projects/hpcl-cli185/world-shared/e3sm/inputdata}"
MODE="${MODE:-spinup}"
WITH_STOCK="${WITH_STOCK:-0}"
DRY_RUN="${DRY_RUN:-0}"

REMOTE="${SRC_USER}@${SRC_HOST}"
CTRL_DIR=""
SSH_MUX=()

cleanup() {
  if [[ -n "${CTRL_DIR}" && -S "${CTRL_DIR}/cm" ]]; then
    ssh -o ControlPath="${CTRL_DIR}/cm" -O exit "${REMOTE}" >/dev/null 2>&1 || true
    rm -rf "${CTRL_DIR}"
  fi
}
trap cleanup EXIT

run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf 'DRY_RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

case "${MODE}" in
  smoke)  YEARS=($(seq 1980 1980)); EXPECT_NC=108;  EXPECT_NOTE="~3 GB (1980 only)" ;;
  spinup) YEARS=($(seq 1980 1999)); EXPECT_NC=2160; EXPECT_NOTE="~58 GB (1980-1999)" ;;
  full)   YEARS=($(seq 1979 2022)); EXPECT_NC=4752; EXPECT_NOTE="~126 GB (1979-2022)" ;;
  *)
    echo "ERROR: MODE must be smoke, spinup, or full (got '${MODE}')" >&2
    exit 1
    ;;
esac

echo "MODE:        ${MODE}  (${EXPECT_NOTE}; expect ${EXPECT_NC} monthly files)"
echo "SRC:         ${REMOTE}:${SRC_FORC}"
echo "DEST_FORC:   ${DEST_FORC}"
echo "WITH_STOCK:  ${WITH_STOCK}"
echo "DEST_DIN:    ${DEST_DIN}"

if [[ "${DRY_RUN}" != "1" ]]; then
  CTRL_DIR="$(mktemp -d "${TMPDIR:-/tmp}/eraf09-ssh.XXXXXX")"
  echo
  echo "Opening SSH to ${REMOTE} (OLCF RSA). Later rsyncs reuse this session."
  ssh -MNf -o ControlMaster=yes -o ControlPath="${CTRL_DIR}/cm" \
    -o ControlPersist=4h "${REMOTE}"
  SSH_MUX=(-e "ssh -o ControlPath=${CTRL_DIR}/cm -o ControlMaster=no")
fi

RSYNC=(rsync -a --info=stats1,progress2 --partial --append-verify)
if [[ "${#SSH_MUX[@]}" -gt 0 ]]; then
  RSYNC+=("${SSH_MUX[@]}")
fi

FILTER=(--include='domain.lnd.fv0.9x1.25_gx1v6.090309.nc')
for y in "${YEARS[@]}"; do
  FILTER+=(--include="elmforc.ERA5.c2018.0.9x1.25.*.${y}-??.nc")
done
FILTER+=(--include='*/')
FILTER+=(--exclude='*')

echo
echo "==== 1. Pull ERA5_6hr_f09 forcing ===="
run mkdir -p "${DEST_FORC}"/{lwdn,pbot,prec,swdn,tbot,tdew,wind}

# --copy-links: Frontier domain file is a Lustre symlink; store a real netCDF here.
run "${RSYNC[@]}" --copy-links \
  "${FILTER[@]}" \
  "${REMOTE}:${SRC_FORC}/" \
  "${DEST_FORC}/"

echo
echo "==== 2. Verify local forcing ===="
if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN: find ${DEST_FORC} monthly files (expect ${EXPECT_NC}) and check domain"
else
  n=$(find "${DEST_FORC}" -name 'elmforc.ERA5.c2018.0.9x1.25.*.nc' | wc -l)
  d="${DEST_FORC}/domain.lnd.fv0.9x1.25_gx1v6.090309.nc"
  echo "local monthly files: ${n} (expect ${EXPECT_NC})"
  if [[ -f "${d}" && ! -L "${d}" ]]; then
    echo "domain: regular file OK (${d})"
  elif [[ -L "${d}" ]]; then
    echo "WARNING: domain is still a symlink: ${d} -> $(readlink "${d}")"
  else
    echo "WARNING: domain missing: ${d}"
  fi
fi

if [[ "${WITH_STOCK}" == "1" ]]; then
  echo
  echo "==== 3. Pull stock ELM / MOSART / mapping files (~1.4 GB) ===="
  STOCK=(
    share/domains/domain.lnd.fv0.9x1.25_gx1v6.090309.nc
    lnd/clm2/surfdata_map/surfdata_0.9x1.25_simyr1850_c180306.nc
    lnd/clm2/ndepdata/fndep_elm_cbgc_exp_simyr1849-2101_1.9x2.5_ssp245_c240903.nc
    lnd/clm2/pdepdata/fpdep_clm_hist_simyr2000_1.9x2.5_c150929.nc
    lnd/clm2/firedata/elmforc.Li_20181205_mod_hist_SSP2_CMIP6_hdm_0.5x0.5_AVHRR_simyr1850-2100_c240906.nc
    atm/datm7/NASA_LIS/clmforc.Li_2012_climo1995-2011.T62.lnfm_Total_c140423.nc
    lnd/clm2/snicardata/snicar_optics_5bnd_mam_c160322.nc
    lnd/clm2/snicardata/snicar_drdt_bst_fit_60_c070416.nc
    lnd/clm2/paramdata/clm_params_c211124.nc
    lnd/clm2/paramdata/CNP_parameters_c180529.nc
    rof/mosart/US_reservoir_8th_NLDAS3_c20161220_updated_20170314.nc
    rof/mosart/MOSART_global_half_20180721a.nc
    share/meshes/rof/SCRIPgrid_0.5x0.5_nomask_c110308.nc
    lnd/clm2/mappingdata/maps/0.9x1.25/map_0.9x1.25_nomask_to_0.5x0.5_nomask_aave_da_c120522.nc
    lnd/clm2/mappingdata/maps/0.9x1.25/map_0.5x0.5_nomask_to_0.9x1.25_nomask_aave_da_c121019.nc
  )
  LIST="$(mktemp "${TMPDIR:-/tmp}/eraf09-stock.XXXXXX")"
  printf '%s\n' "${STOCK[@]}" > "${LIST}"
  run mkdir -p "${DEST_DIN}"
  # One rsync so stock files share the same SSH mux as the forcing pull.
  run "${RSYNC[@]}" --files-from="${LIST}" \
    "${REMOTE}:${SRC_DIN}/" \
    "${DEST_DIN}/"
  rm -f "${LIST}"
  echo "If Pathfinder already has a full E3SM inputdata tree, skip WITH_STOCK=1"
  echo "and point DIN_LOC_ROOT at that tree instead."
fi

echo
echo "Done. DIN_LOC_ROOT_CLMFORC must be the parent of ERA5_6hr_f09:"
echo "  ${DEST_FORC%/*}"
echo "Smoke first (MODE=smoke), then spinup before submitting AD."
