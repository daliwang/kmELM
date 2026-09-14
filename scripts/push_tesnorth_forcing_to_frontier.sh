#!/bin/bash
# Push TES_NORTH 3-hourly monthly forcing from Pathfinder to Frontier Orion.
#
# Run in an interactive Pathfinder terminal or tmux. You will enter the OLCF
# RSA passcode once, at the start of rsync. Do not use BACKGROUND=1 unless a
# ControlMaster slave to the same host already works (DTN often refuses mux).
#
#   tmux
#   cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
#   DEST_HOST=dtn101.ccs.ornl.gov bash scripts/push_tesnorth_forcing_to_frontier.sh
#
# Pin a single DTN (dtn101/dtn102/...). Do not use dtn.olcf.ornl.gov: it is a
# load balancer, host keys rotate, and SSH mux from Frontier will not attach.

set -euo pipefail

SRC_FORC="${SRC_FORC:-/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain/forcing}"
DEST_HOST="${DEST_HOST:-dtn101.ccs.ornl.gov}"
DEST_USER="${DEST_USER:-wangd}"
DEST_FORC="${DEST_FORC:-/lustre/orion/cli115/world-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain/forcing}"
MODE="${MODE:-spinup}"
DRY_RUN="${DRY_RUN:-0}"
BACKGROUND="${BACKGROUND:-0}"
LOG_DIR="${LOG_DIR:-/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain/scripts}"
LOG="${LOG:-${LOG_DIR}/push_tesnorth_forcing_frontier.${MODE}.$(date +%Y%m%d-%H%M%S).log}"

if [[ "${DEST_HOST}" == "dtn.olcf.ornl.gov" || "${DEST_HOST}" == "frontier.olcf.ornl.gov" ]]; then
  echo "ERROR: ${DEST_HOST} is a load balancer / login pool." >&2
  echo "Use a single DTN, e.g. DEST_HOST=dtn101.ccs.ornl.gov" >&2
  exit 1
fi

REMOTE="${DEST_USER}@${DEST_HOST}"
CTRL_DIR="${CTRL_DIR:-${HOME}/.ssh/cm-tesnorth-push}"
# One socket per destination so a Frontier mux is never reused for a DTN.
CTRL_PATH="${CTRL_DIR}/cm-${DEST_HOST}"
RSH="${CTRL_DIR}/rsh-${DEST_HOST}.sh"

case "${MODE}" in
  test)
    YEARS=(1980)
    MONTH_GLOB='1980-01'
    EXPECT_NC=3
    NOTE='~1.8 GiB (1980-01 only)'
    ;;
  spinup)
    YEARS=($(seq 1980 1999))
    MONTH_GLOB=''
    EXPECT_NC=720
    NOTE='~400 GiB (1980-1999 spinup)'
    ;;
  full)
    YEARS=($(seq 1980 2023))
    MONTH_GLOB=''
    EXPECT_NC=1584
    NOTE='~878 GiB (1980-2023)'
    ;;
  *)
    echo "ERROR: MODE must be test, spinup, or full (got '${MODE}')" >&2
    exit 1
    ;;
esac

echo "MODE:     ${MODE}  (${NOTE}; expect ${EXPECT_NC} files)"
echo "SRC:      ${SRC_FORC}"
echo "DEST:     ${REMOTE}:${DEST_FORC}"
echo "LOG:      ${LOG}"
echo

if [[ ! -d "${SRC_FORC}/Precip3Hrly" ]]; then
  echo "ERROR: source forcing missing: ${SRC_FORC}" >&2
  exit 1
fi

FILTER=(--include='*/')
if [[ -n "${MONTH_GLOB}" ]]; then
  FILTER+=(--include="*.${MONTH_GLOB}.nc")
else
  for y in "${YEARS[@]}"; do
    FILTER+=(--include="*.${y}-??.nc")
  done
fi
FILTER+=(--exclude='*')

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN: rsync ... ${SRC_FORC}/ ${REMOTE}:${DEST_FORC}/"
  exit 0
fi

mkdir -p "${CTRL_DIR}" "${LOG_DIR}"
cat > "${RSH}" <<EOF
#!/bin/bash
exec ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=12 \\
  -o PreferredAuthentications=keyboard-interactive,publickey \\
  "\$@"
EOF
chmod +x "${RSH}"

# Optional mux: only used if a slave to THIS host works without a passcode.
USE_MUX=0
if [[ -S "${CTRL_PATH}" ]] && ssh -o ControlPath="${CTRL_PATH}" -O check "${REMOTE}" >/dev/null 2>&1; then
  if ssh -o ControlPath="${CTRL_PATH}" -o ControlMaster=no -o BatchMode=yes \
       "${REMOTE}" true >/dev/null 2>&1; then
    USE_MUX=1
    echo "Reusing ControlMaster ${CTRL_PATH}"
    cat > "${RSH}" <<EOF
#!/bin/bash
exec ssh -o ControlPath="${CTRL_PATH}" -o ControlMaster=no \\
  -o ServerAliveInterval=60 "\$@"
EOF
    chmod +x "${RSH}"
  else
    echo "Stale or unusable mux for ${REMOTE}; ignoring ${CTRL_PATH}"
    ssh -o ControlPath="${CTRL_PATH}" -O exit "${REMOTE}" >/dev/null 2>&1 || true
    rm -f "${CTRL_PATH}"
  fi
fi

if [[ "${BACKGROUND}" == "1" && "${USE_MUX}" != "1" ]]; then
  echo "ERROR: BACKGROUND=1 needs a working SSH mux, and DTN usually will not" >&2
  echo "multiplex. Run in tmux in the foreground instead:" >&2
  echo "  tmux" >&2
  echo "  DEST_HOST=${DEST_HOST} bash $0" >&2
  exit 1
fi

RSYNC=(rsync -a --info=stats1,progress2 --partial --append-verify -e "${RSH}")

echo
echo "==== rsync ${MODE} forcing ===="
echo "Started $(date -Iseconds). Enter RSA once if ssh asks. Re-run to resume."
echo

if [[ "${BACKGROUND}" == "1" ]]; then
  nohup "${RSYNC[@]}" "${FILTER[@]}" \
    "${SRC_FORC}/" \
    "${REMOTE}:${DEST_FORC}/" >> "${LOG}" 2>&1 &
  echo $! > "${LOG}.pid"
  echo "rsync PID $(cat "${LOG}.pid")  log: ${LOG}"
  exit 0
fi

"${RSYNC[@]}" "${FILTER[@]}" \
  "${SRC_FORC}/" \
  "${REMOTE}:${DEST_FORC}/" | tee -a "${LOG}"

echo
n=$(ssh -o ServerAliveInterval=60 "${REMOTE}" \
  "find '${DEST_FORC}' -type f -name 'climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.*.nc' | wc -l")
echo "remote monthly files: ${n} (expect ${EXPECT_NC} for MODE=${MODE})"
echo "Done $(date -Iseconds). Destination: ${REMOTE}:${DEST_FORC}"
