# kmELM (Kilometer-scale E3SM Land Model)
## Overview
The kilometer-scale E3SM Land Model (ELM) is a high-resolution version of the land surface component of the Energy Exascale Earth System Model (E3SM), designed to capture fine-scale terrestrial processes such as hydrology, vegetation dynamics, and carbon-nutrient cycles with unprecedented spatial detail. By resolving sub-grid heterogeneity at the kilometer scale, ELM improves the representation of complex land-atmosphere interactions, such as topographically driven water redistribution, localized land use changes, and ecosystem responses to climate variability. This high-resolution modeling capability enables more accurate simulations of regional and global land surface processes, supporting applications in climate change assessment, extreme event prediction, and resource management.

## Supported Systems and Recommended Environments
### Frontier at ORNL


### Perlmutter at NERSC


### Baseline at ORNL



## Repo Configuration
```

git clone git@github.com:daliwang/kmELM.git
cd kmELM
export kmELM_home=$PWD
git submodule update --init --recursive
```

## Build and Run

## E3SM land developer testing (Frontier)

Full procedure: [`docs/e3sm_land_developer_testing_procedure.md`](docs/e3sm_land_developer_testing_procedure.md).

`create_test` compiles on the login node and submits Slurm jobs for the runs. Launch the driver with `nohup` so logout does not kill compile/submit. Do not wrap the whole suite in one `sbatch` script.

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM/scripts

# Step 1: generate gold files from parent master
nohup ./e3sm_land_developer_generate.sh > ../docs/e3sm_land_developer_generate.nohup.log 2>&1 &

# Wait until generate jobs finish (queue empty and cs.status is clean), then:
# Step 2: compare the development branch
nohup ./e3sm_land_developer_compare.sh > ../docs/e3sm_land_developer_compare.nohup.log 2>&1 &
```

Monitor:

```bash
tail -f /lustre/orion/cli115/world-shared/wangd/kmELM/docs/e3sm_land_developer_compare.nohup.log
module load cray-python/3.11.7
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.a899004464   # generate
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.fbfcc93f52   # compare
```
