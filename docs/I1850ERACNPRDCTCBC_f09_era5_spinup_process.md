# I1850ERACNPRDCTCBC f09 ERA5 spinup process (Frontier → Pathfinder)

**Date:** 2026-09-13  
**Purpose:** Record how the Frontier AD and final spinup cases were created and run, so the same science configuration can be recreated on Pathfinder.  
**Status:** Frontier AD + final **completed**. Pathfinder 5-day smoke **passed** (job `524272`). AD/final not yet created on Pathfinder.

Companion notes:

- Which E3SM tree to use (ERA5 vs TES_NORTH): [`e3sm_source_trees.md`](./e3sm_source_trees.md)
- Smoke (5-day 1980, Frontier): [`I1850ERACNPRDCTCBC_f09_smoke1980_report.md`](./I1850ERACNPRDCTCBC_f09_smoke1980_report.md)
- Short spinup card: [`I1850ERACNPRDCTCBC_f09_spinup_report.md`](./I1850ERACNPRDCTCBC_f09_spinup_report.md)
- Pathfinder scripts: [`case_gene/PathFinder/ERAf09/README.md`](../case_gene/PathFinder/ERAf09/README.md)
- Forcing transfer: [`case_gene/PathFinder/ERAf09/DATA.md`](../case_gene/PathFinder/ERAf09/DATA.md)
- Forcing regrid: `/lustre/orion/cli115/world-shared/wangd/kiloCraft/scripts/README_ERA5_f09_regrid.md`

---

## 1. Confirmation (what is on disk)

| Item | Confirmed value |
|---|---|
| kmELM repo | `/lustre/orion/cli115/world-shared/wangd/kmELM` |
| E3SM checkout | submodule `E3SM/` (fork `git@github.com:daliwang/E3SM.git`) |
| Working branch | **`lnd/clm_glacier_fixes_era5`** (tracks `origin/lnd/clm_glacier_fixes_era5`) |
| Working SHA | **`2a1960cd8a`** — *Add ERA5 f09 DATM forcing and guard hourly accumulators for long timesteps.* |
| Compset | `I1850ERACNPRDCTCBC` → `1850_DATM%ERAf09_ELM%CNPRDCTCBC_SICE_SOCN_MOSART_SGLC_SWAV` |
| Resolution | `f09_f09` (ATM/LND 0.9×1.25, ROF r05) |
| DATM mode | **`ERAf09`** (do **not** use `ERA56HR` / `ERA56HRf09`) |
| Forcing | ERA5 6-hourly remapped onto f09; cycle **1980–1999** |
| Machine used | Frontier / **`craygnu`** |
| Cases | `/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM/e3sm_cases` |
| Runs | `/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM/e3sm_runs` |

`.gitmodules` still lists `branch = master`. The **science branch** for these cases is `lnd/clm_glacier_fixes_era5`, not the SHA recorded in the parent `main` index. Treat that branch as the source of truth for this campaign.

On Pathfinder, pin that branch in a **sibling worktree** so `E3SM/` can track TES_NORTH (`TESSFA_4km`) or other experiments:

```bash
bash scripts/setup_e3sm_era5_worktree.sh
# tree: /projects/hpcl-cli185/proj-shared/wangd/kmELM/E3SM-era5
```

Do not check this branch out in `kmELM/E3SM` while TES_NORTH needs a different branch. Details: [`e3sm_source_trees.md`](./e3sm_source_trees.md).

A third case, `I1850ERACNPRDCTCBC_f09_smoke1980`, is the 1980 5-day smoke (passed job `5216389`). It is not part of the 400+800 yr production chain.

---

## 2. What this branch contains

`lnd/clm_glacier_fixes_era5` is fork `master` @ `a899004464` plus six commits:

| SHA | Role |
|---|---|
| `c304fff2d1` | Port CLM fractional-snow energy and melt-compaction fixes |
| `3f7fd0f8cb` | Port CLM bedrock heat capacity fix |
| `5bdf5f2212` | Port CLM active-element masking for ELM accumulators |
| `4b7a01afc3` | Surface-water runoff calculation fixes |
| `fbfcc93f52` | Snow balance accounting fix |
| `2a1960cd8a` | **`ERAf09` DATM streams + `I1850ERACNPRDCTCBC` + `accum_period = max(1, …)`** |

