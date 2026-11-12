# AI4ELM GSWP3 TOP/crop on Pathfinder — status, data, LandSim plan

**Date:** 2026-11-12  
**Experiment:** `I1850GSWCNPRDCTCBCTOPPHSWFMCROP` @ `ne30pg2_r05_IcoswISC30E3r5`  
**Source tree:** `E3SM-ai4elm` @ `48d8ff20cc` (`jinyuntang/elm/fix-top-crop-compsets`)

Perlmutter as-run: [`AI4ELM_Spinup_repeat.md`](./AI4ELM_Spinup_repeat.md)  
Jinyun custom-file CFS paths: [`Extra_Information_from_JinyunTang.md`](./Extra_Information_from_JinyunTang.md)  
Pathfinder scripts: [`../case_gene/PathFinder/AI4ELM_GSW/`](../case_gene/PathFinder/AI4ELM_GSW/)  
TES_NORTH LandSim (different grid — do not mix): [`TES_NORTH_training_and_inference_guide.md`](./TES_NORTH_training_and_inference_guide.md)

This is **not** TES_NORTH 4 km ERA5 and **not** the global f09 ERA5 spinup.

---

## 1. What this experiment is

1850 accelerated-decomposition (AD) ELM with GSWP3 v1 forcing, prognostic crop, TOP solar radiation, irrigation / `tw_irr`, methane, plant hydraulics, C–N–P / CTC / relative demand, and active MOSART (WRM + inundation). Driver `moab`.

| Item | Value |
|---|---|
| Compset alias | `I1850GSWCNPRDCTCBCTOPPHSWFMCROP` |
| Longname | `1850_DATM%GSWP3v1_ELM%CNPRDCTCBCTOPPHSWFMCROP_SICE_SOCN_MOSART_SGLC_SWAV_SIAC_SESP` |
| Land/river grid | Global 0.5°; compacted land `gridcell=94838` on Jinyun `elm.r` files |
| Forcing | GSWP3 v1, 1901–1920, `DATM_CLMNCEP_YR_ALIGN=1` |
| Coupling | `ATM_NCPL=48`, `ROF_NCPL=8` |
| Jinyun Perlmutter AD | 3072 ranks / 24 nodes; pointers reached **0166-01-01** (165 AD years) |

Jinyun’s `elm.r.0166` is an **AD** restart (`spinup_state=1`), not a normal/final-spinup restart. Normal spinup would use `spinup_state=0` and drop `-bgc_spinup on`.

---

## 2. Case creation on Pathfinder

