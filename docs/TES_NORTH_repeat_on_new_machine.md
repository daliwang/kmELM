# Repeat TES_NORTH AD and finalspin on a new machine (Polaris example)

**Date:** 2026-09-13  
**Audience:** A new user who has not run TES_NORTH before and needs to
reproduce the 4 km AD spinup and finalspin on another HPC, especially
**Polaris at ALCF**.  
**Experiment:** `TES_NORTHERA5` / `uELM_NORTHERA5` (Daymet–ERA5, NALCMS
surfdata, ELM CNP).  
**This is not** the global f09 ERA5 spinup (`I1850ERACNPRDCTCBC` / `ERAf09`).

Science files, SHA256 sums, DATM streams, and the Pathfinder as-run PE
layout are recorded in
[`TES_NORTH_baseline_on_pathfinder.md`](./TES_NORTH_baseline_on_pathfinder.md).
This document is the **porting playbook**: what to copy, how to build, how
to submit AD, how to start finalspin from the AI restart, and how Polaris
queues force the segment length.

Create-script reference (Pathfinder; do not run these as-is on Polaris):

- `case_gene/PathFinder/TES_NORTHERA5/TES_NORTHERA5_ref.sh` (AD)
- `case_gene/PathFinder/TES_NORTHERA5/TES_NORTHERA5_finalspin_ref.sh` (first finalspin)

---

## 0. What you are reproducing

```
AD 20 yr (0001–0021, cold start, spinup_state=1, suplphos=ALL)
        │
        ▼
AI-updated elm.r.0021   (copy this 49 GB file; do not re-run AI)
        │
        ▼
finalspin first submit   CONTINUE_RUN=FALSE
                         finidat = AI 0021 file
                         RUN_STARTDATE = 0401-01-01
                         spinup_state=0, suplphos=NONE
        │
        ▼
finalspin continue       CONTINUE_RUN=TRUE  (rpointer.lnd / rpointer.drv)
                         10-year segments, restart every 2 years
```

Do **not** create the historical transient case here. That is a later,
separate case that reads a January-1 finalspin `elm.r`.

Two valid ways to get a finalspin IC:

| Path | When to use |
|---|---|
| **A. Copy the Pathfinder AI restart** (recommended) | You want the same TES_NORTH baseline. Copy the 49 GB AI `0021` file. You still run AD on the new machine only if you want a local AD archive; you do **not** need a new AD `0021` for finalspin. |
| **B. Re-run AD on the new machine, then reuse the same AI file** | You want to prove AD works on Polaris. The AI file is still the finalspin IC. Do **not** point finalspin at the raw AD `0021` (pre-AI). |

There is no AD `0401` restart on Pathfinder. AD stopped at `0021`. The
model clock for finalspin is set to `0401-01-01` by convention.

---

## 1. Prerequisites

### 1.1 Accounts and allocation (Polaris)

- ALCF account and MFA (`ssh <user>@polaris.alcf.anl.gov`).
- A project with node-hours (`qstat -x` / `sbank` as your project uses).
- CIME will require `PROJECT`. The machine file default is `E3SMinput`;
  **override it** with your project unless you are charged to that one.
- Disk on **Eagle** and/or **Grand**. Home is too small. Forcing +
  restarts need about **1.5–2 TB** for a full AD + first finalspin
  campaign if you keep a few 49 GB restarts.
- Globus access from the source machine (Pathfinder / OLCF) to
  `alcf#dtn_eagle` or `alcf#dtn_grand`.

Docs: <https://docs.alcf.anl.gov/polaris/>

### 1.2 What Polar is (for PE and queue choices)

From the E3SM `MACH=polaris` file in this repo:

| Item | Value |
|---|---|
| Nodes | 560 |
| CPU | 1× AMD EPYC 7543P, **32 cores** |
| GPU | 4× A100 (not used for this I-compset) |
| Memory | 512 GB / node |
| Scheduler | PBS Pro |
| CIME compilers | `gnu` (CPU), `gnugpu`, `nvidia`, `nvidiagpu` |
| MPI | `mpich` only |
| `MAX_MPITASKS_PER_NODE` (`gnu`) | **32** |
| Default `DIN_LOC_ROOT` | `/grand/E3SMinput/data` |
| Default scratch | `/eagle/$PROJECT/$USER/scratch/polaris` |