The last commit is required for this experiment. It adds:

1. Compset alias `I1850ERACNPRDCTCBC` in `components/elm/cime_config/config_compsets.xml`
2. DATM option `%ERAf09` / `DATM_MODE=ERAf09` in `components/data_comps/datm/cime_config/config_component.xml`
3. Stream paths under `$DIN_LOC_ROOT_CLMFORC/ERA5_6hr_f09/...` in `namelist_definition_datm.xml`
4. Hourly-accumulator guard in `VegetationDataType.F90` and `EnergyFluxType.F90` (smoke SIGFPE when `dtime > 3600`)

Without that branch (or an equivalent cherry-pick), `create_newcase --compset I1850ERACNPRDCTCBC` will not resolve.

---

## 3. Forcing product (must be copied to Pathfinder)

DATM and ELM share the stock f09 mesh. ERA5 is **not** used at native 0.25°.

| Role | Frontier path |
|---|---|
| Source 0.25° ERA5 | `/lustre/orion/cli115/world-shared/e3sm/inputdata/atm/datm7/atm_forcing.datm7.ERA.6HRLY.0.25d.v5.c180614` |
| Regrid script | `/lustre/orion/cli115/world-shared/wangd/kiloCraft/scripts/regrid_era56hr_to_f09.py` |
| f09 forcing root | `/lustre/orion/cli115/world-shared/wangd/kiloCraft/ERA5_6hr_f09` |
| `DIN_LOC_ROOT` | `/lustre/orion/cli115/world-shared/e3sm/inputdata` |
| `DIN_LOC_ROOT_CLMFORC` | `/lustre/orion/cli115/world-shared/wangd/kiloCraft` |
| Domain (DATM + ELM) | `share/domains/domain.lnd.fv0.9x1.25_gx1v6.090309.nc` (also copied/symlinked under `ERA5_6hr_f09/`) |
| 1850 surfdata | `lnd/clm2/surfdata_map/surfdata_0.9x1.25_simyr1850_c180306.nc` |

Layout:

```text
ERA5_6hr_f09/
  domain.lnd.fv0.9x1.25_gx1v6.090309.nc
  lwdn/  pbot/  prec/  swdn/  tbot/  tdew/  wind/
    elmforc.ERA5.c2018.0.9x1.25.<var>.YYYY-MM.nc
```

| Stream var | Subdir | DATM field |
|---|---|---|
| `msdwlwrf` | `lwdn` | `lwdn` |
| `sp` | `pbot` | `pbot` |
| `mcpr`, `mlspr` | `prec` | `precc`, `precl` |
| `msdrswrf`, `msdfswrf` | `swdn` | `swdndr`, `swdndf` |
| `t2m` | `tbot` | `tbot` |
| `d2m` | `tdew` | `tdew` |
| `w10` | `wind` | `wind` |

- Shape: `(time, lat, lon)` with `lat=192`, `lon=288`
- Files per year: **108** (12 months × 9 var files)
- On disk: **1979–2022** complete (108 files/year)
- Spinup cycle uses **1980–1999 only** → **2160** files (verified)

`datamode=CLMNCEP`. DATM interpolates 6-hourly data to the land timestep.

---

## 4. Production case design (reproduce this, not the first draft)

Smoke used `ATM_NCPL=4` (native 6-hour coupling). Production **does not**. After two AD crashes at `NCPL=4` / `STOP_N=100` (jobs `5291608`, `5305590`; abort around model year 0007), the working configuration is hourly coupling with 10-year segments.

