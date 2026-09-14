# TES_NORTH resolution comparison: 4 km vs 2 km vs 1 km

**Date:** 2026-09-13  
**Domain:** TES_NORTH / `TES_NORTHERA5` (Daymet–ERA5, NALCMS surfdata, ELM CNP)  
**Purpose:** Head-to-head sizes and 20-year wall times so the group can pick the next resolution.  
**Machine assumed for run-time:** Pathfinder (`parallel` queue, 128 cores/node, 24 h max, **30 nodes max**).

**Recommendation:** **2 km is the appropriate next step on Pathfinder.** 4 km is the production baseline already running. Interpolated 1 km is doable but is a multi-week, multi-TB campaign and adds no new meteorology.

---

## 1. Decision in one page

| | **4 km (baseline)** | **2 km (next step)** | **1 km (stretch)** |
|---|---|---|---|
| Land cells | 259,535 | **1,038,140 (4×)** | **4,152,560 (16×)** |
| Parent 2D mesh | 1321 × 433 | 2642 × 866 | 5284 × 1732 |
| How 2 km / 1 km are built | As-run | Linear refine of 4 km domain / surfdata / forcing | Same method, 4×4 |
| Spinup forcing (1980–1999) | 0.4 TB | **1.6 TB** | **6.4 TB** |
| Full forcing archive (1980–2023) | 0.9 TB | 3.5 TB | 14 TB |
| One ELM restart | 49 GB | **196 GB** | **~0.8 TB** |
| 20 annual history files | 34 GB | 136 GB | 540 GB |
| Lean 20-yr output (1 restart + h0) | ~85 GB | **~330 GB** | **~1.4 TB** |
| 20-yr wall, 15 nodes (1920 tasks) | **15–19 h** (measured) | **~3.5–5 days** | **~12–15 days** |
| 20-yr wall, 30 nodes (3840 tasks) | not needed | **~1.5–2 days** | **~7–8 days** |
| Fits Pathfinder comfortably? | Yes (in production) | **Yes** | Tight (QOS, IO, 0.8 TB restarts) |
| New 2 km / 1 km science in the forcing? | Native 4 km Daymet–ERA5 | **No** — interpolated | **No** — interpolated |

2 km and 1 km here mean a **2×2 or 4×4 split of the existing 4 km TES_NORTH mesh**, with linear interpolation of forcing and continuous surfdata. They do **not** ingest native 1 km Daymet or remapped 1 km NALCMS. That would be a separate, larger project.

---

## 2. Mesh

The 4 km 1D land mesh is the Daymet / TESSFA North footprint inside 42–60°N, 119–64°W (~3.50 million km²). About 45% of the lon–lat bounding box is active land. Finer meshes keep that same footprint: every 4 km land cell becomes 4 children (2 km) or 16 children (1 km).

| Quantity | 4 km | 2 km | 1 km |
|---|---:|---:|---:|
| Nominal resolution | ~1/24° | ~1/48° | ~1/96° |
| Parent 2D (lon × lat) | 1321 × 433 | 2642 × 866 | 5284 × 1732 |
| Parent 2D cells | 571,993 | 2,287,972 | 9,151,888 |
| Active 1D land cells | **259,535** | **1,038,140** | **4,152,560** |
| Scale vs 4 km | 1× | 4× | 16× |
| Median cell area | ~13.6 km² | ~3.4 km² | ~0.85 km² |

MOSART is `NULL` in the as-run TES_NORTH cases. No 1 km / 2 km river network is required.

---

## 3. Input dataset size

4 km numbers are **measured** on Pathfinder  
(`…/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain`).  
2 km and 1 km are **4× and 16×** that layout (same 3-hourly monthly NetCDF, float32, `64bit_data`).

### 3.1 Domain and surface

| File | 4 km | 2 km | 1 km |
|---|---:|---:|---:|
| Domain (`domain.lnd.…1d`) | 28 MB | ~110 MB | ~450 MB |
| Surfdata (NALCMS, as-run) | 76 MB | ~300 MB | ~1.2 GB |

These are negligible next to forcing.

### 3.2 Atmospheric forcing (Daymet-downscaled ERA5)

Three streams: Prec, Solr, TPQWL (TBOT, QBOT, PSRF, FLDS, WIND). Monthly files, 3-hourly, 1D land mesh.

| Item | 4 km | 2 km | 1 km |
|---|---:|---:|---:|
| Prec monthly (Jan-class) | 251 MB | 1.0 GB | 4.0 GB |
| Solr monthly (Jan-class) | 251 MB | 1.0 GB | 4.0 GB |
| TPQWL monthly (Jan-class) | 1.3 GB | 5.2 GB | 21 GB |
| Prec archive 1980–2023 | 127 GB | 508 GB | 2.0 TB |
| Solr archive 1980–2023 | 127 GB | 508 GB | 2.0 TB |
| TPQWL archive 1980–2023 | 624 GB | 2.5 TB | 10.0 TB |
| **Full forcing 1980–2023** | **878 GB** | **3.5 TB** | **14.0 TB** |
| **Spinup cycle 1980–1999** | **~400 GB** | **~1.6 TB** | **~6.4 TB** |

