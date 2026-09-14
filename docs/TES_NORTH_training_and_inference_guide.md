# TES_NORTH: new-user guide for training and inference

**Date:** 2026-09-14  
**Audience:** Someone who has not run the TES_NORTH CNP surrogate before and needs to (1) build a training set from the 10% sites, (2) train, (3) infer on the full 4 km domain, (4) write an ELM restart.  
**Data inventory and Frontier copies:** [`TES_NORTH_data_inventory_and_frontier_transfer.md`](./TES_NORTH_data_inventory_and_frontier_transfer.md).  
**ELM AD / finalspin (after you have an AI restart):** [`TES_NORTH_repeat_on_new_machine.md`](./TES_NORTH_repeat_on_new_machine.md).

This is **not** the global f09 ERA5 spinup. Do not mix `ERA5_6hr_f09` forcing into these configs.

---

## 0. What you are doing

```
10% ELM bundle          LandSim_dataGEN              LandSim / AI4BGC
(restart, surfdata,  →  training_data_batch_*.pkl  →  train CNP model
 clm_params, DATM)         (one row per land cell)       run_2026…/cnp_model.pt
                                                              │
full-domain bundle  ──────────────────────────────────────────┤
(259,535 cells)                                               ▼
                                                    infer every cell
                                                              │
                                                    update elm.r.0021
                                                              ▼
                                                    kmELM finalspin (finidat)
```

| Use | Dataset | Land cells | One `elm.r` |
|---|---|---|---|
| **Train** (and in-sample test) | `ERA5_10PCTSITES` | 25,954 | 4.9 GB |
| **Infer** (apply the model) | `ERA5_TESNORTH_inference` + full-domain DATM | 259,535 | 49 GB |
| Run ELM after AI | AI-updated `elm.r.0021` as `finidat` | 259,535 | 49 GB |

The published model `run_20260714_222907` was trained on the 10% set. It is strong **on those cells** and weaker on the other 90%. If you need a better full-domain restart, train with more cells or daily forcing (below), then infer again. Do not expect the 10% model to match ELM on the unseen 90% without that.

Code (not in this `kmELM` repo):