| Setting | AD | Final |
|---|---|---|
| Case name | `I1850ERACNPRDCTCBC_f09_adspinup` | `I1850ERACNPRDCTCBC_f09_finalspinup` |
| Created | 2026-08-17 | 2026-08-31 |
| Finished | 2026-08-23 (job `5329567`) | 2026-09-05 (job `5428542`) |
| `RUN_TYPE` | `startup` | `startup` |
| `RUN_STARTDATE` | `0001-01-01` | `0401-01-01` |
| `ELM_FORCE_COLDSTART` | `on` | `off` |
| `ELM_ACCELERATED_SPINUP` | `on` | `off` |
| `ELM_BLDNML_OPTS` | append `-bgc_spinup on` | (none) |
| `spinup_state` | `1` | `0` |
| `suplphos` | `'ALL'` | `'NONE'` |
| `nyears_ad_carbon_only` | `25` | — |
| `spinup_mortality_factor` | `10` | — |
| `finidat` | empty (cold start) | AD restart `…elm.r.0401-01-01-00000.nc` |
| DATM years | 1980–1999, `YR_ALIGN=1` | same |
| `ATM/LND/ROF/ICE_NCPL` | **24** (`dtime=3600`) | **24** |
| Length | **400 yr** | **800 yr** |
| Segment | `STOP_N=10`, `REST_N=10` | same |
| `RESUBMIT` at submit | **39** (40 × 10 yr) | **79** (80 × 10 yr) |
| History | `hist_nhtfrq=-175200`, `hist_mfilt=1` (20-yr) | same |
| PE | 1280 MPI, 64/node, 1 thread | same |
| Walltime | `02:00:00` (Frontier batch max) | same |
| Account / queue | `cli115` / `batch` | same |
| End restart | `…adspinup.elm.r.0401-01-01-00000.nc` | `…finalspinup.elm.r.1201-01-01-00000.nc` |

`RESUBMIT` is now `0` on both cases because the chains finished. Recreate with 39 / 79.

Throughput on Frontier (1280 tasks, ~23 nodes because of how Slurm packed 64 MPI/node): **~28 minutes per 10 model years**. That is why 10-year segments were used under a 2-hour wallclock.

`ROF_NCPL` must equal `LND_NCPL`.

---

## 5. How the Frontier cases were created

Canonical scripts (wrappers in `scripts/frontier/` just `exec` these):

```text
case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh
case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_finalspinup.sh
```

Login Python on Frontier is 3.6; CIME needs ≥ 3.9. The scripts load `cray-python/3.11.7` **before** they delete `CASEROOT`.

### 5.1 Checkout

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM
git submodule update --init --recursive
cd E3SM
git fetch origin
git checkout lnd/clm_glacier_fixes_era5
# expect 2a1960cd8a
```

### 5.2 Create AD (script deletes and recreates the case)

```bash
module load cray-python/3.11.7   # if invoking pieces by hand
bash case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh
```

Essential `create_newcase` line:

```bash
E3SM/cime/scripts/create_newcase \
  --case E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_adspinup \
  --mach frontier --compiler craygnu \
  --compset I1850ERACNPRDCTCBC --res f09_f09 \
  --handle-preexisting-dirs r \
  --srcroot $PWD/E3SM