Use **`gnu` + `mpich`**, not `gnugpu`. This is land-only DATM+ELM.

### 1.3 Polar queue vs wall-clock (read this before you pick NTASKS)

Polaris `prod` wall-clock is a function of **node count**:

| Queue | Nodes | Max wall |
|---|---|---|
| `debug` | 1–2 | 1 h |
| `debug-scaling` | 3–9 | 1 h |
| `prod` | 10–24 | **3 h** |
| `prod` | 25–99 | **6 h** |
| `prod` | 100–496 | **24 h** |

Pathfinder AD took ~**36 h** at 840 LND tasks (~1.8 h/year). Finalspin
took ~**0.8–0.9 h/year** at 1920 tasks. Those runtimes **do not fit**
in a 6 h Polar `prod` job at ~27–60 nodes.

You must do one of:

1. **Short segments** on ~27–60 nodes (2–5 years per job, `RESUBMIT`), or
2. **≥100 nodes** to unlock 24 h `prod` (more node-hours per job, fewer
   submits).

Recommended starting layouts are in §7.

### 1.4 Software on the login node

You need git, python3, and (after `create_newcase`) the E3SM Polar
module set (`PrgEnv-gnu`, netcdf, parallel-netcdf). CIME loads those
during `case.build`. Do not mix Pathfinder `openmpi` flags into Polar
`mpich` jobs.

---

## 2. Clone kmELM and the TES E3SM tree

On Polar, put the repo on Eagle (not `$HOME`):

```bash
export ALCF_PROJECT=<your_project>          # e.g. MyProj
export KMELM_ROOT=/eagle/${ALCF_PROJECT}/${USER}/kmELM
mkdir -p "$(dirname "${KMELM_ROOT}")"
git clone git@github.com:daliwang/kmELM.git "${KMELM_ROOT}"
cd "${KMELM_ROOT}"
git submodule update --init --recursive
```

TES_NORTH uses **`${KMELM_ROOT}/E3SM`**, not `E3SM-era5`.
See [`e3sm_source_trees.md`](./e3sm_source_trees.md).

```bash
cd "${KMELM_ROOT}"
git -C E3SM fetch origin
# Branch that has DATM_MODE=uELM_TES. Fork master has the streams.
# TESSFA_4km has I1850uELMTESCNPRDCTCBC but may lack Polar machine files.
git -C E3SM checkout master          # or TESSFA_4km if Polar is present
git -C E3SM submodule update --init --recursive
```

Confirm Polar is a known machine before you go further:

```bash
grep -n 'MACH="polaris"' E3SM/cime_config/machines/config_machines.xml
```

If that grep is empty, overlay the `polaris` blocks from a tree that has
them (`config_machines.xml`, `config_batch.xml`, and any
`cmake_macros/polaris_*.cmake`). Do **not** overlay Pathfinder-only
files and expect Polar to work.

Also confirm `uELM_TES` exists:

```bash
grep -n 'uELM_TES' E3SM/components/data_comps/datm/cime_config/namelist_definition_datm.xml | head
```

---

## 3. Copy the TES_NORTH data tree

### 3.1 What to copy (minimum for AD + finalspin)

Source on Pathfinder:

```
/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain
```

Destination example:

```bash
export DATA_ROOT=/eagle/${ALCF_PROJECT}/${USER}/TES_cases_data/Daymet_ERA5_TESSFA_NORTH
```

Copy this layout (rebuild the DATM softlinks on Polar; do not copy
broken absolute symlinks):

```
<DATA_ROOT>/entire_domain/
  domain_surfdata/
    domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc
    NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc   # symlink
    surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc
  forcing/
    Precip3Hrly/climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.Prec.YYYY-MM.nc
    Solar3Hrly/climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.Solr.YYYY-MM.nc
    TPHWL3Hrly/climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.TPQWL.YYYY-MM.nc
```

| Set | Years | Size | Needed for |
|---|---|---|---|
| Spinup DATM cycle | **1980–1999** | **~400 GB** | AD and finalspin |
| Full archive | 1980–2023 | ~878 GB | later transient only |

Copy **1980–1999** first (240 months × 3 streams = 720 files).

January 1980 sizes for a test copy: Prec ~251 MB, Solr ~251 MB,
TPQWL ~1.3 GB.