```text
setup_e3sm_ai4elm_worktree.sh
        → stage_ai4elm_inputs.sh
                → create script → case.setup → case.build → case.submit
```

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
bash scripts/setup_e3sm_ai4elm_worktree.sh
MODE=spinup bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh
```

Then one of:

| Script | Case directory | Purpose | Status 2026-11-12 |
|---|---|---|---|
| `I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke.sh` | `e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke` | 5 model days, 128 ranks, cold start | **RUN PASS** job `1103841` (2026-10-30) |
| `I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh` | `e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup` | Multi-year AD from year 1; default 1280 ranks / 10 nodes | Case exists; not the LandSim path |
| `I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node.sh` | `e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node` | 15 nodes / 1920 ranks, `parallel`+NDR, `--mem=500g`, 1 AD year from `finidat` | Case created; **`finidat` still names missing `elm.r.0166`** |

Cases: `${KMELM_ROOT}/e3sm_cases/`  
Runs: `${KMELM_ROOT}/e3sm_runs/`  
Machine: `pathfinder` / `gnu` / `openmpi`. Default queue `parallel` adds `--constraint=NDR` (128-core, ~2.2 TiB). Optional `JOB_QUEUE=hpcl-cli185` (20 nodes, ~503 GB).

`user_nl_elm` lives **in the case directory**, not under `E3SM-ai4elm`. For the 15-node case:

```text
e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node/user_nl_elm
```

Resolved namelist after `preview_namelists`: `CaseDocs/lnd_in`.

The 15-node case is **startup + ELM `finidat`**, not `CONTINUE_RUN`. Perlmutter coupler restarts are 3072 ranks and will not load on 1920.

Do not use `E3SM-era5` or TES `E3SM/` for this experiment.

---

## 3. Pathfinder data inventory (checked 2026-11-12)

Prefix: `PF=/projects/hpcl-cli185/proj-shared/wangd`

### 3.1 ELM / MOSART custom inputs (ready)

`PF/input_data/ai4elm_spinup/`

| File | Notes |
|---|---|
| `surfdata_0.5x0.5_50pfts_20250528.nc` | 5.5 GB |
| `clm_params_c251006.nc` | symlink into world-shared paramdata |
| `ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc` | 333 MB |
| `MOSART_Global_half_20250523.nc` | 87 MB |
| `global_reservoir_halfdegree_c20200917.nc` | symlink into world-shared mosart |

### 3.2 GSWP3 and domain (ready)

```text
/projects/hpcl-cli185/world-shared/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/{Solar,Precip,TPHWL}
/projects/hpcl-cli185/world-shared/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc
```

Solar / Precip / TPHWL each have ~241 files matching 1901–1920. DATM TPQW reads **TPHWL**.

### 3.3 Jinyun restarts on Pathfinder

Copied from Frontier:

```text
/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/AI_restart_files_Jinyun
```

into:

```text
$PF/input_data/ai4elm_spinup/AI_restart_files_Jinyun/
```

| File | Role | Size | Mesh |
|---|---|---|---|
| `20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0021-01-01-00000.nc` | **AD (LandSim X / ELM template)** | **22 GB** | `gridcell=94838`, `pft=5893601` |
| `20261025.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.rg.spinup.elm.r.0202-01-01-00000.nc` | **Regular/normal spinup (LandSim Y)** | **47 MB** | same dimensions |
| `20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.cpl.r.0041-01-01-00000.nc` | Coupler year 41 | 59 MB | not used by LandSim |

`restartfiles_Jinyu/` is empty.

**Not on Pathfinder:** `elm.r.0166-01-01`. Perlmutter path if still needed for AD continue:

```text
/pscratch/sd/j/jinyun/e3sm_scratch/pm-cpu/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup/run/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0166-01-01-00000.nc
```

The 47 MB `rg.spinup` `0202` file has the **same NetCDF dimensions** as the 22 GB AD `0021` file. Treat that as either heavy compression or a truncated copy. Verify pools (`ncdump` / `ncks`) before LandSim training. Recopy from Frontier if the file is incomplete.

Pull from Frontier (OTP/passcode on a real terminal):

```bash
mkdir -p /projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup/AI_restart_files_Jinyun
scp -r wangd@frontier.olcf.ornl.gov:/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/AI_restart_files_Jinyun/. \
  /projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup/AI_restart_files_Jinyun/
