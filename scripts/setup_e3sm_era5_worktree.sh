#!/usr/bin/env bash
# Pin the ERA5 science branch in a sibling E3SM tree so kmELM/E3SM can
# track a different experiment (TES_NORTH / TESSFA_4km, master, …).
#
# Usage (from the kmELM toplevel):
#   bash scripts/setup_e3sm_era5_worktree.sh
#
# Result:
#   E3SM-era5/   lnd/clm_glacier_fixes_era5   (ERAf09 / I1850ERACNPRDCTCBC)
#   E3SM/        free for other branches
set -euo pipefail

KMELM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E3SM_MAIN="${KMELM_ROOT}/E3SM"
E3SM_ERA5="${KMELM_ROOT}/E3SM-era5"
ERA5_BRANCH="${ERA5_BRANCH:-lnd/clm_glacier_fixes_era5}"

if [[ ! -d "${E3SM_MAIN}/.git" && ! -f "${E3SM_MAIN}/.git" ]]; then
  echo "ERROR: E3SM submodule not found at ${E3SM_MAIN}" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

if [[ -d "${E3SM_ERA5}" ]]; then
  current="$(git -C "${E3SM_ERA5}" rev-parse --abbrev-ref HEAD)"
  sha="$(git -C "${E3SM_ERA5}" rev-parse --short HEAD)"
  echo "E3SM-era5 already exists: ${current} @ ${sha}"
  if [[ "${current}" != "${ERA5_BRANCH}" ]]; then
    echo "WARNING: expected branch ${ERA5_BRANCH}" >&2
  fi
else
  echo "Creating worktree ${E3SM_ERA5} on ${ERA5_BRANCH}"
  git -C "${E3SM_MAIN}" fetch origin "${ERA5_BRANCH}"
  # A branch can live in only one worktree. Detach E3SM/ first if it holds it.
  main_branch="$(git -C "${E3SM_MAIN}" rev-parse --abbrev-ref HEAD)"
  if [[ "${main_branch}" == "${ERA5_BRANCH}" ]]; then
    echo "Detaching ${E3SM_MAIN} so ${ERA5_BRANCH} can move to E3SM-era5"
    git -C "${E3SM_MAIN}" checkout --detach HEAD
  fi
  git -C "${E3SM_MAIN}" worktree add "${E3SM_ERA5}" "${ERA5_BRANCH}"
fi

# Land-only I1850ERACNPRDCTCBC needs CIME + MCT + PIO. Do not recurse into
# unused EAM/MPAS/sBETR third-party trees (HDF5 clones hang on this network).
echo "Initializing CIME / MCT / SCORPIO in E3SM-era5 (local object cache: E3SM/)"
git -C "${E3SM_ERA5}" submodule update --init --reference "${E3SM_MAIN}" \
  cime \
  externals/mct \
  externals/scorpio \
  externals/scorpio_classic
if [[ -d "${E3SM_ERA5}/cime/.git" || -f "${E3SM_ERA5}/cime/.git" ]]; then
  git -C "${E3SM_ERA5}/cime" submodule update --init --recursive \
    --reference "${E3SM_MAIN}/cime"
fi

echo
echo "E3SM-era5: $(git -C "${E3SM_ERA5}" rev-parse --abbrev-ref HEAD) @ $(git -C "${E3SM_ERA5}" rev-parse --short HEAD)"
echo "E3SM/:     $(git -C "${E3SM_MAIN}" rev-parse --abbrev-ref HEAD) @ $(git -C "${E3SM_MAIN}" rev-parse --short HEAD)"
echo
echo "ERA5 f09 create scripts use E3SM-era5 by default."
echo "TES_NORTH / other experiments: checkout the branch you need in E3SM/, e.g."
echo "  git -C ${E3SM_MAIN} checkout TESSFA_4km"
echo "See docs/e3sm_source_trees.md"