Baseline cases cycle **1980–1999** only. Generate that first. 2000–2023 is needed only for a later transient.

TPQWL is ~70% of forcing volume. At 1 km a single month is ~21 GB; that is the DATM IO bottleneck.

### 3.3 Other ELM / DATM inputs

Stock E3SM files (parameters, N/P deposition, fire, 1850 aerosol, topo) stay on their coarse grids and are mapped onto the user mesh. They do **not** scale with resolution.

### 3.4 Input generation (one-time)

| Step | 4 km | 2 km | 1 km |
|---|---|---|---|
| Status | On disk | New refine scripts | New refine scripts |
| Domain + surfdata | — | minutes–2 h | minutes–2 h |
| Forcing 1980–1999 (Slurm array) | — | ~2–6 h on ~32 cores | ~4–12 h on ~32 cores |
| Forcing 1980–2023 | — | ~2× the 20-yr set | ~2× the 20-yr set |

---

## 4. Output dataset size (20-year run)

Assumes the same history as the 4 km baseline: annual `elm.h0` only (`hist_nhtfrq=-175200`, `hist_mfilt=1`). No hourly tapes.

| File | 4 km (measured) | 2 km | 1 km |
|---|---:|---:|---:|
| `elm.r` (one Jan-1 restart) | 49 GB | **196 GB** | **~780–800 GB** |
| `cpl.r` | 165 MB | ~660 MB | ~2.6 GB |
| `elm.h0` (one year) | 1.7 GB | 6.8 GB | 27 GB |
| 20 annual `h0` files | 34 GB | 136 GB | 540 GB |

**Working set** depends on how many restarts you keep:

| Keep | 4 km | 2 km | 1 km |
|---|---:|---:|---:|
| 1 restart + 20 `h0` (lean) | ~85 GB | **~330 GB** | **~1.4 TB** |
| 4 restarts (`REST_N=5`) + 20 `h0` | ~230 GB | ~920 GB | ~3.7 TB |
| 10 restarts (`REST_N=2`, current finalspin habit) | ~525 GB | ~2.1 TB | ~8.3 TB |

The current 4 km finalspin writes a 49 GB restart every 2 years. **Do not copy that habit at 1 km.** Prefer `REST_N=5` or `10` and delete older restarts after the next segment is verified.

---

## 5. Simulation time (20 years)

### 5.1 What was measured at 4 km

| Case | Layout | Cells / LND task | Observed rate | 20-year wall |
|---|---|---:|---|---|
| AD (spinup_state=1) | 840 LND, 84 MPI/node | 309 | ~1.8 h / year | **~36 h** (two jobs; 24 h cap) |
| Finalspin (normal BGC) | 1920 ATM/CPL/LND, 128 MPI/node, 15 nodes | 135 | **0.75–0.93 h / year** | **15–19 h** |

Throughput is about **160–170 cell-years per task-hour** for both AD and finalspin. 2 km / 1 km times below scale from that, then add IO (larger monthly TPQWL reads; larger restart writes).

### 5.2 Pathfinder limits (this is the constraint)

| Queue | Max nodes | Max MPI tasks | Memory / node | Max wall |
|---|---:|---:|---|---|
| `parallel` (NDR high-mem) | **30** | **3840** | ~2.2 TiB | 24 h |
| `hpcl-cli185` | 20 | 2560 | ~515 GB | 24 h |

TES_NORTH has already hit `QOSMaxCpuPerUserLimit` and `QOSMaxMemoryPerUser` on this machine. Treat 30 nodes as a **ceiling**, not a guarantee.

To keep the 4 km finalspin load (~135 cells/task) you would need ~60 nodes at 2 km and ~240 nodes at 1 km. **That does not fit Pathfinder.** Finer runs will have more work per task.

### 5.3 20-year wall time (normal BGC, annual history)

IO uplift applied on top of compute: **~25% at 2 km**, **~35% at 1 km**.

| Layout | 4 km | 2 km | 1 km |
|---|---|---|---|
| **15 nodes / 1920 tasks** (current finalspin) | **15–19 h measured** | **80–110 h (~3.5–5 days)** | **280–360 h (~12–15 days)** |
| **30 nodes / 3840 tasks** (Pathfinder max) | not needed | **38–50 h (~1.5–2 days)** | **160–200 h (~7–8 days)** |
| Cells / task at 30 nodes | — | ~270 (similar to 4 km AD) | ~1,080 (heavy) |
| 24 h job segments at 30 nodes | 1 | **2–3** | **7–9** |

