#!/bin/bash
# Step 1: generate e3sm_land_developer baselines from parent master.
#
# Launch with nohup on a login node (keeps compile/submit alive after logout):
#   nohup ./e3sm_land_developer_generate.sh > ../docs/e3sm_land_developer_generate.nohup.log 2>&1 &
#
# Do not start compare until cs.status.${BASELINE_NAME} shows generate jobs finished.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=e3sm_land_developer.conf.sh
source "${SCRIPT_DIR}/e3sm_land_developer.conf.sh"

mkdir -p "${MY_BASELINE_DIR}" "${LOG_DIR}"
LOG="${LOG_DIR}/e3sm_land_developer_generate_${BASELINE_NAME}.log"

echo "==== e3sm_land_developer GENERATE ===="
echo "E3SMROOT:        ${E3SMROOT}"
echo "MY_BASELINE_DIR: ${MY_BASELINE_DIR}"
echo "BASELINE_NAME:   ${BASELINE_NAME}  (-b and -t)"
echo "LOG:             ${LOG}"
echo "SCRATCH:         ${SCRATCH_ROOT}"
echo "cs.status:       ${SCRATCH_ROOT}/cs.status.${BASELINE_NAME}"
echo

cd "${E3SMROOT}"
echo "Checking out ${BASELINE_NAME} (detached parent master)..."
git checkout "${BASELINE_NAME}"
git submodule update --init
echo "HEAD: $(git log -1 --format='%h %s')"

load_python

cd "${E3SMROOT}/cime/scripts"
exec > >(tee -a "${LOG}") 2>&1

./create_test "${SUITE}" \
  --machine "${MACHINE}" \
  --compiler "${COMPILER}" \
  --baseline-root "${MY_BASELINE_DIR}" \
  -b "${BASELINE_NAME}" \
  -t "${BASELINE_NAME}" \
  -p "${PROJECT}" \
  --walltime "${WALLTIME}" \
  --mail-user "${MAIL_USER}" \
  --mail-type fail \
  -g -v -j "${CREATE_TEST_JOBS}"

echo
echo "create_test generate submitted/finished."
echo "Monitor: ${SCRATCH_ROOT}/cs.status.${BASELINE_NAME}"
echo "Gold files: ${MY_BASELINE_DIR}/${BASELINE_NAME}/"
echo "Wait for generate jobs to complete before running e3sm_land_developer_compare.sh"
