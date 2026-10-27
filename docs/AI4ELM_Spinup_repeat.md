# Reproducing 20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup

Recorded 2026-10-19 from case XML, generated namelists, archived build provenance, executable checksums, run logs, and restart pointers. A fresh reproduction run was not performed.

## Purpose and status

This is an **1850 accelerated-decomposition ELM spin-up**, using GSWP3 atmospheric forcing and active MOSART river routing. The restart pointers reach **0166-01-01**, representing **165 model years** from 0001-01-01. Successful execution alone does not establish spin-up equilibrium.

Authoritative case directory:

```text
/pscratch/sd/j/jinyun/elm/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup
```

## Code base

Use the revision recorded when the executable was compiled:

| Item | Required value |
|---|---|
| Source checkout | `/pscratch/sd/j/jinyun/esm_10022026` |
| Branch | `jinyuntang/elm/fix-top-crop-compsets` |
| E3SM commit | `48d8ff20ccb32d6cddcb2fcd6d83fddaf03ee53a` |
| Git description | `bp_maint3.2-1009-g48d8ff20cc` |
| CIME commit | `bacb0a2c0601ca2bc0d08520d9eea12af55fe52f` |
| Case-local source overrides | None; `SourceMods` contains only README files |

The October 11 build provenance records no source patch. The October 11, October 13, and October 19 executable copies have identical SHA-256 checksums:

```text
703fe15d8359277521ddf2fcba55240b74cc96149c0515a05fd817e24f226113
```

Do not use the source directory's current HEAD as the historical version. At inspection it had advanced to `fffb27dca5a5c72c35b73bcc8eb09e538b515a88`. The archived build records identify the earlier commit above as the executable's source.

For a separate checkout on Perlmutter:

```bash
git clone --recurse-submodules \
  /pscratch/sd/j/jinyun/esm_10022026 E3SM-spinup
cd E3SM-spinup
git checkout 48d8ff20ccb32d6cddcb2fcd6d83fddaf03ee53a
git submodule update --init --recursive
```

The configured upstream is `git@github.com:E3SM-Project/E3SM.git`; availability of this custom commit on that remote was not verified. The local checkout is the verified source of the commit.

## Model configuration

| Setting | Configuration |
|---|---|
| Compset | `I1850GSWCNPRDCTCBCTOPPHSWFMCROP` |
| Resolution alias | `ne30pg2_r05_IcoswISC30E3r5` |
| Atmospheric grid | `ne30np4.pg2` |
| Land and river grids | Global 0.5 degrees; 720 × 360 |
| Components | DATM + ELM + MOSART; other physical components are stubs |
| Driver interface | `moab` |
| Calendar/start | `NO_LEAP`, `0001-01-01` |
| Initialization | Startup/cold start; ELM `finidat=' '` |
| Atmospheric forcing | GSWP3 v1, cycling 1901–1920, aligned to model year 1 |
| CO2 | Constant, 284.7 ppmv |
| Land timestep | 1,800 seconds |
| River coupling/timestep | 10,800 / 3,600 seconds |
| Restart output | Annually |
| Short-term archiving | Disabled, `DOUT_S=FALSE` |

Full compset longname:

```text
1850_DATM%GSWP3v1_ELM%CNPRDCTCBCTOPPHSWFMCROP_SICE_SOCN_MOSART_SGLC_SWAV_SIAC_SESP
```

ELM uses C–N–P biogeochemistry, relative-demand nutrient competition, CTC decomposition, methane, plant hydraulic stress, prognostic crops, irrigation including `tw_irr`, and TOP solar radiation. Exact `ELM_BLDNML_OPTS`:

```text
-bgc bgc -nutrient cnp -bgc_spinup on -nutrient_comp_pathway rd -soil_decomp ctc -methane -hydrstress -irrig .true. -tw_irr_on -crop -solar_rad_scheme top
```

The resolved namelist confirms:

```fortran
spinup_state = 1
suplnitro = 'NONE'
suplphos = 'NONE'
h2osfcflag = 0
create_crop_landunit = .true.
use_crop = .true.
firrig_data = .true.
check_finidat_fsurdat_consistency = .false.
check_finidat_year_consistency = .false.
hist_dov2xy = .true.,.true.
```

No transient land-use file is enabled. Nitrogen deposition is fixed to 1850; the phosphorus-deposition dataset is fixed to its year-2000 field. DATM uses prescribed 1850 aerosol climatology.

MOSART enables water management and inundation, with `data_bgc_fluxes_to_ocean_flag=.true.`. Its generated settings include `wrmflag=.true.`, `inundflag=.true.`, `opt_elevprof=1`, and `damconstructionflag=1`.

## Required input data

These exact custom files are referenced by the case. They must be accessible or copied with corresponding namelist-path changes.

| Purpose | File |
|---|---|
| Surface data | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/surfdata_0.5x0.5_50pfts_20250528.nc` |
| ELM parameters | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/clm_params_c251006.nc` |
| Nitrogen deposition | `/global/homes/j/jinyun/pscratch/cmip7/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc` |
| MOSART river network | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/MOSART_Global_half_20250523.nc` |
| Reservoir parameters | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/global_reservoir_halfdegree_c20200917.nc` |

Standard input data root:

```text
/global/cfs/cdirs/e3sm/inputdata
```

GSWP3 forcing directory relative to that root:

```text
atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516
```

Land domain:

```text
share/domains/domain.lnd.r05_IcoswISC30E3r5.231121.nc
```

DATM target domain:

```text
share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc
```

Preserve `Buildconf/*input_data_list`, `CaseDocs/datm.streams*`, and `CaseDocs/seq_maps.rc` to retain the auxiliary-data and mapping-file inventory. Input-file checksums were not computed during this review.

## Perlmutter build and execution

The case uses `pm-cpu`, compiler `intel`, MPI library `mpich`, and an optimized unthreaded build (`DEBUG=FALSE`, `BUILD_THREADED=FALSE`). ELM configuration options are `-phys elm -phys elm -cppdefs -DMODAL_AER`; PIO version is 2.

The parallel layout is **24 CPU nodes with 3,072 MPI ranks**, 128 ranks per node, one thread per rank. All component root ranks are zero. CPL, ATM, LND, ICE, OCN, ROF, GLC, and WAV each use 3,072 ranks; IAC and ESP each use one. The XML represents the former task counts as `-24`, meaning 24 nodes. The recorded launch uses:

```text
srun --label -n 3072 -N 24 -c 2 --cpu-bind=cores -m plane=128 .../bld/e3sm.exe
```

The case's recorded module environment includes:

```text
PrgEnv-intel/8.6.0
intel/2025.3
craype-accel-host
craype/2.7.35
cray-mpich/9.0.1
cray-hdf5-parallel/1.14.3.7
cray-netcdf-hdf5parallel/4.9.2.1
cray-parallel-netcdf/1.12.3.19
cmake/3.30.2
```

Preserve `env_mach_specific.xml`, `Macros.cmake`, `Depends*.cmake`, and the archived build environment. Module names alone do not capture the full build configuration. Build provenance is under the output directory's `bld`, especially:

```text
GIT_LOG.261011-184824
GIT_DIFF.261011-184824
GIT_SUBMODULE_STATUS.261011-184824
build_environment.261011-184824.txt
SourceMods.261011-184824.tar.gz
```

## Clean setup recipe

The following is a reproduction recipe, not a script executed during this review. Replace the source, new-case, and allocation placeholders. Preserve access to the original custom data, or update its paths in the copied namelists.

