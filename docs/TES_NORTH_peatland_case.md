# TES_NORTH Minnesota peatland case (MNpeatlands2)

**Date:** 2026-09-16  
**Purpose:** Record the Pathfinder Minnesota peatland spinup so LandSim / AI4ELM
can reuse history, restart, surface, and parameter files. This is a TES_NORTH
4 km subset with peatland PFTs and a `topounit` dimension, not the 259,535-cell
TES_NORTHERA5 baseline.  
**Source notes:** [`peatland_case_data.txt`](./peatland_case_data.txt) (copied
from `AI4ELM/AI_data/TES_NORTH_dataset/peatland_case_data.txt`).

Related TES_NORTH docs:

- Full-domain 4 km baseline: [`TES_NORTH_baseline_on_pathfinder.md`](./TES_NORTH_baseline_on_pathfinder.md)
- Training / inference: [`TES_NORTH_training_and_inference_guide.md`](./TES_NORTH_training_and_inference_guide.md)

**This is not** the TES_NORTHERA5 259,535-cell case and **not** the global f09
ERA5 spinup. Do not mix `E3SM/` (TES_NORTH) with the peatland science tree.

---

## 1. Cases (Pathfinder, 2026-08-13)

| Stage | Case / run name | Compset | Role |
|---|---|---|---|
| AD spinup | `20260813_MNpeatlands2_ICB1850CNRDCTCBC_ad_spinup` | `ICB1850CNRDCTCBC` (CN, RD, CTC, BC; `spinup_state=1`) | Accelerated-decomposition cold start |
| Final spinup | `20260813_MNpeatlands2_ICB1850CNPRDCTCBC` | `ICB1850CNPRDCTCBC` (CNP, RD, CTC, BC; `spinup_state=0`) | Normal BGC from AD year-101 restart |

Run directories (history, restart, `surfdata.nc`, `domain.nc`, `clm_params.nc`,
`CNP_parameters.nc`):

```
/scratch/hpcl-cli185/zdr/e3sm_run/20260813_MNpeatlands2_ICB1850CNRDCTCBC_ad_spinup/run
/scratch/hpcl-cli185/zdr/e3sm_run/20260813_MNpeatlands2_ICB1850CNPRDCTCBC/run
```

CIME cases:

```
/scratch/hpcl-cli185/zdr/e3sm_cases/20260813_MNpeatlands2_ICB1850CNRDCTCBC_ad_spinup
/scratch/hpcl-cli185/zdr/e3sm_cases/20260813_MNpeatlands2_ICB1850CNPRDCTCBC
```

Science tree: `/projects/hpcl-cli185/proj-shared/zdr/E3SM-Peatlands`  
Machine: Pathfinder. Create used `--res f09_f09` then user domain + coupler
bypass (`SATM` + `metdata_type='era5-daymet'`), not `DATM_MODE=uELM_TES`.

A 20th-century transient case also exists
(`20260813_MNpeatlands2_ICB20TRCNPRDCTCBC`) but is not the training source in
the original notes.

---

## 2. Domain and surface

Parent 2D mesh is the same TES_NORTH 4 km rectangle (**1321 × 433**). The
peatland case keeps **17,850** land cells (`gridcell=17850`, domain `ni=17850`,
`nj=1`), not the 259,535-cell TES_NORTHERA5 land list.

| File in the run dir | Size | Notes |
|---|---|---|
| `surfdata.nc` | 739 MB | `topounit=4`, `lsmpft=natpft=22` |
| `domain.nc` | 2.0 MB | TES compacted 1D subset |
| `clm_params.nc` | 304 KB | peatland PFT names; `pft=30` in the file |
| `CNP_parameters.nc` | 4.5 KB | soil-order CNP |

`maxpatch_pft = 22`. List PFT names with:

```bash
ncdump clm_params.nc -v pftname
```

Active / peatland-relevant names (first 22 entries used with `natpft=22`):