```

Then `xmlchange` paths, DATM years, `NCPL=24`, 10-year segments, AD namelist, `case.setup`, `preview_namelists`. The script does **not** submit.

### 5.3 Build and run AD

```bash
cd E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_adspinup
./case.build
./case.submit
```

Wait until `e3sm_runs/I1850ERACNPRDCTCBC_f09_adspinup/run/I1850ERACNPRDCTCBC_f09_adspinup.elm.r.0401-01-01-00000.nc` exists.

### 5.4 Create, build, and run final

```bash
bash case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_finalspinup.sh
cd E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_finalspinup
./case.build
./case.submit   # only after the AD 0401 restart exists
```

`user_nl_elm` `finidat` is the AD 0401 restart. The create script warns if that file is missing but still writes the path.

### 5.5 What actually ran (Frontier)

**AD**

1. Created 2026-08-17 with first-draft `NCPL=4`, `STOP_N=20`, then hand-changed to `STOP_N=100` / `RESUBMIT=3`.
2. Job `5291608` (17 Aug) and `5305590` (18 Aug) **failed** at 6-hour coupling (~model year 0007).
3. 20 Aug: `xmlchange ATM_NCPL=24,LND_NCPL=24,ROF_NCPL=24,ICE_NCPL=24,STOP_N=10,REST_N=10,RESUBMIT=39,CONTINUE_RUN=FALSE`.
4. 40 successful 10-year segments, 20 Aug–23 Aug. Last job `5329567`. Restart `0401-01-01`. 21 h0 files (20-yr history).

**Final**

1. Created 31 Aug already at `NCPL=24`, `STOP_N=10`, `RESUBMIT=79`.
2. Submitted the same day; 80 successful segments through 5 Sep. Last job `5428542`. Restart `1201-01-01`. 41 h0 files.

Live case XMLs match the table in §4. `replay.sh` in each case directory is the CIME command log (AD’s replay also contains the failed `NCPL=4` / 100-year attempts).

---

## 6. Pathfinder port checklist

Existing `case_gene/PathFinder/TES_NORTHERA5/` scripts are a **different** experiment: 4 km TES / `ELM_USRDAT` / `DATM_MODE=uELM_TES`. Do not reuse those namelists, and do not share the ERA5 E3SM tree with them. TES uses `E3SM/`; this port uses `E3SM-era5/`.

Pathfinder conventions already used in this repo (`TES_NORTHERA5_ref.sh`):

| Item | Pathfinder value used elsewhere |
|---|---|
| Machine | `--mach pathfinder` |
| Compiler | `--compiler gnu --mpilib openmpi` |
| Project root | `/projects/hpcl-cli185` |
| `DIN_LOC_ROOT` | `/projects/hpcl-cli185/world-shared/e3sm/inputdata` |
| kmELM | `/projects/hpcl-cli185/proj-shared/wangd/kmELM` |
| Queue | `parallel` with QOS `normal` (`batch_ccsi` is the old CADES partition and is not on this Pathfinder) |

`lnd/clm_glacier_fixes_era5` includes the Pathfinder machine overlay (`config_machines.xml`, `config_batch.xml`, `cmake_macros/pathfinder_gnu.cmake`). That overlay is additive and does not change the Frontier science through `2a1960cd8a`. Pathfinder has no MOAB, so Pathfinder create scripts set `COMP_INTERFACE=mct`.

### Keep identical (science)

- Branch `lnd/clm_glacier_fixes_era5` @ `2a1960cd8a` (or bit-for-bit equivalent)
- Compset `I1850ERACNPRDCTCBC`, res `f09_f09`, `DATM_MODE=ERAf09`
- DATM cycle 1980–1999, `YR_ALIGN=1`
- `NCPL=24` on ATM/LND/ROF/ICE
- AD 400 yr cold start; final 800 yr from AD `0401-01-01` restart
- `user_nl_elm` fields in §4
- Same domain and 1850 surfdata filenames

### Change (machine)

1. Pin `lnd/clm_glacier_fixes_era5` in `E3SM-era5/` (`bash scripts/setup_e3sm_era5_worktree.sh`). Leave `E3SM/` free for TES_NORTH.
2. Pathfinder CIME machine/compiler files are already on this branch (`c2d41815c1`). Pathfinder has no MOAB; create scripts set `COMP_INTERFACE=mct`.
3. Stage stock E3SM inputdata (`DIN_LOC_ROOT`) including the f09 domain and 1850 surfdata (or `WITH_STOCK=1` in the stage script).
4. On Pathfinder, pull `kiloCraft/ERA5_6hr_f09` (at least 1980–1999, 2160 files + a **real** domain file) to `/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/ERA5_6hr_f09`: `MODE=spinup bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh`. Details: `case_gene/PathFinder/ERAf09/DATA.md`.
5. Create scripts are in `case_gene/PathFinder/ERAf09/` (not under `E3SM/`). Cases and runs go to `${KMELM_ROOT}/e3sm_cases` and `${KMELM_ROOT}/e3sm_runs`. Scripts default `E3SM_SRCROOT` to `E3SM-era5`.
6. Keep 10-year segments until a Pathfinder smoke measures minutes per year; longer walltime can use fewer resubmits but do not change `NCPL` or total years.
7. Smoke first (`STOP_N=5` days, `RUN_STARTDATE=1980-01-01`, `NCPL=24` to match production).
8. AD → wait for `elm.r.0401-01-01-00000.nc` → final.

```bash
bash scripts/setup_e3sm_era5_worktree.sh
bash case_gene/PathFinder/ERAf09/I1850ERACNPRDCTCBC_f09_smoke.sh
# then: cd e3sm_cases/I1850ERACNPRDCTCBC_f09_smoke1980 && ./case.build && ./case.submit
bash case_gene/PathFinder/ERAf09/I1850ERACNPRDCTCBC_f09_adspinup.sh
bash case_gene/PathFinder/ERAf09/I1850ERACNPRDCTCBC_f09_finalspinup.sh
```

### Pathfinder status (2026-09-13)

| Step | Status |
|---|---|
| `E3SM-era5` worktree on `lnd/clm_glacier_fixes_era5` | Created (`scripts/setup_e3sm_era5_worktree.sh`) |
| Forcing 1980 (smoke) | Staged for the 2026-09-12 smoke |
| Forcing 1980–1999 (spinup) | Confirm 2160 files before AD (`DATA.md`) |
| Smoke 5-day 1980, `NCPL=24` | **Passed** job `524272` (built against `.../kmELM/E3SM` before the worktree split). Recreate against `E3SM-era5` if you rebuild. |
| AD 400 yr | Not created yet |
| Final 800 yr | Not created yet |

---

## 7. Lessons that matter for the port

1. Name the DATM mode **`ERAf09`**. Names containing `ERA56HR` collide with the 0.25° stream set.
2. Do not list months that are still being written in DATM streams.
3. The hourly-accumulator `max(1, nint(3600/dtime))` fix is already on this branch; still use `NCPL=24` for production (that is what completed).
4. `ROF_NCPL` must equal `LND_NCPL`.
5. Recreating a case **deletes** `CASEROOT`. Load a CIME-capable Python first.
6. Final `finidat` is a Frontier Lustre path today. On Pathfinder, either copy the AD restart or recreate AD there and point `finidat` at the new path.
7. Use this branch on both Frontier and Pathfinder. Science is `2a1960cd8a`; the Pathfinder machine overlay is `c2d41815c1`. On Pathfinder keep it in `E3SM-era5/`, not in the `E3SM/` submodule if TES_NORTH needs another branch.
8. Recreating a Pathfinder smoke/AD case **deletes** `CASEROOT`. The first Pathfinder smoke (`524272`) predates `E3SM-era5`; new creates pick up `E3SM-era5` automatically.

---

## 8. Artifact index

| Artifact | Path |
|---|---|
| AD case | `E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_adspinup` |
| Final case | `E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_finalspinup` |
| AD run / restart | `E3SM/e3sm_runs/I1850ERACNPRDCTCBC_f09_adspinup/run/` |
| Final run / restart | `E3SM/e3sm_runs/I1850ERACNPRDCTCBC_f09_finalspinup/run/` |
| AD create script (Frontier) | `case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh` |
| Final create script (Frontier) | `case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_finalspinup.sh` |
| Pathfinder create scripts | `case_gene/PathFinder/ERAf09/` (cases/runs under `${KMELM_ROOT}/e3sm_{cases,runs}`, not `E3SM/`) |
| Pathfinder E3SM tree | `${KMELM_ROOT}/E3SM-era5` (`lnd/clm_glacier_fixes_era5`) |
| Pathfinder smoke case | `${KMELM_ROOT}/e3sm_cases/I1850ERACNPRDCTCBC_f09_smoke1980` (job `524272` passed) |
| CIME replay (actual xmlchanges) | `$CASEROOT/replay.sh` |
| Forcing (Frontier) | `/lustre/orion/cli115/world-shared/wangd/kiloCraft/ERA5_6hr_f09` |
| Forcing (Pathfinder) | `/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/ERA5_6hr_f09` |
| Source-tree map | [`e3sm_source_trees.md`](./e3sm_source_trees.md) |
