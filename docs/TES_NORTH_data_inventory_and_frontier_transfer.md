# TES_NORTH data inventory and Frontier transfer

**Date:** 2026-09-14  
**Cases:** (1) full-domain TES_NORTH 4 km Daymet–ERA5; (2) 10% site subset used to train the CNP surrogate.  
**Purpose:** Record what lives on Pathfinder, what was copied to Frontier Orion, and how to repeat the copy.  
**This is not** the global f09 ERA5 spinup (`I1850ERACNPRDCTCBC` / `ERAf09`).

Related science/run docs:

- Full-domain baseline: [`TES_NORTH_baseline_on_pathfinder.md`](./TES_NORTH_baseline_on_pathfinder.md)
- Repeat AD/finalspin on a new machine: [`TES_NORTH_repeat_on_new_machine.md`](./TES_NORTH_repeat_on_new_machine.md)
- Resolution sizes: [`TES_NORTH_resolution_comparison.md`](./TES_NORTH_resolution_comparison.md)
- **Training and inference (10% → full domain):** [`TES_NORTH_training_and_inference_guide.md`](./TES_NORTH_training_and_inference_guide.md)

Repeatable copy scripts (run on Pathfinder, RSA passcode in a real terminal):

- `scripts/push_tesnorth_forcing_to_frontier.sh`
- `scripts/push_tesnorth_inference_bundle_to_frontier.sh`
- `scripts/push_tesnorth_10pct_bundle_to_frontier.sh`

Pin **one** DTN (`dtn101.ccs.ornl.gov` or `dtn102.ccs.ornl.gov`). Do not use `dtn.olcf.ornl.gov` or `frontier.olcf.ornl.gov` (load balancer / login pool; host keys rotate; SSH mux does not attach). DTN rsync is **3.1.3** — no `--mkpath`. Pathfinder rsync is 3.2.5.

---

## 1. The two cases

| | **Full domain** | **10% training subset** |
|---|---|---|
| Short name | TES_NORTH / `TES_NORTHERA5` / `uELM_NORTHERA5` | `TESNorthERA510PCT` / `ERA5_10PCTSITES` |
| Land cells | **259,535** | **25,954** (10% of the 1D land list) |
| Mesh | 4 km Daymet–ERA5, 1D compacted, 42–60°N, 119–64°W | Same mesh, stratified 10% of cells |
| ELM CNP | AD 20 yr → AI `0021` → finalspin | Same chain on the subset |
| AI role | Full-domain inference (`run_20260714_222907` applied to all cells) | **Training / in-sample test** for that model |
| Pathfinder data root | `kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH` plus `AI4ELM/.../ERA5_TESNORTH_inference` | `AI4ELM/.../TES_NORTH_dataset/ERA5_10PCTSITES` |
| Forcing on Pathfinder | Yes — monthly 3-hourly, 1980–2023 | **No** `forcing/` next to this bundle |
| Restart size (one `elm.r`) | 49 GB | 4.9 GB |

The CNP combined surrogate `run_20260714_222907` was trained on the 10% subset (Ruiheng PKLs on Perlmutter: `/pscratch/sd/r/ruihchen/tesnorth10pct/final_dataset`). Full-domain inference overfits that 10% (see the Chen compressed-restart README under `ERA5_TESNORTH_inference/AI_restartfile/`).

---

## 2. Pathfinder inventory

Prefix unless noted:

`PF=/projects/hpcl-cli185/proj-shared/wangd`

### 2.1 Full domain — DATM / ELM inputs

`PF/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain/`

| Path | What | Size (Pathfinder) |
|---|---|---|
| `forcing/Precip3Hrly/` | Monthly files, 3-hourly Prec | 1980–1999: 58 GiB (240 files); 1980–2023: 127 GiB |
| `forcing/Solar3Hrly/` | Monthly files, 3-hourly Solr | 1980–1999: 58 GiB; 1980–2023: 127 GiB |
| `forcing/TPHWL3Hrly/` | Monthly files, 3-hourly TPQWL | 1980–1999: 284 GiB; 1980–2023: 624 GiB |
| **`forcing/` spinup 1980–1999** | 720 NetCDF files | **~399 GiB / 428 GB** |
| `forcing/` full 1980–2023 | 1584 files | ~878 GiB |
| `atm_forcing.datm7.km.1d/` | DATM softlinks only | ~800 KB — **do not copy** |
| `domain_surfdata/domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc` | 1D domain | 28 MB; SHA256 `cfaffb0315dbe85d…7a284a` |
| `domain_surfdata/NORTHERA5_domain.lnd.…c251009.nc` | Symlink to the domain file | |
| `domain_surfdata/surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc` | As-run `fsurdat` | 76 MB |
| `domain_surfdata/NORTHERA5_surfdata.…c251009.nc` | **Not** the as-run surfdata | 35 MB |

