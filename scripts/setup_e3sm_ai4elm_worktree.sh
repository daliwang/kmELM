#!/usr/bin/env bash
# Pin the AI4ELM GSWP3 TOP/crop science commit in a sibling E3SM tree so
# kmELM/E3SM (TES) and E3SM-era5 (ERAf09) are not disturbed.
#
# Usage (from the kmELM toplevel, on Frontier or Pathfinder):
#   bash scripts/setup_e3sm_ai4elm_worktree.sh
#
# Optional:
#   OVERLAY_PATHFINDER=1   # default on Pathfinder hosts; insert pathfinder
#                          # machine files (pin lacks them)
#   DONOR_REF=origin/lnd/clm_glacier_fixes_era5
#
# Result:
#   E3SM-ai4elm/   ai4elm-spinup-pin @ 48d8ff20cc
set -euo pipefail

KMELM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E3SM_MAIN="${KMELM_ROOT}/E3SM"
E3SM_AI4="${KMELM_ROOT}/E3SM-ai4elm"
PIN_SHA="${PIN_SHA:-48d8ff20ccb32d6cddcb2fcd6d83fddaf03ee53a}"
BRANCH_NAME="${BRANCH_NAME:-ai4elm-spinup-pin}"
DONOR_REF="${DONOR_REF:-origin/lnd/clm_glacier_fixes_era5}"

HOST="$(hostname -s 2>/dev/null || hostname 2>/dev/null || true)"
if [[ -z "${OVERLAY_PATHFINDER:-}" ]]; then
  if [[ "${HOST}" == *pathfinder* || "${HOST}" == pf* || "${HOST}" == *pflogin* ]]; then
    OVERLAY_PATHFINDER=1
  else
    OVERLAY_PATHFINDER=0
  fi
fi

if [[ ! -d "${E3SM_MAIN}/.git" && ! -f "${E3SM_MAIN}/.git" ]]; then
  echo "ERROR: E3SM submodule not found at ${E3SM_MAIN}" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

if [[ -d "${E3SM_AI4}" ]]; then
  echo "E3SM-ai4elm already exists: $(git -C "${E3SM_AI4}" rev-parse --short HEAD) ($(git -C "${E3SM_AI4}" rev-parse --abbrev-ref HEAD))"
else
  echo "Fetching pin ${PIN_SHA}"
  git -C "${E3SM_MAIN}" fetch upstream "${PIN_SHA}" 2>/dev/null \
    || git -C "${E3SM_MAIN}" fetch origin "${PIN_SHA}"
  git -C "${E3SM_MAIN}" branch -f "${BRANCH_NAME}" "${PIN_SHA}"
  echo "Creating worktree ${E3SM_AI4} on ${BRANCH_NAME}"
  git -C "${E3SM_MAIN}" worktree add "${E3SM_AI4}" "${BRANCH_NAME}"
fi

HEAD="$(git -C "${E3SM_AI4}" rev-parse HEAD)"
if [[ "${HEAD}" != "${PIN_SHA}" ]]; then
  echo "WARNING: E3SM-ai4elm HEAD is ${HEAD}, expected ${PIN_SHA}" >&2
fi

echo "Initializing CIME / MCT / SCORPIO / FATES / sbetr (local object cache: E3SM/)"
git -C "${E3SM_AI4}" submodule update --init --reference "${E3SM_MAIN}" \
  cime \
  externals/mct \
  externals/scorpio \
  externals/scorpio_classic \
  components/elm/src/external_models/fates \
  components/elm/src/external_models/sbetr
if [[ -d "${E3SM_AI4}/cime/.git" || -f "${E3SM_AI4}/cime/.git" ]]; then
  git -C "${E3SM_AI4}/cime" submodule update --init --recursive \
    --reference "${E3SM_MAIN}/cime" 2>/dev/null \
    || git -C "${E3SM_AI4}/cime" submodule update --init --recursive
fi