Do **not** copy `NORTHERA5_surfdata.TES_NORTHERA5.4km.1d.c251009.nc` as
the baseline `fsurdat`. The as-run file is the NALCMS
`surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc`.

### 3.2 Globus (preferred)

From a machine with Globus CLI, or the web app:

- Source: Pathfinder / OLCF DTN that can see `…/Daymet_ERA5_TESSFA_NORTH`
- Dest: `alcf#dtn_eagle` → `${DATA_ROOT}/entire_domain`

Preserve file names. After the transfer, **rebuild**
`atm_forcing.datm7.km.1d/` on Polar (next subsection). Absolute
symlinks from Pathfinder will be wrong.

### 3.3 Rebuild DATM softlinks

The generator lives in kiloCraft. If that repo is not on Polar, copy
`kiloCraft/TES_inputGEN/TES_NORTH/data_generation_era5/NORTHERA5_softlink_creation.py`
next to `entire_domain/` and run it **from `entire_domain/`**:

```bash
cd "${DATA_ROOT}/entire_domain"
python3 NORTHERA5_softlink_creation.py
```

It creates:

```
atm_forcing.datm7.km.1d/clmforc.Daymet.km.1d.Prec.YYYY-MM.nc
atm_forcing.datm7.km.1d/clmforc.Daymet.km.1d.Solr.YYYY-MM.nc
atm_forcing.datm7.km.1d/clmforc.Daymet.km.1d.TPQWL.YYYY-MM.nc
atm_forcing.datm7.km.1d/domain.lnd.Daymet.km.1d.nc
```

`DATM_MODE=uELM_TES` looks up exactly those names under
`$DIN_LOC_ROOT_CLMFORC/atm_forcing.datm7.km.1d`.
`DIN_LOC_ROOT_CLMFORC` must be `…/entire_domain` (the parent of
`atm_forcing.datm7.km.1d`), not the `forcing/` folder.

Check 1980–1999:

```bash
cd "${DATA_ROOT}/entire_domain/atm_forcing.datm7.km.1d"
ls -1 clmforc.Daymet.km.1d.Prec.198{0,1,2,3,4,5,6,7,8,9}-*.nc | wc -l   # 120
ls -1 clmforc.Daymet.km.1d.Prec.199{0,1,2,3,4,5,6,7,8,9}-*.nc | wc -l   # 120
readlink -f domain.lnd.Daymet.km.1d.nc
```

You want 240 Prec + 240 Solr + 240 TPQWL links, and the domain link
must resolve to
`domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc`.

### 3.4 Verify domain and surfdata

```bash
cd "${DATA_ROOT}/entire_domain/domain_surfdata"
sha256sum domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc \
          surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc
ncdump -h domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc | head
```

Expected:

```
cfaffb0315dbe85d1346b504d0c4f586322f8d6a23d42b4a61bcb3b4767a284a  domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc
0f9b46c8647f0f8b1f96ff908379bc9492fb04412f3404c7abf774b7a7aa60bf  surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc
```

Domain: `ni=259535`, `nj=1`, parent `x=1321`, `y=433`.
Surfdata: `gridcell=259535`.

Also create the case-name symlink if you copied only the real file:

```bash
ln -sfn domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc \
        NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc
```

---

## 4. Stock E3SM inputdata (`DIN_LOC_ROOT`)

ELM also reads parameter and stream files under `DIN_LOC_ROOT`.
On Polar the machine default is `/grand/E3SMinput/data`. If your
project can read that tree, use it and **only override**
`DIN_LOC_ROOT_CLMFORC` to the TES `entire_domain`.

Required relative paths (from the Pathfinder as-run `lnd_in` / streams):

