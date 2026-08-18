#!/bin/bash
# Smoke: two cheap e3sm_land_developer cases on DEV_BRANCH (no -g/-c).
# Confirms Frontier overlay + bug-fix branch build/run before the full suite.
#
#   setsid nohup ./e3sm_land_developer_smoke.sh \
#     > ../docs/e3sm_land_developer_smoke.nohup.log 2>&1 < /dev/null &

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=e3sm_land_developer.conf.sh
source "${SCRIPT_DIR}/e3sm_land_developer.conf.sh"

mkdir -p "${LOG_DIR}"

cd "${E3SMROOT}"
reset_local_frontier_overlay
echo "Checking out ${DEV_BRANCH}..."
git checkout "${DEV_BRANCH}"
git submodule update --init
DEV_ID="$(git rev-parse --short=10 HEAD)"
TEST_ID="smoke${DEV_ID}"
echo "HEAD: $(git log -1 --format='%h %s')"
echo "TEST_ID (-t): ${TEST_ID}"

LOG="${LOG_DIR}/e3sm_land_developer_smoke_${DEV_ID}.log"

echo "==== e3sm_land_developer SMOKE (bug-fix branch, 2 cases, no gold) ===="
echo "E3SMROOT:        ${E3SMROOT}"
echo "DEV_BRANCH:      ${DEV_BRANCH}"
echo "TEST_ID:         ${TEST_ID}"
echo "TESTS:           ${SMOKE_TESTS[*]}"
echo "LOG:             ${LOG}"
echo "SCRATCH:         ${SCRATCH_ROOT}"
echo "cs.status:       ${SCRATCH_ROOT}/cs.status.${TEST_ID}"
echo

load_python
apply_frontier_lmod_workaround

cd "${E3SMROOT}/cime/scripts"
exec > >(tee -a "${LOG}") 2>&1

./create_test "${SMOKE_TESTS[@]}" \
  --machine "${MACHINE}" \
  --compiler "${COMPILER}" \
  -t "${TEST_ID}" \
  -p "${PROJECT}" \
  --walltime "${SMOKE_WALLTIME}" \
  --mail-user "${MAIL_USER}" \
  --mail-type fail \
  -v -j 2

echo
echo "create_test smoke submitted/finished."
echo "Monitor: ${SCRATCH_ROOT}/cs.status.${TEST_ID}"
echo "Expect RUN PASS on both cases before restarting full generate."
