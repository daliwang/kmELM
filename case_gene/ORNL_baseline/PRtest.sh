#!/bin/bash
set -x

export SCRATCH=/gpfs/wolf2/cades/cli185/proj-shared/wangd/PRtest

CIMEROOT=/gpfs/wolf2/cades/cli185/proj-shared/wangd/E3SM/cime/scripts
CASENAME=PR_kmelm_03312025
COMPILER=gnu
MACH=baseline
BASELINE=PR_kmelm_03312025
SUITE=e3sm_land_developer

$CIMEROOT/create_test -r $SCRATCH/$CASENAME \
  --output-root $SCRATCH/$CASENAME/output \
  --compiler $COMPILER -m $MACH \
  --baseline-root $SCRATCH/baselines/ \
  --wait \
  -b $BASELINE -g \
  $SUITE > PR_kmelm_03312025_04022025.log