| Namelist / stream | Path under `DIN_LOC_ROOT` | SHA256 (full or first 16) |
|---|---|---|
| `paramfile` | `lnd/clm2/paramdata/clm_params_c211124.nc` | `3876806bdaf2c432…91042e9` |
| `fsoilordercon` | `lnd/clm2/paramdata/CNP_parameters_c180529.nc` | `fc9323002ef94cee…181357c` |
| `fsnowoptics` | `lnd/clm2/snicardata/snicar_optics_5bnd_mam_c160322.nc` | |
| `fsnowaging` | `lnd/clm2/snicardata/snicar_drdt_bst_fit_60_c070416.nc` | |
| N deposition | `lnd/clm2/ndepdata/fndep_elm_cbgc_exp_simyr1849-2101_1.9x2.5_ssp245_c240903.nc` | |
| P deposition | `lnd/clm2/pdepdata/fpdep_clm_hist_simyr2000_1.9x2.5_c150929.nc` | |
| Population density | `lnd/clm2/firedata/elmforc.Li_20181205_mod_hist_SSP2_CMIP6_hdm_0.5x0.5_AVHRR_simyr1850-2100_c240906.nc` | |
| Lightning | `atm/datm7/NASA_LIS/clmforc.Li_2012_climo1995-2011.T62.lnfm_Total_c140423.nc` | |
| 1850 aerosol | `atm/cam/chem/trop_mozart_aero/aero/aerosoldep_monthly_1850_mean_1.9x2.5_c090421.nc` | |
| DATM topo | `atm/datm7/topo_forcing/topodata_0.9x1.25_USGS_070110_stream_c151201.nc` | |

Full SHA256 for the two parameter files:

```
3876806bdaf2c432dde41db748b139b962068f6c1b0a1c86324c60eaf91042e9  clm_params_c211124.nc
fc9323002ef94ceeb480f1f9b97b1a876a29667f076197c3e1c49216b181357c  CNP_parameters_c180529.nc
```

**Pathfinder quirk:** as-run cases set `DIN_LOC_ROOT` to
`/projects/hpcl-cli185/world-shared/e3sm` (the **parent** of
`inputdata`) because that tree stores `lnd/clm2` at
`$DIN_LOC_ROOT/lnd/clm2`. Polar `/grand/E3SMinput/data` is already
the `inputdata`-style root. After `case.setup`, open
`CaseDocs/lnd_in` and confirm those paths exist. If CIME prepends an
extra `inputdata/` and files 404, point `DIN_LOC_ROOT` at the parent
or the child until `lnd/clm2/paramdata/clm_params_c211124.nc` resolves.

If you cannot read `/grand/E3SMinput/data`, copy the files above from
Pathfinder `…/world-shared/e3sm/` (or `…/e3sm/inputdata/`) into your
Eagle tree and set `DIN_LOC_ROOT` to that root.

---

## 5. Copy the AI restart (finalspin IC)

Pathfinder path:

```
/projects/hpcl-cli185/proj-shared/wangd/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_TESNORTH_inference/AI_restartfile/updated_restart_normal_spinup_uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC.elm.r.0021-01-01-00000.nc
```

49 GB, `gridcell=259535`. Put it on Eagle, for example:

```bash
export AI_RESTART=/eagle/${ALCF_PROJECT}/${USER}/TES_NORTH_IC/updated_restart_normal_spinup_uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC.elm.r.0021-01-01-00000.nc
```

Do **not** use
`…/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC/run/…elm.r.0021-01-01-00000.nc`
(the raw AD file). That is the pre-AI restart.

`ncdump -h` should show `gridcell = 259535`.

---

## 6. Science settings that must not change

These are the TES_NORTH baseline. Only PE, queue, wall-clock, paths,
and `--mach` change on Polar.

| Item | AD | Finalspin |
|---|---|---|
| Compset | `I1850CNPRDCTCBC` | same |
| Compset long name | `1850_DATM%QIA_ELM%CNPRDCTCBC_SICE_SOCN_MOSART_SGLC_SWAV_SIAC_SESP` | same |
| Resolution | `ELM_USRDAT` | same |
| `DATM_MODE` | **`uELM_TES`** (set after create; do not leave `%QIA`) | same |
| Driver | MCT (`COMP_INTERFACE=mct`) | same |
| PIO | `pnetcdf`, `64bit_data` | same |
| `ATM_NCPL` | 24 (ELM `dtime=3600`) | same |
| DATM years | 1980–1999, align 1990 | same |
| CO2 | 284.7 ppm (compset default) | same |
| `ELM_BLDNML_OPTS` | `-bgc bgc -nutrient cnp -nutrient_comp_pathway rd -soil_decomp ctc -methane -bgc_spinup on` | same without `-bgc_spinup on` |
| `ELM_ACCELERATED_SPINUP` | on | off |
| `ELM_FORCE_COLDSTART` | on | off |
| `spinup_state` | **1** | **0** |
| `suplphos` | **`ALL`** | **`NONE`** |
| `nyears_ad_carbon_only` | 25 | unset |
| `spinup_mortality_factor` | 10 | unset |
| `RUN_TYPE` | startup | startup (first segment only) |
| `RUN_STARTDATE` | 0001-01-01 | **0401-01-01** |
| `finidat` | empty | **AI 0021 restart** |
| History | `hist_nhtfrq=-175200`, `hist_mfilt=1` | same |
| MOSART | `MOSART_MODE=NULL` (as-run) | same |

