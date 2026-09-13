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

## Source trees (do not share one E3SM checkout)

ERA5 f09 (`I1850ERACNPRDCTCBC` / `ERAf09`) and TES_NORTH (`uELM_TES` / 4 km) need
**different E3SM branches**. On Pathfinder:

| Tree | Branch | Use |
|---|---|---|
| `E3SM-era5/` | `lnd/clm_glacier_fixes_era5` | ERA5 f09 spinup |
| `E3SM/` | `TESSFA_4km`, `master`, … | TES_NORTH and other experiments |

```bash
bash scripts/setup_e3sm_era5_worktree.sh
```

Layout, what not to mix, and Frontier `E3SM-master-pr`:
[`docs/e3sm_source_trees.md`](docs/e3sm_source_trees.md).

## Build and Run

### ERA5 f09 (`I1850ERACNPRDCTCBC`)

Frontier AD + final spinup (completed) and Pathfinder port:
[`docs/I1850ERACNPRDCTCBC_f09_era5_spinup_process.md`](docs/I1850ERACNPRDCTCBC_f09_era5_spinup_process.md).

Pathfinder create scripts: `case_gene/PathFinder/ERAf09/` (they use `E3SM-era5`).
Forcing stage: `case_gene/PathFinder/ERAf09/DATA.md`.

### TES_NORTH (4 km)

Different experiment. Scripts: `case_gene/PathFinder/TES_NORTHERA5/`.
Use the `E3SM/` tree, not `E3SM-era5`. Notes:
[`case_gene/PathFinder/TES_NORTHERA5/README.md`](case_gene/PathFinder/TES_NORTHERA5/README.md).

## E3SM land developer testing (Frontier)

Full procedure: [`docs/e3sm_land_developer_testing_procedure.md`](docs/e3sm_land_developer_testing_procedure.md).  
Results (campaign 1 complete; campaign 2 in progress): [`docs/e3sm_land_developer_testing_results.md`](docs/e3sm_land_developer_testing_results.md).

`create_test` compiles on the login node and submits Slurm jobs for the runs. Launch the driver with `setsid nohup` so logout does not kill compile/submit. Do not wrap the whole suite in one `sbatch` script. On `maint-3.0`, generate/compare apply a local overlay (`craygnu` + Lmod wrapper); do not commit those E3SM files to the science branch. Overlay, what is mergeable, and whether to open a **separate machines PR**: [`docs/frontier_maint-3.0_testing_overlay.md`](docs/frontier_maint-3.0_testing_overlay.md).

Active campaign (2026-09-03) is **master** gold `34fb1e111e` vs branch `lnd/port-clm-cryosphere-fixes-master2`. Settings: `scripts/e3sm_land_developer.conf.sh`. Tree: `E3SM-master-pr`. Do not open the master PR until this campaign finishes. Older gold `baselines/a899004464/` and `baselines/34bd782d18/` is kept and not reused.

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM/scripts

# Step 1: generate gold files from current master
setsid nohup ./e3sm_land_developer_generate.sh \
  > ../docs/e3sm_land_developer_generate_34fb1e111e.nohup.log 2>&1 < /dev/null &

# Wait until generate jobs finish (queue empty and cs.status is clean), then:
# Step 2: compare the master development branch
setsid nohup ./e3sm_land_developer_compare.sh \
  > ../docs/e3sm_land_developer_compare_0b5f3c01b8.nohup.log 2>&1 < /dev/null &
```

Monitor:

```bash
tail -f /lustre/orion/cli115/world-shared/wangd/kmELM/docs/e3sm_land_developer_generate_34fb1e111e.nohup.log
module load cray-python/3.11.7
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.34fb1e111e   # generate (current master)
# /lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.0b5f3c01b8   # compare (after generate)
```