| Index | `pftname` |
|---|---|
| 0 | `not_vegetated` |
| 1 | `needleleaf_evergreen_temperate_tree` |
| 2 | `upland_needleleaf_evergreen_boreal_tree` |
| 3 | `peatlnd_needleleaf_evergreen_boreal_tree` |
| 4 | `needleleaf_deciduous_boreal_tree` |
| 5 | `peatlnd_needleleaf_deciduous_boreal_tree` |
| 6–10 | tropical / temperate / boreal broadleaf trees (standard ELM names) |
| 11–12 | evergreen / temperate deciduous shrubs |
| 13 | `upland_broadleaf_deciduous_boreal_shrub` |
| 14 | `peatlnd_broadleaf_deciduous_boreal_shrub` |
| 15–17 | C3 arctic, C3 non-arctic, C4 grass |
| 18 | `moss` |
| 19 | `sedge` |
| 20–21 | `c3_crop`, `c3_irrigated` |

The param file continues through soybean (indices 22–29). Those extra crop PFTs
are not on the surface `natpft=22` axis.

Peatland ELM flags in `user_nl_elm`: `use_humhol=.true.`,
`use_shrub_moss_shading=.true.`, `obs_zwt_forcing=.false.`,
`metdata_bypass` under
`.../e3sm/inputdata/atm/datm7/Daymet_ERA5_TESSFA1/cpl_bypass_full/`.

---

## 3. Topounit fields to incorporate

Surface data have an extra **`topounit`** dimension (`topounit=4`). LandSim
data generation for this case must read these fields (and generally any
`(topounit, gridcell)` variable), not only the 1D TES_NORTH surfdata layout.

Required in the original notes:

```
double TopounitFracArea(topounit, gridcell) ;
    TopounitFracArea:long_name = "fractional area of topounits" ;
    TopounitFracArea:units = "unitless" ;
double TopounitAveElv(topounit, gridcell) ;
    TopounitAveElv:long_name = "average elevation of each topounit" ;
    TopounitAveElv:units = "m" ;
double TopounitLateralDist(topounit, gridcell) ;
    TopounitLateralDist:long_name = "lateral distance for each topounit" ;
    TopounitLateralDist:units = "m" ;
int TopounitIsBog(topounit, gridcell) ;
    TopounitIsBog:long_name = "topounit bog flag" ;
    TopounitIsBog:units = "1" ;
double TopounitPeatDepth(topounit, gridcell) ;
    TopounitPeatDepth:long_name = "topounit peat depth" ;
    TopounitPeatDepth:units = "m" ;
```

Also present on this `surfdata.nc` (keep if you copy the full topounit layout):

| Variable | Units / meaning |
|---|---|
| `TopounitRegionalTarget(topounit, gridcell)` | local topounit index for regional lateral GW |
| `TopounitTillKsat(topounit, gridcell)` | mm s⁻¹, till Ksat below peat |
| `MNTopounitLateralDistanceCap(topounit, gridcell)` | m |
| `MaxTopounitElv(gridcell)` | m |

Most soil / PFT / LAI fields on this file are also `(…, topounit, gridcell)`,
for example `PCT_NAT_PFT(natpft, topounit, gridcell)` and
`SOIL_COLOR(topounit, gridcell)`.

---

## 4. History and restarts (as of 2026-09-16)

Annual history: `hist_nhtfrq = -8760`, `hist_mfilt = 1` on two tapes
(`hist_dov2xy = .true.,.false.` → `h0` gridcell, `h1` not 2-D compacted).

| | AD | Final spinup |
|---|---|---|
| `STOP_N` (case XML) | 200 yr | 400 yr |
| `REST_N` | 20 yr | 20 yr |
| `elm.r` on disk | 0021, 0041, 0061, 0081, **0101** | 0021, 0041, 0061, 0081 |
| Last `h0`/`h1` | 0103 | 0100 |
| One `elm.r` | ~14 GB | ~14 GB |
| Run dir size | ~668 GB | ~703 GB |
| `finidat` | empty (cold start) | AD `elm.r.0101-01-01-00000.nc` |

Final spinup `finidat`:

```
/scratch/hpcl-cli185/zdr/e3sm_run/20260813_MNpeatlands2_ICB1850CNRDCTCBC_ad_spinup/run/20260813_MNpeatlands2_ICB1850CNRDCTCBC_ad_spinup.elm.r.0101-01-01-00000.nc
```

Scratch paths can be purged. If these run dirs disappear, recover from the
CIME case `DOUT_S` archive or recopy before using them as a LandSim bundle.