| Step | Repo | Typical clone |
|---|---|---|
| Build PKLs | [LandSim_dataGEN](https://github.com/daliwang/LandSim_dataGEN) | `AI4ELM/AI_data/LandSim_dataGEN` or `_h0_vectorized` |
| Train / infer / write restart | [LandSim](https://github.com/daliwang/LandSim) (AI4BGC) | `AI4ELM/AI_spinup/AI4BGC` |

---

## 1. Paths (Pathfinder)

`PF=/projects/hpcl-cli185/proj-shared/wangd`

After a Frontier copy, replace `PF/...` with  
`/lustre/orion/cli115/world-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/`  
(see the inventory doc §3). `CNP_parameters` on Frontier is already under  
`/lustre/orion/cli115/world-shared/e3sm/inputdata/lnd/clm2/paramdata/`.

### 1.1 Training (10%)

`T10=$PF/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_10PCTSITES`

| Config key | File |
|---|---|
| `DS1_PATH` (surfdata) | `$T10/domain_surfdata/TESNorthERA510PCT_surfdata.TES_NORTHERA5.4km.1d.NLCD.c260303.nc` |
| domain (if needed) | `$T10/domain_surfdata/TESNorthERA510PCT_domain.lnd.TES_NORTHERA5.4km.1d.c260303.nc` |
| `DS2_PATH` (AD h0) | `$T10/history_restart_files/uELM_TESNorthERA510PCT_I1850CNPRDCTCBC.elm.h0.0021-01-01-00000.nc` |
| `DS10_PATH` (AD restart X) | `$T10/history_restart_files/uELM_TESNorthERA510PCT_I1850CNPRDCTCBC.elm.r.0021-01-01-00000.nc` |
| `H0_LIST_PATHS` (target h0) | `$T10/history_restart_files/uELM_TESNorthERA510PCT_I1850CNPRDCTCBC_finalspin.elm.h0.1101-01-01-00000.nc` |
| `R_LIST_PATHS` (target Y) | `$T10/history_restart_files/uELM_TESNorthERA510PCT_I1850CNPRDCTCBC_finalspin.elm.r.1101-01-01-00000.nc` |
| `CLM_PARAMS_PATH` | `$T10/history_restart_files/clm_params_c211124.nc` |
| `DATM_ROOT` | **Not in `$T10`.** Point at full-domain forcing (next table). `A_index_core` maps the 10% cells onto that mesh by lat/lon. |

Worked LandSim_dataGEN config:  
`AI4ELM/AI_data/LandSim_dataGEN/config/CNP_dataInput_dw.txt`  
(set `DATA_ROOT` to `$T10`; keep `FORCING_MODE: datm`, years 1980–1999).

### 1.2 Inference (full domain)

`TFULL=$PF/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_TESNORTH_inference`  
`FORC=$PF/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain`

| Role | File |
|---|---|
| Surfdata | `$TFULL/domain_surfdata/surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc` |
| Domain | `$TFULL/domain_surfdata/NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc` |
| AD restart **template** | `$TFULL/history_restart_files/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC.elm.r.0021-01-01-00000.nc` |
| AD h0 | `$TFULL/history_restart_files/…elm.h0.0021-01-01-00000.nc` |
| `clm_params` | `$TFULL/history_restart_files/clm_params_c211124.nc` |
| DATM 3-hourly monthly | `$FORC/forcing/{Precip,Solar,TPHWL}3Hrly/` (spinup 1980–1999) |
| Pathfinder as-run AI `finidat` | `$TFULL/AI_restartfile/updated_restart_normal_spinup_uELM_NORTHERA5_ERA5REF_….elm.r.0021-01-01-00000.nc` |

Use the **AD 0021 template** as the NetCDF you write predictions into. The `updated_restart_normal_spinup_…` file is an already-written AI restart (TES_NORTHERA5 finalspin IC). The Chen 50 GB file under `AI_restartfromChen/` is a **different** compressed-I/O inference product; skip it unless you are reproducing that IPDPS pipeline.

---

## 2. Build the training PKLs (10%)

On a machine that can see `$T10` and the full-domain `forcing/` (Pathfinder, Frontier, or Perlmutter after copy).

```bash
cd /path/to/LandSim_dataGEN   # or LandSim_dataGEN_h0_vectorized
cp config/CNP_dataInput_dw.txt config/CNP_dataInput_tesnorth10.txt
```

Edit `CNP_dataInput_tesnorth10.txt`:

- `DATA_ROOT:` `$T10`
- `DATM_ROOT:` `$FORC/forcing` (or `$FORC` if your scanner expects `clmforc.*` under `atm_forcing.datm7.km.1d/` — then rebuild those softlinks with `NORTHERA5_softlink_creation.py` from `entire_domain/`)
- `FORCING_MODE: datm`
- `DATM_START_YEAR: 1980` / `DATM_END_YEAR: 1999`
- tokens: Prec, Solr, TPQWL as in `CNP_dataInput_dw.txt`
- `BASE_OUTPUT_ROOT:` a scratch directory you own
- `TIME_SERIES_LENGTH: 58400` (20 yr × 365 × 8 three-hourly steps) if you ingest 3-hourly and then average
- `YEARS_IN_DATA: 20`

```bash
python3 scripts/run_extraction.py --build all --forcing-mode datm \
  --config-input config/CNP_dataInput_tesnorth10.txt
python3 scripts/run_assembly.py --config-input config/CNP_dataInput_tesnorth10.txt
python3 scripts/validate_final_dataset.py --config-input config/CNP_dataInput_tesnorth10.txt
```

Output: `$BASE_OUTPUT_ROOT/final_dataset/training_data_batch_*.pkl`  
(one batch ≈ `BATCH_SIZE` cells; 25,954 cells → about 13 files at 2000/batch).

**Default forcing reduction is monthly means** (240 steps for 20 years). That is what `run_20260714_222907` used. For a ~30× larger series (training **and** inference), average the same 3-hourly files **by day** instead of by month (8 steps → 1 day, ~7,300 steps). That is a small change in the DATM preprocessor (`_monthly_mean_series_from_datm_files` → group by calendar day). You do **not** re-download ERA5 or convert 6-hourly global files. Daily files are not on disk yet; they are derived from `$FORC/forcing/`.

If PKLs already exist (Perlmutter: `/pscratch/sd/r/ruihchen/tesnorth10pct/final_dataset`), you can skip this stage and train from those files.

---

## 3. Train the CNP model

```bash
cd /path/to/LandSim    # AI4BGC / LandSim
# point the CNP_IO list data_paths at final_dataset/
python train_cnp_model.py \
  --variable-list CNP_IO_list.txt \
  --output-dir cnp_results \
  --epochs 100 \
  --batch-size 128
```

Details: `AI4ELM/AI_spinup/AI4BGC/docs/CNP_pipeline_runbook.md` and `docs/README_CNP_Model_Workflow.md`.

You need a GPU node (Perlmutter GPU, Frontier GPU, or equivalent). Each run writes `cnp_results/run_YYYYMMDD_HHMMSS/` with `cnp_model.pt`, scalers, and test predictions.

Check in-sample quality before inferring the full domain:

```bash
cd cnp_results/run_YYYYMMDD_HHMMSS
python ../../scripts/cnp_result_validationplot.py --stats-only
python ../../scripts/generate_prediction_quality_report.py
```

On the 10% test split, `run_20260714_222907` was about median R² 0.99. If your new run is far below that, stop and fix data alignment (lat/lon, PFT mask, forcing length) before full-domain inference.

---

## 4. Infer on the full domain

Build **full-domain** PKLs or a compressed-nc loader the same way as §2, but with `$TFULL` surfdata + AD `0021` restart and `$FORC` DATM. Same `FORCING_MODE` and the **same temporal reduction** as training (monthly with monthly, daily with daily). Mixing monthly-trained weights with daily inference (or the reverse) is wrong.

Then, from the training run directory:

```bash
python ../../scripts/run_inference_all.py --inference-full-grid
# or shard: --num-shards 4
```

Write predictions into the AD template (example from the Chen package; adjust paths):

```bash
python scripts/update_restart_with_aiprediction.py \
  --variable-list CNP_IO_list.txt \
  --run-dir /path/to/cnp_results/run_… \
  --input-nc $TFULL/history_restart_files/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC.elm.r.0021-01-01-00000.nc \
  --output-nc /path/to/updated_restart_…elm.r.0021-01-01-00000.nc
```

Only CNP pool fields are overwritten; hydrology and other restart state stay from the AD file. Confirm `gridcell=259535` on the output.

Optional linear recalibration (Chen workflow) if raw pools are out of ELM range: `scripts/calibrate.py` in that package. Recalibration uses the existing ELM restart as a scale reference; it does not add spatial skill.

---

## 5. Use the AI restart in ELM

Point TES_NORTHERA5 **finalspin** `finidat` at the file from §4 (or at the Pathfinder as-run `updated_restart_normal_spinup_uELM_NORTHERA5_ERA5REF_…` if you are reproducing the baseline, not a new model).

Playbook: [`TES_NORTH_repeat_on_new_machine.md`](./TES_NORTH_repeat_on_new_machine.md).

- First finalspin submit: `CONTINUE_RUN=FALSE`, `RUN_STARTDATE=0401-01-01`, `spinup_state=0`.
- Later segments: `CONTINUE_RUN=TRUE`; do not reset `finidat`.
- Same domain, NALCMS surfdata, and `clm_params_c211124.nc` as the template.

---

## 6. Do not mix

| Wrong | Why |
|---|---|
| Train on 10% PKLs, infer with 6-hourly `ERA5_6hr_f09` | Different grid and DATM product |
| Train monthly, infer daily (or the reverse) | Forcing length and scalers will not match |
| Write AI pools into the 10% restart and run full-domain ELM | `gridcell` 25954 vs 259535 |
| Use Chen `uELM_NORTHACCESS_TESNorth_AIrestart_compressed.elm.r` as the TES_NORTHERA5 baseline `finidat` | Different write path; baseline finalspin uses `updated_restart_normal_spinup_uELM_NORTHERA5_ERA5REF_…` |
| Copy 10% `history_restart_files/` into the full-domain folder of the same name | File names collide; keep `ERA5_10PCTSITES/` separate |

---

## 7. Checklist

- [ ] 10% surfdata + AD `0021` + finalspin `1101` + `clm_params` readable
- [ ] Full-domain 1980–1999 DATM visible (`720` monthly 3-hourly files)
- [ ] LandSim_dataGEN config `DATA_ROOT` / `DATM_ROOT` point at those trees
- [ ] PKLs validate (row count ≈ 25,954; forcing length 240 monthly or ~7,300 daily)
- [ ] CNP training run directory has `cnp_model.pt` and scalers
- [ ] Full-domain inference used the **same** forcing reduction as training
- [ ] Output restart `gridcell=259535`; CNP fields finite; other fields copied from AD `0021`
- [ ] Finalspin `finidat` is that restart; domain/surfdata/params match TES_NORTHERA5