`I1850uELMTESCNPRDCTCBC` is an equivalent alias on `TESSFA_4km`. The
Pathfinder `_ref` scripts use stock `I1850CNPRDCTCBC` plus
`DATM_MODE=uELM_TES` so they run on a fork `master` that already has
machine files. Prefer that pattern on Polar.

---

## 7. Polar PE layouts (start here)

259,535 land cells. Pathfinder AD used ~309 cells/task (840 LND);
finalspin used ~135 cells/task (1920 LND).

Use **32 MPI/node** (`gnu`). Round LND tasks to a multiple of 32.

| Job | LND (= ATM = CPL for finalspin) | Nodes | Queue / max wall | Suggested `STOP_N` |
|---|---:|---:|---|---|
| 10-day smoke | 64 | 2 | `debug` / 1 h | 10 days |
| AD, few-node | 864 | 27 | `prod` / **6 h** | **2 years** (then continue) |
| AD, 24 h queue | 3200 | 100 | `prod` / 24 h | 20 years (or 10 + continue) |
| Finalspin, few-node | 1920 | 60 | `prod` / **6 h** | **5 years** |
| Finalspin, 24 h queue | 3200 | 100 | `prod` / 24 h | 10 years |

Set `NTASKS=1` first, then the component counts, then
`MAX_MPITASKS_PER_NODE=32` and `MAX_TASKS_PER_NODE=32`. For AD you
can keep ATM/CPL smaller (Pathfinder used ATM 50, CPL 1) **if** they
share `rootpe=0` with LND; `TOTALPES` is then the max (LND). On Polar
it is simpler to set ATM=CPL=LND to the same count so DATM IO is not
stuck on 50 ranks.

`MOSART` / ice / ocn stay at 1 (stubs).

---

## 8. Create and run AD on Polar

Do **not** run `TES_NORTHERA5_ref.sh` unchanged (`--mach pathfinder`,
Pathfinder paths). Either edit a copy or type the commands below.

```bash
export ALCF_PROJECT=<your_project>
export KMELM_ROOT=/eagle/${ALCF_PROJECT}/${USER}/kmELM
export E3SM_SRCROOT=${KMELM_ROOT}/E3SM
export E3SM_DIN=/grand/E3SMinput/data          # or your copy; see §4
export DATA_ROOT=/eagle/${ALCF_PROJECT}/${USER}/TES_cases_data/Daymet_ERA5_TESSFA_NORTH
export CASE_DATA=${DATA_ROOT}/entire_domain
export CASEDIR=${KMELM_ROOT}/e3sm_cases/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC
export DOMAIN_FILE=NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc
export SURFDATA_FILE=surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc
```

### 8.1 create_newcase

```bash
"${E3SM_SRCROOT}/cime/scripts/create_newcase" \
  --case "${CASEDIR}" \
  --mach polaris \
  --compiler gnu \
  --mpilib mpich \
  --compset I1850CNPRDCTCBC \
  --res ELM_USRDAT \
  --project "${ALCF_PROJECT}" \
  --handle-preexisting-dirs r \
  --srcroot "${E3SM_SRCROOT}"

cd "${CASEDIR}"
```

### 8.2 xmlchange (AD)