```bash
SRC=/absolute/path/to/E3SM-spinup
ORIGINAL=/pscratch/sd/j/jinyun/elm/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup
NEWCASE=/absolute/path/to/new-case
ACCOUNT=your_nersc_account

"$SRC/cime/scripts/create_newcase" \
  --case "$NEWCASE" \
  --compset I1850GSWCNPRDCTCBCTOPPHSWFMCROP \
  --res ne30pg2_r05_IcoswISC30E3r5 \
  --machine pm-cpu --compiler intel \
  --project "$ACCOUNT" --walltime 24:00:00

cd "$NEWCASE"
cp "$ORIGINAL"/user_nl_elm "$ORIGINAL"/user_nl_mosart \
   "$ORIGINAL"/user_nl_datm "$ORIGINAL"/user_nl_cpl .

./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -bgc_spinup on -nutrient_comp_pathway rd -soil_decomp ctc -methane -hydrstress -irrig .true. -tw_irr_on -crop -solar_rad_scheme top"

./xmlchange RUN_TYPE=startup,RUN_STARTDATE=0001-01-01,CONTINUE_RUN=FALSE
./xmlchange DATM_CLMNCEP_YR_ALIGN=1,DATM_CLMNCEP_YR_START=1901,DATM_CLMNCEP_YR_END=1920
./xmlchange ATM_NCPL=48,ROF_NCPL=8
./xmlchange STOP_OPTION=nyears,STOP_N=35,REST_OPTION=nyears,REST_N=1
./xmlchange RESUBMIT=0,DOUT_S=FALSE,SAVE_TIMING=FALSE
./xmlchange JOB_QUEUE=regular,JOB_WALLCLOCK_TIME=24:00:00

./case.setup
./preview_namelists
```

Before building, match the original parallel layout and machine environment described above. Compare generated namelists against the original `CaseDocs`, allowing for changed paths and the intentional cold-start versus continuation settings. Then:

```bash
./case.build
./case.submit
```

Subsequent segments require `CONTINUE_RUN=TRUE`. The 35-year segment length reflects the latest production configuration. Earlier attempts used other lengths and sometimes resumed from intermediate annual restarts. This cleaned recipe reproduces the scientific setup; it does not replay the historical sequence of interrupted jobs.

## Completed run and continuation

The latest successful segment, job `59910671`, ran from `0131-01-01` to `0166-01-01`, completing on October 18. It took approximately 22 hours, at 38.22 simulated years per day.

Output root:

```text
/pscratch/sd/j/jinyun/e3sm_scratch/pm-cpu/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup
```

The `bld` subdirectory holds executable/build records; `run` holds runtime output and restart pointers. For continuation, preserve the complete restart set, including ELM, MOSART, coupler, DATM NetCDF and DATM binary stream restarts, and all `rpointer.*` files. Current pointers reference `0166-01-01-00000`.

At inspection, current XML had `CONTINUE_RUN=TRUE`, `STOP_N=35`, `STOP_OPTION=nyears`, `RESUBMIT=1`, and `PROJECT=m2467`. These are continuation settings, distinct from the cold-start recipe above.

The existing `.submit_options` contains the malformed argument `account=m2467`, which caused automatic resubmission to fail after successful model execution. Configure the allocation through `PROJECT`; do not copy that saved argument. An earlier resubmission also failed because the original `e3sm` allocation lacked sufficient balance.

`replay.sh` contains failed commands and repeated experiments, including the incorrect `-spinup on` option before correction to `-bgc_spinup on`. Do not execute it as a reproduction script.

## Evidence files

Within the case directory:

- `README.case`: original creation command and compset/grid description.
- `env_case.xml`, `env_build.xml`, `env_run.xml`, `env_mach_pes.xml`, `env_workflow.xml`: case, build, scientific, parallel, and scheduler settings.
- `user_nl_elm`, `user_nl_mosart`, `user_nl_datm`, `user_nl_cpl`: user overrides.
- `CaseDocs/lnd_in`, `CaseDocs/datm_in`, `CaseDocs/mosart_in`: resolved component namelists.
- `CaseDocs/datm.streams*`, `CaseDocs/seq_maps.rc`, `Buildconf/*input_data_list`: forcing, mapping, and auxiliary-input inventory.
- `CaseStatus` and `run.20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.59910671`: execution success and resubmission failure.
- `timing/e3sm_timing.20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.59910671.261017-211949`: measured layout and performance.

The output directory's archived build records and runtime logs provide the executable provenance and restart chronology. Bit-for-bit equivalence of a newly built reproduction was not tested.