AD 20-year times are in the same ballpark as the 30-node column (4 km AD was ~36 h at only 840 tasks). Budget the table above for either a 20-year AD or a 20-year normal run.

### 5.4 Memory

| | 4 km @ 1920 | 2 km @ 3840 | 1 km @ 3840 |
|---|---|---|---|
| Cells / task | 135 | ~270 | ~1,080 |
| Restart file | 49 GB | 196 GB | ~0.8 TB |
| Recommended nodes | `hpcl-cli185` or `parallel` | **`parallel` NDR (2.2 TiB)** | **`parallel` NDR only** |

1 km on `hpcl-cli185` (515 GB/node) is likely to OOM. If 1 km OOMs at 128 MPI/node, drop to 64 MPI/node (1920 tasks on 30 nodes) and accept the 15-node wall-time column.

---

## 6. Combined cost picture

| Cost item | 4 km | 2 km | 1 km |
|---|---:|---:|---:|
| New forcing to generate (1980–1999) | 0 (exists) | 1.6 TB | 6.4 TB |
| Lean 20-yr output | 0.09 TB | 0.33 TB | 1.4 TB |
| **Disk for one 20-yr experiment** | **~0.5 TB** | **~2.0 TB** | **~8 TB** |
| 20-yr wall @ 30 Pathfinder nodes | ~1 day (15 nodes is enough) | **~2 days** | **~1 week** |
| Restart write | easy (49 GB) | manageable (196 GB) | painful (~0.8 TB / write) |

Project filesystem currently has on the order of **285 TB free**, so disk quota is not the limiter. **Queue, wall-clock, and restart IO** are.

---

## 7. What interpolation does and does not buy

Proposed method for 2 km and 1 km:

1. **Domain:** exact 2×2 or 4×4 split of the 4 km land mask (not interpolation).
2. **Forcing:** scatter 1D → 2D, linear zoom, gather to the new 1D land list. Clip Prec/FSDS ≥ 0.
3. **Surfdata:** linear for continuous soils / hydrology / P pools; **nearest** for categorical fields (soil color/order, urban IDs). PFT fractions: nearest recommended; linear smears NALCMS.

Scientific caveats for peers:

- Forcing remains **4 km Daymet–ERA5 information**, just evaluated on a finer lattice.
- NALCMS vegetation is **4 km** unless we remap native 1 km NALCMS later.
- ELM will still compute on more columns (more hydrologic / biophysical degrees of freedom), so a resolution-sensitivity experiment is valid.
- This is **not** a native kilometer-scale meteorological product. Native Daymet 1 km already exists under `kiloCraft/NA_cases_data/` as a different project.

---

## 8. Recommendation

| If the goal is… | Choose |
|---|---|
| Continue the production TES_NORTH spinup / transient | **4 km** (already running; do not replace it) |
| Next resolution on Pathfinder this quarter | **2 km** |
| Stress-test IO / km-scale infrastructure, or Frontier campaign | **1 km** |
| True 1 km meteorology and land cover | Native Daymet 1 km + NALCMS remap (not this refine) |

**2 km** is the appropriate next resolution for this group on Pathfinder:

- 4× cells, still a **single ~200 GB restart** (not 0.8 TB).
- **1.6 TB** of spinup forcing — large but routine.
- **~2 days** of 24 h jobs on 30 NDR nodes for 20 years.
- Same scripts and QA path as 1 km, so 1 km remains a later option.

**1 km** is technically doable with the same interpolation path, but Pathfinder cannot keep cells/task constant, monthly TPQWL files are ~21 GB, and each restart is ~0.8 TB. Treat it as a follow-on after 2 km works, or move it to Frontier.

---

## 9. Sources and method

**Measured (4 km)**

- Domain / surfdata / forcing sizes: `kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain`
- Restart / history sizes: `kmELM/e3sm_runs/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC{,_finalspin}/run`
- AD and finalspin wall times: CaseStatus + restart timestamps (AD jobs 11892 / 12295; finalspin jobs 448042, 467648, 477999)
- Mesh and configuration: `docs/TES_NORTH_baseline_on_pathfinder.md`
- Pathfinder limits: `E3SM/cime_config/machines/config_batch.xml` (`nodemax=30` / `20`, `walltimemax=24:00:00`)

**Scaled (2 km, 1 km)**

- All land-cell-sized files ×4 or ×16.
- Wall time from ~165 cell-years per task-hour, then +25% (2 km) or +35% (1 km) for IO.
- 20-year estimates assume annual history only and 1980–1999 DATM cycling.

**Not included in the wall-time numbers:** queue wait, failed jobs, hourly history, writing every-2-year restarts, or generating 2000–2023 forcing.