```bash
./xmlchange COMP_INTERFACE=mct
./xmlchange PIO_TYPENAME=pnetcdf
./xmlchange PIO_NETCDF_FORMAT=64bit_data
./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"
./xmlchange CIME_OUTPUT_ROOT="${KMELM_ROOT}/e3sm_runs"
./xmlchange DATM_MODE=uELM_TES
./xmlchange PROJECT="${ALCF_PROJECT}"
./xmlchange CHARGE_ACCOUNT="${ALCF_PROJECT}"

./xmlchange NTASKS=1
./xmlchange NTASKS_LND=864
./xmlchange NTASKS_ATM=864
./xmlchange NTASKS_CPL=864
./xmlchange NTASKS_PER_INST=1
./xmlchange MAX_MPITASKS_PER_NODE=32
./xmlchange MAX_TASKS_PER_NODE=32

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"
./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange ATM_NCPL=24
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1999
./xmlchange DATM_CLMNCEP_YR_ALIGN=1990

./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE=0001-01-01
./xmlchange ELM_FORCE_COLDSTART=on
./xmlchange CONTINUE_RUN=FALSE
./xmlchange ELM_ACCELERATED_SPINUP=on
./xmlchange --append ELM_BLDNML_OPTS="-bgc_spinup on"

# 27 nodes → 6 h max. Do not ask for 20 years in one job at this PE.
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=2
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=2
./xmlchange JOB_WALLCLOCK_TIME=06:00:00
./xmlchange --force JOB_QUEUE=prod
```

If you instead take the 100-node / 24 h option, set `NTASKS_*=3200`,
`STOP_N=20`, `REST_N=5`, `JOB_WALLCLOCK_TIME=24:00:00`.

### 8.3 user_nl_elm (AD)

```bash
cat >> user_nl_elm <<EOF
fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      hist_dov2xy = .true.,.true.
      hist_nhtfrq=-175200
      hist_mfilt=1
      spinup_state = 1
      suplphos = 'ALL'
      nyears_ad_carbon_only = 25
      spinup_mortality_factor = 10
EOF
```

Leave hourly `hist_fincl2` commented out (Pathfinder baseline).

### 8.4 setup, build, smoke, then AD

`case.build` is heavy; run it in a `debug` interactive job or a
one-node PBS build job if the login node is busy.

```bash
./case.setup --reset
./case.setup
./case.build --clean-all
./case.build
```

**10-day smoke** (2 nodes, `debug`):

```bash
./xmlchange NTASKS_LND=64,NTASKS_ATM=64,NTASKS_CPL=64
./xmlchange STOP_OPTION=ndays,STOP_N=10
./xmlchange REST_OPTION=ndays,REST_N=10
./xmlchange JOB_WALLCLOCK_TIME=01:00:00
./xmlchange --force JOB_QUEUE=debug
./case.submit
```

Success looks like: `CaseStatus` has `model execution success`,
`datm.log` opened `clmforc.Daymet.km.1d.*.1980-01.nc`, and a small
`elm.r.0001-01-11-00000.nc` exists. **Do not** use that smoke restart
as a spinup IC.

Reset to the AD layout in §8.2 (`CONTINUE_RUN=FALSE` still, or
`TRUE` only if you are continuing a multi-year AD). Then:

```bash
./case.submit
```

After each 2-year AD segment:

```bash
cd "${CASEDIR}"
# Confirm rpointer.lnd names an existing elm.r.YYYY-01-01-00000.nc
./xmlchange CONTINUE_RUN=TRUE
./xmlchange STOP_OPTION=nyears,STOP_N=2
./xmlchange REST_OPTION=nyears,REST_N=2
./xmlchange RESUBMIT=9          # optional: 10 segments × 2 yr = 20 yr
./case.submit
```

Stop when you have `…elm.r.0021-01-01-00000.nc`. That local AD file
is **not** the finalspin IC unless you run a new AI update. For the
TES_NORTH baseline, finalspin still reads the **copied AI** file.

---

## 9. Create and run finalspin on Polar

New case name. Do not reuse the AD caseroot.

```bash
export CASEDIR=${KMELM_ROOT}/e3sm_cases/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC_finalspin
# AI_RESTART already set in §5
```

### 9.1 create_newcase

Same `create_newcase` as §8.1, new `--case`. Then:

```bash
cd "${CASEDIR}"
./xmlchange COMP_INTERFACE=mct
./xmlchange PIO_TYPENAME=pnetcdf
./xmlchange PIO_NETCDF_FORMAT=64bit_data
./xmlchange DIN_LOC_ROOT="${E3SM_DIN}"
./xmlchange DIN_LOC_ROOT_CLMFORC="${CASE_DATA}"
./xmlchange CIME_OUTPUT_ROOT="${KMELM_ROOT}/e3sm_runs"
./xmlchange DATM_MODE=uELM_TES
./xmlchange PROJECT="${ALCF_PROJECT}"
./xmlchange CHARGE_ACCOUNT="${ALCF_PROJECT}"

./xmlchange NTASKS=1
./xmlchange NTASKS_ATM=1920
./xmlchange NTASKS_CPL=1920
./xmlchange NTASKS_LND=1920
./xmlchange NTASKS_PER_INST=1
./xmlchange MAX_MPITASKS_PER_NODE=32
./xmlchange MAX_TASKS_PER_NODE=32

./xmlchange ATM_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange ATM_DOMAIN_FILE="${DOMAIN_FILE}"
./xmlchange LND_DOMAIN_PATH="${CASE_DATA}/domain_surfdata/"
./xmlchange LND_DOMAIN_FILE="${DOMAIN_FILE}"

./xmlchange ATM_NCPL=24
./xmlchange DATM_CLMNCEP_YR_START=1980
./xmlchange DATM_CLMNCEP_YR_END=1999
./xmlchange DATM_CLMNCEP_YR_ALIGN=1990

./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE=0401-01-01
./xmlchange CONTINUE_RUN=FALSE
./xmlchange ELM_ACCELERATED_SPINUP=off
./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_BLDNML_OPTS="-bgc bgc -nutrient cnp -nutrient_comp_pathway rd -soil_decomp ctc -methane"

# 60 nodes → 6 h max. 10 years will not finish; use 5 years.
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=5
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=2
./xmlchange JOB_WALLCLOCK_TIME=06:00:00
./xmlchange --force JOB_QUEUE=prod
```

### 9.2 user_nl_elm (finalspin)

```bash
cat >> user_nl_elm <<EOF
finidat = '${AI_RESTART}'
fsurdat = '${CASE_DATA}/domain_surfdata/${SURFDATA_FILE}'
      hist_dov2xy = .true.,.true.
      hist_nhtfrq=-175200
      hist_mfilt=1
      spinup_state = 0
      suplphos = 'NONE'
EOF
```

### 9.3 First submit vs continue

`case.setup` / `case.build` as in §8.4. Optional 10-day smoke from
`0401-01-01` with `CONTINUE_RUN=FALSE`. Do **not** keep the
`elm.r.0401-01-11` smoke file as a later IC.

First multi-year submit: `CONTINUE_RUN=FALSE` so ELM reads `finidat`.

**Every later job:**

```bash
cd "${CASEDIR}"
./xmlchange CONTINUE_RUN=TRUE
# do not edit finidat
# do not delete run/rpointer.lnd or run/rpointer.drv
./xmlchange STOP_OPTION=nyears,STOP_N=5
./xmlchange REST_OPTION=nyears,REST_N=2
./case.submit
```

Rules:

1. Do not set `CONTINUE_RUN=FALSE` again unless you intend to restart
   from the AI file at year 0401.
2. Confirm `rpointer.lnd` names an existing
   `…elm.r.YYYY-01-01-00000.nc` and `rpointer.drv` names the matching
   `cpl.r`.
3. Each 2-year restart is ~49 GB. Delete older ones after the next
   segment is verified if Eagle is tight.
4. If `CaseStatus` shows `model execution starting` and no
   success/error, the job is still running or was killed. Check PBS
   (`qstat -u $USER`) and the newest `elm.r` year before submitting
   again.

---

## 10. Checks after the first successful year

| Check | Pass |
|---|---|
| `CaseDocs/datm_in` `datamode` | `CLMNCEP` |
| TES streams | `uELM_TES.Prec`, `.Solr`, `.TPQWL` with `mapalgo=copy` |
| DATM files | opened `clmforc.Daymet.km.1d.*.YYYY-MM.nc` (no “file not found”) |
| `CaseDocs/lnd_in` `fsurdat` | NALCMS `…c260218_yw.nc` |
| `fatmlndfrc` / domain | `NORTHERA5_domain.lnd.…4km.1d.c251009.nc` |
| AD `spinup_state` / `suplphos` | `1` / `ALL` |
| Finalspin `spinup_state` / `suplphos` | `0` / `NONE` |
| `gridcell` on `elm.r` | 259535 |
| History | one `elm.h0` per year, ~1.7 GB |

---

## 11. Other machines (same science, different wrapper)