## Frontier port (OLCF)

A Frontier cold-start AD case was created without bit-for-bit intent (Perlmutter
`intel` / `pm-cpu` → Frontier `craygnu`). Science settings match this document;
machine, PE layout, and walltime are adapted for Frontier’s 2-hour queue limit
below 92 nodes.

| Item | Value |
|---|---|
| Source tree | `E3SM-ai4elm` @ `48d8ff20cc` (CIME `bacb0a2c`) |
| Create script | `case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh` |
| Case directory | `E3SM-ai4elm/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup` |
| Data staging guide | [`../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md`](../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md) |
| Layout | 3072 MPI ranks, 48 nodes × 64, `STOP_N=2` years, walltime `02:00:00` |

```bash
bash case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh
```

### Stage custom inputs and DATM domain (NERSC → Frontier)

Custom NetCDFs → `/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup/`.  
Domain → `/lustre/orion/cli115/world-shared/e3sm/inputdata/share/domains/`.

From Frontier (NERSC user `wangd`):

```bash
DEST_CUSTOM=/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup
DEST_DOMAIN=/lustre/orion/cli115/world-shared/e3sm/inputdata/share/domains
SRC=wangd@perlmutter.nersc.gov
mkdir -p "$DEST_CUSTOM"

rsync -avP --info=progress2 \
  "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/surfdata_0.5x0.5_50pfts_20250528.nc" \
  "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/clm_params_c251006.nc" \
  "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/MOSART_Global_half_20250523.nc" \
  "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/global_reservoir_halfdegree_c20200917.nc" \
  "$SRC:/global/homes/j/jinyun/pscratch/cmip7/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc" \
  "$DEST_CUSTOM/"

scp "$SRC:/global/cfs/cdirs/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc" \
  "$DEST_DOMAIN/"
```

Alternatively for the domain only via CIME (if the inputdata server is reachable):

```bash
cd E3SM-ai4elm/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup
module load cray-python/3.11.7
./check_input_data --download
```

OLCF GSWP3 v1 under `DIN_LOC_ROOT` was incomplete at case creation (partial
monthly files; missing `TPQW`). Fill 1901–1920 with `--download` or rsync from
NERSC before multi-year AD. See `DATA.md` for the full checklist.

Do not submit AD until custom files, the ne30pg2 domain, and GSWP3 1901–1920
are present. Then `./case.build`, optional short smoke, then AD segments.

## Pathfinder port (OLCF)

Duplicate the Frontier cold-start case on Pathfinder using a dedicated pin plus
a Pathfinder machine overlay (the science pin has no `pathfinder` machine entry).

| Item | Value |
|---|---|
| Checklist / scripts | [`../case_gene/PathFinder/AI4ELM_GSW/README.md`](../case_gene/PathFinder/AI4ELM_GSW/README.md) |
| Setup worktree | `bash scripts/setup_e3sm_ai4elm_worktree.sh` |
| Stage from Frontier | `MODE=spinup bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh` |
| Smoke (5 days, 128 ranks) | `…/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke.sh` |
| AD (default 1280 ranks) | `…/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh` |

On Pathfinder after `git pull`:

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
bash scripts/setup_e3sm_ai4elm_worktree.sh
MODE=spinup bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh
bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke.sh
cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke && ./case.build && ./case.submit
```

Do not reuse `E3SM-era5` or TES `E3SM/` for this experiment. Details and data
paths: [`../case_gene/PathFinder/AI4ELM_GSW/DATA.md`](../case_gene/PathFinder/AI4ELM_GSW/DATA.md).

## Final (normal) spinup after AD

Create a new case from the same science branch/compset/grid. Turn off AD BGC
spinup options and start from the AD restart, for example:

```bash
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -nutrient_comp_pathway rd -soil_decomp ctc -methane -hydrstress -irrig .true. -tw_irr_on -crop -solar_rad_scheme top"
# Point finidat (and related restarts) at the AD end-state, then CONTINUE or startup as appropriate.
```