Filenames: `climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.{Prec,Solr,TPQWL}.YYYY-MM.nc`.

Stock ELM params (not under kiloCraft):

`/projects/hpcl-cli185/world-shared/e3sm/inputdata/lnd/clm2/paramdata/`

| File | SHA256 | Size |
|---|---|---|
| `clm_params_c211124.nc` | `3876806bdaf2c432…91042e9` | 88 KB |
| `CNP_parameters_c180529.nc` | `fc9323002ef94cee…181357c` | 4.5 KB |

On Frontier those two already exist under  
`/lustre/orion/cli115/world-shared/e3sm/inputdata/lnd/clm2/paramdata/`.

### 2.2 Full domain — inference / 20-year restart bundle

`PF/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_TESNORTH_inference/`

| Path | What | Size |
|---|---|---|
| `history_restart_files/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC.elm.r.0021-01-01-00000.nc` | AD 20-year restart (inference **template**) | 49 GB |
| `history_restart_files/…elm.h0.0021-01-01-00000.nc` | Annual history at 0021 | 1.6 GB |
| `history_restart_files/clm_params_c211124.nc` | Copy of stock params | 88 KB |
| `domain_surfdata/NORTHERA5_domain.lnd.…c251009.nc` | Same domain as §2.1 | 28 MB |
| `domain_surfdata/surfdata.TESSFA_DOMAIN1.…NALCMS.c260218_yw.nc` | Same as-run surfdata | 76 MB |
| `AI_restartfile/updated_restart_normal_spinup_…elm.r.0021-01-01-00000.nc` | **AI-updated** restart (finalspin IC) | 49 GB |
| `AI_restartfile/AI_restartfromChen/…/restart/uELM_NORTHACCESS_TESNorth_AIrestart_compressed.elm.r.0021-01-01-00000.nc` | Chen compressed-pipeline restart | 50 GB |

The AD run directory also has the raw 0021 (and 0006 / 0011 / 0016):

`PF/kmELM/e3sm_runs/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC/run/`

Use **0021** for inference. The AI-updated file is inference **output**, not the template.

### 2.3 10% training subset

`PF/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_10PCTSITES/` (~16 GB)

LandSim configs (`AI4ELM/.../LandSim_dataGEN/config/CNP_dataInput_dw.txt`) set `DATA_ROOT` to this tree (legacy CADES path `/gpfs/wolf2/cades/cli185/proj-shared/wangd/AI_data/TES_NORTH_dataset/ERA5_10PCTSITES`).

| Path | What | Size |
|---|---|---|
| `history_restart_files/uELM_TESNorthERA510PCT_I1850CNPRDCTCBC.elm.r.0021-01-01-00000.nc` | 20-year AD restart | 4.9 GB; `gridcell=25954` |
| `history_restart_files/…elm.h0.0021-01-01-00000.nc` | AD history 0021 | 155 MB |
| `history_restart_files/uELM_TESNorthERA510PCT_I1850CNPRDCTCBC_finalspin.elm.r.1101-01-01-00000.nc` | Finalspin restart | 4.9 GB |
| `history_restart_files/…finalspin.elm.h0.1101-01-01-00000.nc` | Finalspin history | 155 MB |
| `history_restart_files/clm_params_c211124.nc` | Stock params copy | 88 KB |
| `domain_surfdata/TESNorthERA510PCT_domain.lnd.TES_NORTHERA5.4km.1d.c260303.nc` | 10% 1D domain (`ni=25954`) | 2.8 MB |
| `domain_surfdata/TESNorthERA510PCT_surfdata.TES_NORTHERA5.4km.1d.NLCD.c260303.nc` | 10% surfdata (NLCD stamp) | 224 MB |
| `AIrestart/updated_restart_AI_uELM_TESNorthERA510PCT_I1850CNPRDCTCBC.elm.r.0021-01-01-00000.nc` | AI-updated 10% restart | 4.9 GB |

There is **no** `forcing/` directory here. Training used DATM monthly files when they existed beside this tree (or monthly means already in the Perlmutter PKLs). Full-domain 3-hourly forcing is §2.1.

---

## 3. Intended Frontier layout

Root:

`/lustre/orion/cli115/world-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/`

```
Daymet_ERA5_TESSFA_NORTH/
  entire_domain/
    forcing/{Precip,Solar,TPHWL}3Hrly/     # 1980-1999 spinup (~400 GiB)
    domain_surfdata/                       # optional; also copied at TES_NORTH root
  domain_surfdata/                         # full-domain domain + surfdata (scp 2026-09-14)
  history_restart_files/                   # full-domain 0021 r/h0 + clm_params
  ERA5_10PCTSITES/                         # keep 10% separate (do not mix into history_restart_files/)
    history_restart_files/
    domain_surfdata/
    AIrestart/
```