Replace only the machine wrapper. Keep §3–§6 and §8–§9 science
settings.

| Item | Polar | What you change elsewhere |
|---|---|---|
| `--mach` | `polaris` | `frontier`, `pm-cpu`, … |
| Compiler / MPI | `gnu` / `mpich` | that machine’s CPU land combo |
| MPI / node | 32 | cores per node (or a comfortable packing) |
| Queue / wall | PBS; wall tied to node count | Slurm/PBS limits on that site |
| `PROJECT` | required | as required |
| Scratch | `/eagle/$PROJECT/$USER/...` | Lustre / GPFS project space |
| `DIN_LOC_ROOT` | `/grand/E3SMinput/data` or your copy | local E3SM inputdata |

Target ~150–300 land cells per LND task, then shorten `STOP_N` until
one segment finishes inside the queue wall with ~20% margin. Time a
10-day smoke and a 1-year job before you lock a 20-year plan.

---

## 12. New-user checklist

- [ ] `E3SM/` has `uELM_TES` **and** `MACH=polaris` (or your machine)
- [ ] You did **not** use `E3SM-era5` / `ERAf09` / f09 surfdata
- [ ] 1980–1999 forcing is on Eagle (~400 GB) and SHA256 domain/surfdata match §3.4
- [ ] `NORTHERA5_softlink_creation.py` was run **on Polar** from `entire_domain/`
- [ ] `DIN_LOC_ROOT_CLMFORC` = `…/entire_domain` (DATM sees `atm_forcing.datm7.km.1d`)
- [ ] Stock `clm_params_c211124.nc` and `CNP_parameters_c180529.nc` SHA256 match
- [ ] `PROJECT` is your ALCF allocation
- [ ] PE × queue wall: 27–60 nodes ⇒ 6 h ⇒ `STOP_N` of 2–5 years; 100+ nodes ⇒ 24 h
- [ ] AD smoke 10 days succeeded
- [ ] AD `0021` exists if you re-ran AD; finalspin `finidat` is still the **AI** file
- [ ] First finalspin used `CONTINUE_RUN=FALSE`; later jobs use `TRUE` and `rpointer`
- [ ] No hourly history; no `REST_N=2` pile-up beyond what you can store

---

## 13. Troubleshooting

| Symptom | Likely cause |
|---|---|
| `create_newcase` unknown machine | Polar blocks missing on this E3SM branch; overlay them |
| `DATM_MODE` rejected | Tree has no `uELM_TES`; checkout fork `master` or `TESSFA_4km` |
| DATM cannot open `clmforc.Daymet.km.1d.*` | Softlinks not rebuilt, or `DIN_LOC_ROOT_CLMFORC` points at `forcing/` instead of `entire_domain` |
| `fsurdat` / domain not found | Path not visible on compute nodes (`filesystems=home:grand:eagle` is already in the Polar batch file; data must sit on Eagle/Grand) |
| Build wants MOAB / nuopc | Set `COMP_INTERFACE=mct` (Pathfinder as-run) |
| Job rejected: walltime / nodes | You asked for 24 h on <100 nodes. See §1.3 |
| OOM | Too many cells/task or 32 MPI/node too tight; drop MPI/node to 16 and add nodes |
| Finalspin looks like AD carbon | `spinup_state` still 1 or `ELM_ACCELERATED_SPINUP=on` |
| Finalspin restarted at 0401 unexpectedly | `CONTINUE_RUN` was reset to `FALSE` |
| `gridcell` mismatch | Wrong domain or a 1 km / 2 km file mixed in |

---

## 14. Related docs

| Doc | Role |
|---|---|
| [`TES_NORTH_baseline_on_pathfinder.md`](./TES_NORTH_baseline_on_pathfinder.md) | As-run science, SHA256, DATM streams, Pathfinder PE |
| [`TES_NORTH_resolution_comparison.md`](./TES_NORTH_resolution_comparison.md) | 4 / 2 / 1 km size and wall-time comparison |
| [`e3sm_source_trees.md`](./e3sm_source_trees.md) | Which E3SM checkout to use |
| [`../case_gene/PathFinder/TES_NORTHERA5/README.md`](../case_gene/PathFinder/TES_NORTHERA5/README.md) | Pathfinder create scripts (do not run as-is on Polar) |
