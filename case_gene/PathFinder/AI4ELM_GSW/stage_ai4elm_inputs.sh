#!/usr/bin/env bash
# Pull AI4ELM custom NetCDFs (+ optional GSWP3 1901-1920) from Frontier onto Pathfinder.
# Run on Pathfinder (pflogin). You will be prompted for OLCF SSH + RSA once.
#
#   MODE=smoke|spinup   (default: spinup)
#   DRY_RUN=1
#
# Examples:
#   MODE=smoke  bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh
#   MODE=spinup bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh
set -euo pipefail

SRC_HOST="${SRC_HOST:-frontier.olcf.ornl.gov}"
SRC_USER="${SRC_USER:-wangd}"
SRC_CUSTOM="${SRC_CUSTOM:-/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup}"
SRC_DIN="${SRC_DIN:-/lustre/orion/cli115/world-shared/e3sm/inputdata}"
SRC_GSWP="${SRC_GSWP:-${SRC_DIN}/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516}"

DEST_CUSTOM="${DEST_CUSTOM:-/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup}"
DEST_DIN="${DEST_DIN:-/projects/hpcl-cli185/world-shared/e3sm/inputdata}"
DEST_GSWP="${DEST_GSWP:-${DEST_DIN}/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516}"
MODE="${MODE:-spinup}"
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

echo "MODE:        ${MODE}"
echo "SRC:         ${REMOTE}"
echo "DEST_CUSTOM: ${DEST_CUSTOM}"
echo "DEST_GSWP:   ${DEST_GSWP}"

if [[ "${DRY_RUN}" != "1" ]]; then
  CTRL_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai4elm-ssh.XXXXXX")"
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

echo
echo "==== 1. Five custom NetCDFs ===="
run mkdir -p "${DEST_CUSTOM}"
run "${RSYNC[@]}" \
  "${REMOTE}:${SRC_CUSTOM}/surfdata_0.5x0.5_50pfts_20250528.nc" \
  "${REMOTE}:${SRC_CUSTOM}/clm_params_c251006.nc" \
  "${REMOTE}:${SRC_CUSTOM}/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc" \
  "${REMOTE}:${SRC_CUSTOM}/MOSART_Global_half_20250523.nc" \
  "${REMOTE}:${SRC_CUSTOM}/global_reservoir_halfdegree_c20200917.nc" \
  "${DEST_CUSTOM}/"

echo
echo "==== 2. DATM domain ne30pg2_Icos ===="
run mkdir -p "${DEST_DIN}/share/domains"
run "${RSYNC[@]}" \
  "${REMOTE}:${SRC_DIN}/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc" \
  "${DEST_DIN}/share/domains/"

if [[ "${MODE}" == "smoke" || "${MODE}" == "spinup" ]]; then
  echo
  echo "==== 3. GSWP3 domain + 1901-1920 monthly streams ===="
  run mkdir -p "${DEST_GSWP}"/{Solar,Precip,TPHWL}
  run "${RSYNC[@]}" \
    "${REMOTE}:${SRC_GSWP}/domain.lnd.360x720_gswp3.0v1.c170606.nc" \
    "${DEST_GSWP}/"

  # Only the AD cycle years (240 months x 3 streams).
  FILTER=(--include='*/')
  for y in $(seq 1901 1920); do
    FILTER+=(--include="clmforc.GSWP3.c2011.0.5x0.5.Solr.${y}-??.nc")
    FILTER+=(--include="clmforc.GSWP3.c2011.0.5x0.5.Prec.${y}-??.nc")
    FILTER+=(--include="clmforc.GSWP3.c2011.0.5x0.5.TPQWL.${y}-??.nc")
  done
  FILTER+=(--exclude='*')

  for stream in Solar Precip TPHWL; do
    echo "--- ${stream} ---"
    run "${RSYNC[@]}" "${FILTER[@]}" \
      "${REMOTE}:${SRC_GSWP}/${stream}/" \
      "${DEST_GSWP}/${stream}/"
  done
fi

echo
echo "==== 4. Local verify (1901-1920) ===="
if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN: skip verify"
else
  python3 - <<PY
from pathlib import Path
g = Path("${DEST_GSWP}")
expect = {f"{y:04d}-{m:02d}" for y in range(1901, 1921) for m in range(1, 13)}
ok = True
for label, tag, sub in [
    ("Solar", "Solr", "Solar"),
    ("Precip", "Prec", "Precip"),
    ("TPHWL", "TPQWL", "TPHWL"),
]:
    d = g / sub
    have = set()
    if d.is_dir():
        for p in d.glob(f"clmforc.GSWP3.c2011.0.5x0.5.{tag}.????-??.nc"):
            ym = p.name.split(".")[-2]
            y = int(ym.split("-")[0])
            if 1901 <= y <= 1920:
                have.add(ym)
    miss = sorted(expect - have)
    print(f"{label}: {len(have)}/240 present; missing={len(miss)}")
    if miss:
        ok = False
        print("  first/last miss:", miss[0], miss[-1])
customs = Path("${DEST_CUSTOM}")
for name in [
    "surfdata_0.5x0.5_50pfts_20250528.nc",
    "clm_params_c251006.nc",
    "ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc",
    "MOSART_Global_half_20250523.nc",
    "global_reservoir_halfdegree_c20200917.nc",
]:
    p = customs / name
    print(("OK  " if p.is_file() else "MISS") + f" {p}")
    if not p.is_file():
        ok = False
dom = Path("${DEST_DIN}/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc")
print(("OK  " if dom.is_file() else "MISS") + f" {dom}")
if not dom.is_file():
    ok = False
raise SystemExit(0 if ok else 1)
PY
fi

echo
echo "Done. Create smoke case:"
echo "  bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke.sh"