overlay_pathfinder_machines() {
  local dest="$1"
  echo "Overlaying Pathfinder machine files from ${DONOR_REF} into ${dest}"
  git -C "${E3SM_MAIN}" fetch origin lnd/clm_glacier_fixes_era5 2>/dev/null || true

  mkdir -p "${dest}/cime_config/machines/cmake_macros"
  git -C "${E3SM_MAIN}" show "${DONOR_REF}:cime_config/machines/cmake_macros/pathfinder_gnu.cmake" \
    > "${dest}/cime_config/machines/cmake_macros/pathfinder_gnu.cmake"

  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/ai4elm-pf.XXXXXX")"
  git -C "${E3SM_MAIN}" show "${DONOR_REF}:cime_config/machines/config_machines.xml" \
    > "${tmp}/donor_machines.xml"
  git -C "${E3SM_MAIN}" show "${DONOR_REF}:cime_config/machines/config_batch.xml" \
    > "${tmp}/donor_batch.xml"

  python3 - "${tmp}" "${dest}" <<'PY'
import re, sys
from pathlib import Path
tmpdir, dest = Path(sys.argv[1]), Path(sys.argv[2])

def extract(text, pattern, label):
    m = re.search(pattern, text, re.S)
    if not m:
        raise SystemExit(f"ERROR: missing {label} in donor")
    return m.group(1)

def upsert(path, block, marker, close_tag):
    text = path.read_text()
    if re.search(marker, text):
        print(f"  {path.name}: already has pathfinder — leaving as-is")
        return
    m = re.search(rf"(</{close_tag}>\s*)\Z", text)
    if not m:
        raise SystemExit(f"ERROR: cannot find </{close_tag}> in {path}")
    path.write_text(text[: m.start()] + block + text[m.start() :])
    print(f"  {path.name}: inserted pathfinder block")

d_mach = (tmpdir / "donor_machines.xml").read_text()
d_batch = (tmpdir / "donor_batch.xml").read_text()
mach = extract(
    d_mach,
    r'(  <machine MACH="pathfinder">.*?</machine>\s*)',
    "pathfinder machine",
)
batch = extract(
    d_batch,
    r'(   <batch_system MACH="pathfinder".*?</batch_system>\s*)',
    "pathfinder batch",
)
upsert(dest / "cime_config/machines/config_machines.xml", mach, r'MACH="pathfinder"', "config_machines")
upsert(dest / "cime_config/machines/config_batch.xml", batch, r'MACH="pathfinder"', "config_batch")
PY
  rm -rf "${tmp}"

  if ! grep -q 'MACH="pathfinder"' "${dest}/cime_config/machines/config_machines.xml"; then
    echo "ERROR: Pathfinder overlay failed" >&2
    exit 1
  fi
  echo "Pathfinder machine overlay OK (local dirty files in E3SM-ai4elm — do not push upstream)."
}

if [[ "${OVERLAY_PATHFINDER}" == "1" ]]; then
  if grep -q 'MACH="pathfinder"' "${E3SM_AI4}/cime_config/machines/config_machines.xml" 2>/dev/null; then
    echo "Pathfinder already present in E3SM-ai4elm machines — skip overlay"
  else
    overlay_pathfinder_machines "${E3SM_AI4}"
  fi
else
  echo "OVERLAY_PATHFINDER=0 (Frontier). On Pathfinder re-run with OVERLAY_PATHFINDER=1."
fi

echo
echo "E3SM-ai4elm: $(git -C "${E3SM_AI4}" rev-parse --abbrev-ref HEAD) @ $(git -C "${E3SM_AI4}" rev-parse --short HEAD)"
echo "E3SM/:       $(git -C "${E3SM_MAIN}" rev-parse --abbrev-ref HEAD) @ $(git -C "${E3SM_MAIN}" rev-parse --short HEAD)"
echo
echo "Next on Pathfinder:"
echo "  bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh"
echo "  bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke.sh"
echo "See case_gene/PathFinder/AI4ELM_GSW/README.md"
