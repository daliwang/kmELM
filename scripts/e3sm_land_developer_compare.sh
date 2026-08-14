#!/bin/bash
# Step 2: compare DEV_BRANCH against baselines generated in step 1.
#
# Requires the same MY_BASELINE_DIR and BASELINE_NAME as generate.
# Launch with nohup on a login node (keeps compile/submit alive after logout):
#   nohup ./e3sm_land_developer_compare.sh > ../docs/e3sm_land_developer_compare.nohup.log 2>&1 &

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=e3sm_land_developer.conf.sh
source "${SCRIPT_DIR}/e3sm_land_developer.conf.sh"

mkdir -p "${LOG_DIR}"

cd "${E3SMROOT}"
echo "Checking out ${DEV_BRANCH}..."
git checkout "${DEV_BRANCH}"
git submodule update --init
DEV_ID="$(git rev-parse --short=10 HEAD)"
echo "HEAD: $(git log -1 --format='%h %s')"
echo "TEST_ID (-t): ${DEV_ID}"

LOG="${LOG_DIR}/e3sm_land_developer_compare_${DEV_ID}.log"

if [[ ! -d "${MY_BASELINE_DIR}/${BASELINE_NAME}" ]]; then
  echo "ERROR: baselines not found at ${MY_BASELINE_DIR}/${BASELINE_NAME}" >&2
  echo "Run e3sm_land_developer_generate.sh first and wait for it to finish." >&2
  exit 1
fi

echo "==== e3sm_land_developer COMPARE ===="
echo "E3SMROOT:        ${E3SMROOT}"
echo "MY_BASELINE_DIR: ${MY_BASELINE_DIR}"
echo "BASELINE_NAME:   ${BASELINE_NAME}  (-b, must match generate)"
echo "DEV_BRANCH:      ${DEV_BRANCH}"
echo "TEST_ID:         ${DEV_ID}         (-t, different from generate)"
echo "LOG:             ${LOG}"
echo "SCRATCH:         ${SCRATCH_ROOT}"
echo "cs.status:       ${SCRATCH_ROOT}/cs.status.${DEV_ID}"
echo

load_python

cd "${E3SMROOT}/cime/scripts"
exec > >(tee -a "${LOG}") 2>&1

./create_test "${SUITE}" \
  --machine "${MACHINE}" \
  --compiler "${COMPILER}" \
  --baseline-root "${MY_BASELINE_DIR}" \
  -b "${BASELINE_NAME}" \
  -t "${DEV_ID}" \
  -p "${PROJECT}" \
  --walltime "${WALLTIME}" \
  --mail-user "${MAIL_USER}" \
  --mail-type fail \
  -c -v -j "${CREATE_TEST_JOBS}"

echo
echo "create_test compare submitted/finished."
echo "Monitor: ${SCRATCH_ROOT}/cs.status.${DEV_ID}"
echo "Compared against: ${MY_BASELINE_DIR}/${BASELINE_NAME}/"