Do **not** rsync the 10% `history_restart_files/` into the full-domain `history_restart_files/` folder.

---

## 4. Transfer history (Pathfinder → Frontier)

All copies: user `wangd`, Pathfinder `pflogin`, RSA PIN+token. Destination filesystem is Orion Lustre (`cli115` world-shared).

| When (EDT) | What | How | Host | Result |
|---|---|---|---|---|
| 2026-09-13 23:04–23:20 | Spinup forcing 1980–1999 | `BACKGROUND=1` + mux to `frontier.olcf.ornl.gov` then `dtn.olcf.ornl.gov` | LB DTN | **Failed.** Mux was Frontier, rsync was DTN; extra PASSCODE; `session request failed`. Host-key churn on `dtn.olcf.ornl.gov`. |
| 2026-09-13 23:32 | Same forcing | `scripts/push_tesnorth_forcing_to_frontier.sh` foreground, `DEST_HOST=dtn101.ccs.ornl.gov` | dtn101 | **Completed.** Log `entire_domain/scripts/push_tesnorth_forcing_frontier.spinup.20260913-233207.log`. Sent 394.6e9 bytes; total size 428.13e9 bytes; 724 items; ~37 MB/s. Dest: `.../entire_domain/forcing/`. |
| 2026-09-14 ~15:30 | Full-domain `entire_domain/domain_surfdata/` (5 files, ~230 MB) | manual `scp` | `dtn.ccs.ornl.gov` | **Completed.** Dest: `.../Daymet_ERA5_TESSFA_NORTH/domain_surfdata/`. (`dtn.olcf.ccs.ornl.gov` does not resolve.) |
| 2026-09-14 15:36 | Full-domain inference bundle | script with `--mkpath` | dtn101 | **Failed.** DTN rsync 3.1.3 has no `--mkpath`. |
| 2026-09-14 15:38– | Same bundle without `--mkpath` | `scripts/push_tesnorth_inference_bundle_to_frontier.sh` | dtn101 | **In progress** at doc time (~23% of ~51 GiB). Dest parent: `.../Daymet_ERA5_TESSFA_NORTH/` → `history_restart_files/` + `domain_surfdata/`. Re-run the same command to resume. |
| — | AI-updated 49 GB restart (`AI_restartfile/updated_restart_…`) | — | — | **Not copied.** |
| — | Chen 50 GB compressed restart | — | — | **Not copied.** |
| — | 10% `ERA5_10PCTSITES` bundle | `scripts/push_tesnorth_10pct_bundle_to_frontier.sh` | dtn101 | **Not started.** |

After the inference rsync finishes, confirm on Frontier:

```bash
# on a DTN or Frontier login
ROOT=/lustre/orion/cli115/world-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH
find "$ROOT/entire_domain/forcing" -name 'climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.*.nc' | wc -l
# expect 720 for 1980-1999
ls -lh "$ROOT/history_restart_files"
ls -lh "$ROOT/domain_surfdata"
```

---

## 5. How to repeat

From Pathfinder, interactive terminal (or `tmux` if the copy will outlive the window):

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM

# Full-domain spinup forcing (~400 GiB, 1980-1999)
DEST_HOST=dtn101.ccs.ornl.gov bash scripts/push_tesnorth_forcing_to_frontier.sh

# Full-domain 20-year restart + h0 + clm_params + domain/surfdata (~51 GiB)
DEST_HOST=dtn101.ccs.ornl.gov bash scripts/push_tesnorth_inference_bundle_to_frontier.sh

# 10% training bundle (~16 GiB) — writes ERA5_10PCTSITES/ so it does not mix with full-domain files
DEST_HOST=dtn101.ccs.ornl.gov bash scripts/push_tesnorth_10pct_bundle_to_frontier.sh
```

Optional: `MODE=test` on the forcing script copies 1980-01 only (~1.8 GiB). `MODE=full` is 1980–2023 (~878 GiB). `BACKGROUND=1` only if a ControlMaster **to that same DTN host** already accepts `BatchMode` slaves (usually it does not).

Globus is still the better tool for multi-hundred-GB copies. Source collection: Pathfinder path in §2. Dest: OLCF DTN / Orion path in §3.

---

## 6. Daily forcing note (AI dataset size)

DATM files are **3-hourly inside monthly NetCDF**, not 6-hourly global ERA5 (`ERA5_6hr_f09` is a different experiment). The current AI pipeline reduces those files to **monthly means**. Switching the reducer to **daily means** (8 three-hourly steps → 1 day) is ~30× more samples than monthly, without going back to raw ERA5. That daily product is **not** on disk yet; build it from `entire_domain/forcing/` if Ruiheng needs the larger TES_NORTH training set.