```

### 3.4 LandSim / TES_NORTH code (ready, wrong experiment)

| Path | Use |
|---|---|
| `PF/AI4ELM/AI_data/LandSim_dataGEN` | Build training PKLs |
| `PF/AI4ELM/AI_data/LandSim_dataGEN_h0_vectorized` | Alternate extractor |
| `PF/AI4ELM/AI_spinup/AI4BGC` | Train / infer / write restart |
| `…/AI4BGC/scripts/update_restart_with_aiprediction.py` | Write CNP pools into an `elm.r` template |

TES_NORTH datasets under `PF/AI4ELM/AI_data/TES_NORTH_dataset/` (4 km, `gridcell=259535`, `clm_params_c211124`, model `run_20260714_222907`) **must not** be used for this GSWP3 0.5° 50-PFT crop/TOP case.

---

## 4. Hardware notes (Pathfinder)

Jinyun Perlmutter AD: 24 × 128 = **3072 ranks**, ~512 GB/node.

| Layout | Ranks | Cells vs Perlmutter 3072 | Memory outlook |
|---|---|---|---|
| 1-node smoke | 128 | ~24× | Can OOM even on NDR |
| 15-node (`parallel` NDR) | 1920 | ~1.6× | `--mem=500g` ≈ 3.9 GB/rank; similar to Perlmutter RAM/rank with more cells. Raise `--mem` (e.g. 2000g) on NDR if OOM |
| 20-node `hpcl-cli185` | 2560 | ~1.2× | ~503 GB/node; tighter than NDR |
| 24-node NDR | 3072 | 1.0× | Matches Perlmutter PE; NDR often fully allocated |

NDR (`pfc003–030`): 28 nodes, ~2.2 TiB. CIME `parallel` selects these. `hpcl-cli185`: 20 × ~503 GB.

---

## 5. LandSim plan (new restart from Jinyun files)

TES_NORTH LandSim maps **AD restart → final/normal restart**. Jinyun’s analog:

```text
X (AD)      …ad.spinup.elm.r.0021-01-01-00000.nc
Y (target)  …rg.spinup.elm.r.0202-01-01-00000.nc   # only if the 47 MB file is complete
template    copy of elm.r.0021                     # AI overwrites CNP pools only
DATM        GSWP3 1901–1920
surf/params surfdata_0.5x0.5_50pfts_20250528.nc / clm_params_c251006.nc
```

Train a **new** CNP model. Do not load TES_NORTH `run_20260714_222907`.

### Phase 0 — close the bundle

1. Verify or recopy `rg.spinup` `0202`.
2. Copy matching **`elm.h0`** for AD `0021` and rg `0202` if LandSim_dataGEN still wants `DS2_PATH` / `H0_LIST_PATHS` (TES_NORTH did).
3. Optional: `elm.r.0166` only for the 15-node **ELM AD** case, not for LandSim.
4. Optional 10% cell mask (~9,500 of 94,838) for cheaper training.

### Phase 1 — LandSim_dataGEN PKLs

New config. Do not reuse TES_NORTH `CNP_dataInput_dw.txt` paths.

- `DATA_ROOT` → a new tree, e.g. `AI4ELM/AI_data/GSWP3_050_dataset/`
- `DS1_PATH` → `surfdata_0.5x0.5_50pfts_20250528.nc`
- `DS10_PATH` / X → AD `elm.r.0021`
- `R_LIST_PATHS` / Y → rg `elm.r.0202`
- `CLM_PARAMS_PATH` → `clm_params_c251006.nc`
- `DATM_ROOT` → GSWP3 v1, years **1901–1920**, `FORCING_MODE: datm`
- Extend `CNP_IO` if the TES_NORTH list omits crop / 50-PFT pools

Train on a 10% sample first; keep all 94,838 cells for inference. Same temporal reduction (monthly vs daily) at train and infer.

### Phase 2 — train

In `AI4BGC`: `train_cnp_model.py` on those PKLs (GPU). Check in-sample R² before full-grid inference.

### Phase 3 — infer and write `elm.r`

```bash
python scripts/update_restart_with_aiprediction.py \
  --variable-list CNP_IO_list.txt \
  --run-dir /path/to/cnp_results/run_… \
  --input-nc  $PF/input_data/ai4elm_spinup/AI_restart_files_Jinyun/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0021-01-01-00000.nc \
  --output-nc $PF/input_data/ai4elm_spinup/updated_restart_I1850GSWCNPRDCTCBCTOPPHSWFMCROP.elm.r.0021-01-01-00000.nc
```

CNP pools from the model; hydrology and other state stay from AD `0021`. Confirm `gridcell=94838`.

### Phase 4 — ELM after AI

New **finalspin** case (`spinup_state=0`, no `-bgc_spinup on`), `finidat` = the AI `elm.r.0021`. Same surfdata / params / GSWP3. First submit `CONTINUE_RUN=FALSE`. Later segments `CONTINUE_RUN=TRUE` (do not reset `finidat`).

The existing `ad0166_15node` case keeps **AD on** and is the wrong vehicle for an AI-updated normal-spinup restart.

If running the 15-node AD job anyway, retarget `finidat` to `elm.r.0021` or copy `0166` first.

---

## 6. Order of work

1. Verify/re-copy `rg.spinup` `0202`; get `h0` if LandSim_dataGEN needs it.
2. Do not submit `ad0166_15node` against missing `elm.r.0166`.
3. Build the GSWP3 0.5° LandSim bundle and PKLs.
4. Train → infer → write AI `elm.r.0021`.
5. Create a Pathfinder **finalspin** case that reads that AI restart.

**LandSim blocker:** Y file (`rg.spinup` 0202 quality) and likely missing `h0`.  
**15-node AD blocker:** `user_nl_elm` `finidat` path for `0166` does not exist on Pathfinder.

---

## 7. Do not mix

| Wrong | Why |
|---|---|
| TES_NORTH 4 km PKLs / `run_20260714_222907` on this mesh | `gridcell` 259535 vs 94838; different DATM, surfdata, params |
| Train monthly, infer daily | Scalers and series length will not match |
| Write AI pools into TES_NORTH `elm.r` and run this compset | Wrong PFT list and cell count |
| `CONTINUE_RUN` from Perlmutter `cpl.r` on 1920 ranks | Coupler restart is PE-specific (3072) |
| `ELM_FORCE_COLDSTART=on` with `finidat` | Cold start ignores the restart |
| f09 `ERA5_6hr_f09` forcing in this case | Wrong DATM product |
