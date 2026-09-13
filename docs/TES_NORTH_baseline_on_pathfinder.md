# TES_NORTH baseline on Pathfinder (4 km Daymet–ERA5)

**Date:** 2026-09-13  
**Purpose:** Record the TES_NORTH domain, forcing, surface dataset, ELM
parameters, and the AI-restart → finalspin continue-run procedure so the same
simulation can be repeated and so an agent knows what to do next (transient).  
**Experiment name:** `TES_NORTHERA5` / `uELM_NORTHERA5`  
**This is not** the global f09 ERA5 spinup (`I1850ERACNPRDCTCBC` / `ERAf09`).

Companion notes:

- Source-tree split (TES vs ERA5 f09): [`e3sm_source_trees.md`](./e3sm_source_trees.md)
- Pathfinder create scripts: [`case_gene/PathFinder/TES_NORTHERA5/README.md`](../case_gene/PathFinder/TES_NORTHERA5/README.md)
- Continue-run / transient handoff: §7 and §8 below

---

## 1. What to reproduce

The Pathfinder chain is **AD → AI-updated 0021 restart → finalspin continue runs → transient**.
Two cases exist today; the transient case is **not created yet**.

| Stage | Case name | Role |
|---|---|---|
| AD spinup | `uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC` | 20-year accelerated-decomposition cold start (`0001`–`0021`) |
| AI inference | (data product, not a CIME case) | Overwrites CNP pools in the AD `0021` restart |
| Finalspin continue | `uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC_finalspin` | Normal BGC from that AI restart; **continue runs** write 2-year restarts for transient |
| Transient (next) | *not created* | Historical / transit run; `finidat` = a finalspin `elm.r.YYYY-01-01` |

Create scripts that match the AD and first finalspin settings:

- `case_gene/PathFinder/TES_NORTHERA5/TES_NORTHERA5_ref.sh`
- `case_gene/PathFinder/TES_NORTHERA5/TES_NORTHERA5_finalspin_ref.sh`

On Pathfinder the cases live under
`${KMELM_ROOT}/e3sm_cases/` and the runs under `${KMELM_ROOT}/e3sm_runs/`.
The AD case was created 2026-04-30 and submitted 2026-06-10 (job `11892`).

---

## 2. Model configuration

| Item | Value |
|---|---|
| Compset alias | `I1850CNPRDCTCBC` |
| Compset long name | `1850_DATM%QIA_ELM%CNPRDCTCBC_SICE_SOCN_MOSART_SGLC_SWAV_SIAC_SESP` |
| Resolution | `ELM_USRDAT` (user domain for ATM and LND) |
| DATM mode | **`uELM_TES`** (set after `create_newcase`; do not leave `%QIA`) |
| Driver | MCT (`COMP_INTERFACE=mct`) |
| BGC | ELM CNP, RD nutrient competition, CTC soil decomp, methane |
| `ELM_BLDNML_OPTS` (AD) | `-bgc bgc -nutrient cnp -nutrient_comp_pathway rd -soil_decomp ctc -methane -bgc_spinup on` |
| `ELM_BLDNML_OPTS` (finalspin) | `-bgc bgc -nutrient cnp -nutrient_comp_pathway rd -soil_decomp ctc -methane` |
| Coupling | `ATM_NCPL=24` → ELM `dtime=3600` s |
| Forcing cycle | DATM years **1980–1999**, align **1990** |
| CO2 | constant **284.7** ppm |
| PIO | `pnetcdf`, `64bit_data` |

E3SM source: `${KMELM_ROOT}/E3SM` (not `E3SM-era5`). The science tree needs
`DATM_MODE=uELM_TES` streams. `TESSFA_4km` also has the
`I1850uELMTESCNPRDCTCBC` alias; the baseline `_ref` scripts use stock
`I1850CNPRDCTCBC` plus `DATM_MODE=uELM_TES` and can run on a fork `master`
that already has Pathfinder machine files.

---

## 3. Domain

**File (as-run):**
`NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc`  
→ symlink to `domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc`

**Path (Pathfinder):**
`/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain/domain_surfdata/`

**SHA256:**
`cfaffb0315dbe85d1346b504d0c4f586322f8d6a23d42b4a61bcb3b4767a284a`

| Quantity | Value |
|---|---|
| Nominal resolution | 4 km (`~1/24°`, Δlon ≈ Δlat ≈ 0.04167°) |
| Parent 2D mesh | **1321 × 433** (lon × lat) = 571,993 cells |
| Active 1D land cells | **259,535** (`ni=259535`, `nj=1`; all `mask=1`, `frac=1`) |
| Geographic box | **42–60°N**, **119–64°W** |
| Box size | ~18° × 55°, about 1,950 km × 3,770 km |
| Land area (from cell vertices) | about **3.50 million km²** |
| Cell area | ~10.7 km² (north) to ~15.8 km² (south); median ~13.6 km² |

The 1D file is the land-only subset of the lon-lat rectangle. About **45%** of
the parent 2D mesh is kept. That 45% is “has Daymet/TES forcing,” not “land
fraction of North America in the box.”

The valid land sits in a **NW–SE band** (Daymet / TESSFA North footprint)
inside the rectangle. The unused 55% is mostly empty corners of that bounding
box, plus water inside the footprint:

- SW corner (119–110°W, 42–47°N) is **0%** in the mask even though it is land
  on Earth (Idaho / Montana / Wyoming). Those cells are outside the TES North
  footprint.
- NE corner (75–64°W, 55–60°N) is empty (Hudson Bay / Labrador / Atlantic).
- Water inside the footprint includes Hudson/James Bay, Great Lakes, and the
  Gulf of St. Lawrence.
- The box does **not** reach the Pacific (west edge is 119°W).

The 1D domain is built by keeping 2D forcing cells where `FSDS` is valid
(see `kiloCraft/TES_inputGEN/TES_NORTH/data_generation_access/TES_domainGEN_NORTHACCESS.py`).
`gridID` is the 0-based index on the flattened 1321 × 433 parent (`gridID =
gridXID + gridYID * 1321`). DATM also uses a copy of this file named
`domain.lnd.Daymet.km.1d.nc` under `atm_forcing.datm7.km.1d/`.

`area` in the domain file is stored as `arcad^2` (steradian-like
`(dLon/180)*(dLat/180)`). Do not treat those values as km².

---

## 4. Atmospheric forcing

Product: **Daymet-downscaled ERA5** for TESSFA North, compacted to the 1D land
mesh. Source 2D files (CADES) were under
`.../e3sm/inputdata/atm/datm7/Daymet_ERA5_TESSFA1/{Precip,TPHWL,Solar}3Hrly`.
The 1D generator is
`kiloCraft/TES_inputGEN/TES_NORTH/data_generation_era5/TES_forcingGEN_NORTHERA5.py`.

**Root (Pathfinder):**
`/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH/entire_domain`

| Directory | Role |
|---|---|
| `forcing/Precip3Hrly/` | Real monthly NetCDF (`climforc.Daymet_ERA5_TESSFA_NORTH.4km.1d.Prec.YYYY-MM.nc`) |
| `forcing/Solar3Hrly/` | Same pattern, variable token `Solr` |
| `forcing/TPHWL3Hrly/` | Same pattern, variable token `TPQWL` |
| `atm_forcing.datm7.km.1d/` | DATM view: softlinks named `clmforc.Daymet.km.1d.<var>.YYYY-MM.nc` |

Rebuild the DATM links after a copy with
`kiloCraft/TES_inputGEN/TES_NORTH/data_generation_era5/NORTHERA5_softlink_creation.py`
(run from `entire_domain/`). It also links
`atm_forcing.datm7.km.1d/domain.lnd.Daymet.km.1d.nc` → the 1D domain file.

### Archive vs what DATM cycles

The archive on disk is **1980–2023** (44 years × 12 months × 3 streams = **1584**
files, about **878 GB**):

| Stream | Files | Size | Variable(s) |
|---|---|---|---|
| Prec | 528 | ~127 GB | `PRECTmms` (mm H2O s⁻¹) |
| Solr | 528 | ~127 GB | `FSDS` (W m⁻²) |
| TPQWL | 528 | ~624 GB | `TBOT` (K), `QBOT` (kg kg⁻¹), `PSRF` (Pa), `FLDS` (W m⁻²), `WIND` (m s⁻¹) |

The baseline cases **cycle only 1980–1999** (`DATM_CLMNCEP_YR_START=1980`,
`YR_END=1999`, `YR_ALIGN=1990`). That is 240 months × 3 streams. Copying
2000–2023 is optional for this spinup.

Each monthly file is 3-hourly on the 1D mesh (`time`, `nj=1`, `ni=259535`).
January 1980 has 248 steps (31 × 8). Time units are
`days since <yyyy>-<mm>-01 00:00:00`; the first stamp is 0.0625 d (01:30).
A 232-step month is treated as a leap-day file and trimmed to 224 by the
generator.

January 1980 file sizes (for planning a copy): Prec ~263 MB, Solr ~263 MB,
TPQWL ~1.3 GB.

### DATM streams (`DATM_MODE=uELM_TES`)

Defined in `E3SM/components/data_comps/datm/cime_config/namelist_definition_datm.xml`.
As-run `datm_in` uses five streams:

| Stream | Years | `tintalgo` | `mapalgo` |
|---|---|---|---|
| `uELM_TES.Prec` | 1990 1980 1999 | nearest | copy |
| `uELM_TES.Solr` | 1990 1980 1999 | coszen | copy |
| `uELM_TES.TPQWL` | 1990 1980 1999 | linear | copy |
| `presaero.clim_1850` | 1 1 1 | linear | bilinear |
| `topo.observed` | 1 1 1 | lower | bilinear |

Field maps (file variable → DATM):

| File | DATM |
|---|---|
| `PRECTmms` | `precn` |
| `FSDS` | `swdn` |
| `TBOT` | `tbot` |
| `QBOT` | `shum` |
| `PSRF` | `pbot` |
| `FLDS` | `lwdn` |
| `WIND` | `wind` |

Expected filenames under `$DIN_LOC_ROOT_CLMFORC/atm_forcing.datm7.km.1d`:

```
clmforc.Daymet.km.1d.Prec.%ym.nc
clmforc.Daymet.km.1d.Solr.%ym.nc
clmforc.Daymet.km.1d.TPQWL.%ym.nc
domain.lnd.Daymet.km.1d.nc
```

`datamode = CLMNCEP`. Forcing and ELM share the same 1D domain (`mapalgo=copy`
on the TES streams).

---

## 5. Surface dataset

**Baseline file (as-run, both AD and finalspin):**
`surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc` (76 MB)

**SHA256:**
`0f9b46c8647f0f8b1f96ff908379bc9492fb04412f3404c7abf774b7a7aa60bf`

Same directory as the domain file. The name records TESSFA Domain 1, **NALCMS**
(North American Land Change Monitoring System) vegetation, and the 2026-02-18
`_yw` processing.

Do **not** use the older
`NORTHERA5_surfdata.TES_NORTHERA5.4km.1d.c251009.nc` for this baseline.

| Dimension | Size |
|---|---|
| `gridcell` | 259535 (aligned with the 1D domain) |
| `lon` / `lat` | 1321 / 433 (parent 2D) |
| `natpft` / `lsmpft` | 17 |
| `nlevsoi` | 10 |
| `time` (monthly LAI/SAI/height) | 12 |
| `numurbl` | 3 |

Mean landunit fractions on the 1D mesh:

| Field | Mean (%) |
|---|---|
| `PCT_NATVEG` | 86.1 |
| `PCT_LAKE` | 13.4 |
| `PCT_URBAN` (sum of 3 densities) | 0.49 |
| `PCT_CROP` (crop landunit) | 0 |
| `PCT_WETLAND` | 0 |
| `PCT_GLACIER` | 0 |

Crops are on the natural-veg landunit (`PCT_NAT_PFT` index 15), not a separate
crop landunit (`create_crop_landunit = .false.`).

Mean `PCT_NAT_PFT` (percent of the natural-veg landunit):

| PFT | Mean % | Cells with PFT > 0 |
|---|---|---|
| 0 bare | 5.3 | 60,826 |
| 1 NET temperate | 0.8 | 33,679 |
| **2 NET boreal** | **41.8** | 241,617 |
| 7 BDT temperate | 0.1 | 9,402 |
| **8 BDT boreal** | **14.5** | 204,238 |
| 10 BDS temperate | 0.03 | 9,923 |
| **11 BDS boreal** | **10.0** | 241,154 |
| 12 C3 arctic grass | 7.2 | 180,283 |
| 13 C3 grass | 4.8 | 221,638 |
| 14 C4 grass | 0.1 | 30,183 |
| **15 crop** | **15.4** | 84,970 |

The domain is boreal forest (NET/BDT/BDS boreal) with crop and grass in the
south. Tropical PFTs and NDT boreal are absent.

Other fields required by ELM CNP: soil sand/clay/organic (`nlevsoi=10`),
`SOIL_COLOR`, `SOIL_ORDER`, `FMAX`, monthly LAI/SAI/height, urban parameters,
peat/GDP/fire month, slope and elevation stats, lake depth, CH4 inundation
parameters, and soil P pools (`APATITE_P`, `LABILE_P`, `OCCLUDED_P`,
`SECONDARY_P`) plus `pH`.

Global attributes still show a CLM4 `mksurfdata_map` heritage (360×720
template, 1850 land-use `AA_mksrf_landuse_rc_1850_06062017.nc`). The 4 km
NALCMS PFT overlay is what TES_NORTH actually uses.

`AREA` on this file has units `km^2` in the header but the values match the
domain `arcad^2` field. Use vertex-based area (~3.50 Mkm²) if you need km².

---

## 6. ELM / CLM parameters and other inputdata

These are stock E3SM files under `DIN_LOC_ROOT`. On Pathfinder that root is
**`/projects/hpcl-cli185/world-shared/e3sm`** (the parent of `e3sm/inputdata`).
ELM then reads `$DIN_LOC_ROOT/lnd/clm2/...` and `$DIN_LOC_ROOT/atm/...`.
Point `DIN_LOC_ROOT` at a tree that contains the same relative paths.

### Land parameter files (from as-run `lnd_in`)

| Namelist | File | SHA256 (first 16 hex) |
|---|---|---|
| `paramfile` | `lnd/clm2/paramdata/clm_params_c211124.nc` | `3876806bdaf2c432` |
| `fsoilordercon` | `lnd/clm2/paramdata/CNP_parameters_c180529.nc` | `fc9323002ef94cee` |
| `fsnowoptics` | `lnd/clm2/snicardata/snicar_optics_5bnd_mam_c160322.nc` | |
| `fsnowaging` | `lnd/clm2/snicardata/snicar_drdt_bst_fit_60_c070416.nc` | |
| `fsurdat` | TES surfdata above | `0f9b46c8647f0f8b` |
| `fatmlndfrc` | TES 1D domain above | `cfaffb0315dbe85d` |
| `finidat` (AD) | empty (cold start) | |
| `finidat` (finalspin) | AI restart, see below | |

Full SHA256 for the two parameter files:

```
3876806bdaf2c432dde41db748b139b962068f6c1b0a1c86324c60eaf91042e9  clm_params_c211124.nc
fc9323002ef94ceeb480f1f9b97b1a876a29667f076197c3e1c49216b181357c  CNP_parameters_c180529.nc
```

### Streams (1850 control)

| Stream | File under `DIN_LOC_ROOT` | Years used |
|---|---|---|
| N deposition | `lnd/clm2/ndepdata/fndep_elm_cbgc_exp_simyr1849-2101_1.9x2.5_ssp245_c240903.nc` | 1850–1850 |
| P deposition | `lnd/clm2/pdepdata/fpdep_clm_hist_simyr2000_1.9x2.5_c150929.nc` | 2000–2000 |
| Population density | `lnd/clm2/firedata/elmforc.Li_20181205_mod_hist_SSP2_CMIP6_hdm_0.5x0.5_AVHRR_simyr1850-2100_c240906.nc` | 1850–1850 |
| Lightning | `atm/datm7/NASA_LIS/clmforc.Li_2012_climo1995-2011.T62.lnfm_Total_c140423.nc` | 0001–0001 |
| Prescribed aerosol (1850 clim) | `atm/cam/chem/trop_mozart_aero/aero/aerosoldep_monthly_1850_mean_1.9x2.5_c090421.nc` | climatology |
| Topography (DATM) | `atm/datm7/topo_forcing/topodata_0.9x1.25_USGS_070110_stream_c151201.nc` | climatology |

Ndep/pdep/popdens use `bilinear` mapping from their coarse grids onto the 4 km
mesh.

### As-run ELM science flags

Shared by AD and finalspin unless noted:

| Flag | AD | Finalspin |
|---|---|---|
| `use_cn` | true | true |
| `use_crop` | false | false |
| `use_fates` | false | false |
| `use_vertsoilc` | true | true |
| `use_lch4` | true | true |
| `use_century_decomp` | false (CTC) | false |
| `use_snicar_ad` | true | true |
| `nu_com` | `RD` | `RD` |
| `suplnitro` | `NONE` | `NONE` |
| `suplphos` | **`ALL`** | **`NONE`** |
| `spinup_state` | **1** | **0** |
| `nyears_ad_carbon_only` | 25 | (unset) |
| `spinup_mortality_factor` | 10 | (unset) |
| `ELM_ACCELERATED_SPINUP` | on | off |
| `ELM_FORCE_COLDSTART` | on | off |
| `maxpatch_pft` | 17 | 17 |
| `maxpatch_glcmec` | 0 | 0 |
| `urban_hac` | ON | ON |

History (both): `hist_dov2xy = .true.,.true.`, `hist_nhtfrq = -175200`,
`hist_mfilt = 1` (one annual history file). Hourly `hist_fincl2` is commented
out in the AD namelist.

---

## 7. Run segments and PE layout (Pathfinder as-run)

| | AD | Finalspin |
|---|---|---|
| `RUN_TYPE` | startup | startup |
| `RUN_STARTDATE` | 0001-01-01 | **0401-01-01** |
| `STOP_N` / `STOP_OPTION` | 20 / nyears | 10 / nyears |
| `REST_N` | 5 | 2 |
| Wall clock | 24 h | 12 h |
| Queue | `parallel` | `hpcl-cli185` |
| LND tasks | **840** | **1920** |
| ATM tasks | 50 | 1920 |
| CPL tasks | 1 | 1920 |
| MPI / node | 84 | 128 |

Scale the PE layout to the target machine. 259,535 land cells / 840 LND tasks
is about 309 cells per task on the AD layout.

### Finalspin initial condition (first segment only)

The first finalspin submit is a **startup** from the **AI-updated** AD year-0021
restart, with the model clock set to `0401-01-01` (same convention as a
conventional final spin that would have used an AD `0401` file):

```
/projects/hpcl-cli185/proj-shared/wangd/AI4ELM/AI_data/TES_NORTH_dataset/ERA5_TESNORTH_inference/AI_restartfile/updated_restart_normal_spinup_uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC.elm.r.0021-01-01-00000.nc
```

That file is a drop-in ELM restart (49 GB, `gridcell=259535`). AI inference
replaced the CNP vegetation/soil pools on the AD `0021` template; other
restart fields were copied. `user_nl_elm` still lists this `finidat`, but
**after the first successful segment CIME ignore it**: later submits use
`CONTINUE_RUN=TRUE` and the `rpointer.*` files in the run directory.

Do **not** point `finidat` at the raw AD
`…/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC/run/…elm.r.0021-01-01-00000.nc`
for this baseline. That is the pre-AI file. There is no AD `0401` restart on
Pathfinder (AD stopped at `0021`).

---

## 8. AI restart → continue runs → transient (agent playbook)

This is the procedure an agent should follow. The finalspin case is **already
built**. Do not run `TES_NORTHERA5_finalspin_ref.sh` again unless the user
sets `FORCE_RECREATE=1` and intends to wipe it.

```
AD 20 yr (0001–0021, cold start, spinup_state=1)
        │
        ▼
AI updates elm.r.0021  →  updated_restart_normal_spinup_…elm.r.0021-01-01-00000.nc
        │
        ▼
finalspin first submit   CONTINUE_RUN=FALSE   finidat=AI file   RUN_STARTDATE=0401-01-01
        │
        ▼
finalspin continue       CONTINUE_RUN=TRUE    rpointer.lnd / rpointer.drv
        │                 STOP_N=10 nyears, REST_N=2 nyears
        │                 writes …elm.r.04xx-01-01-00000.nc (~49 GB each)
        ▼
transient (next case)    finidat = a Jan-1 finalspin elm.r  (plus matching cpl.r if hybrid/branch)
                         DATM can use 1980–2023; spinup cycled 1980–1999 only
```

### 8.1 First finalspin segment (already done)

Case:
`${KMELM_ROOT}/e3sm_cases/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC_finalspin`

Run:
`${KMELM_ROOT}/e3sm_runs/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC_finalspin/run`

Settings that must stay true for every finalspin segment:

- `ELM_ACCELERATED_SPINUP=off`, `spinup_state=0`, `suplphos='NONE'`
- Same domain, surfdata, `DATM_MODE=uELM_TES`, DATM cycle 1980–1999
- PE as-run: 1920 ATM/CPL/LND, 128 MPI/node, queue `hpcl-cli185`

The first submit used `CONTINUE_RUN=FALSE` so ELM read the AI `finidat` and
started the clock at `0401-01-01`. A 10-day smoke (`STOP_OPTION=ndays`,
`STOP_N=10`) wrote the tiny `elm.r.0401-01-11` file; **do not** use that for
transient.

### 8.2 Continue runs (current mode)

After the first multi-year segment succeeds, **every later job is a continue
run**. As-run command (2026-08-11 and 2026-08-20):

```bash
cd ${KMELM_ROOT}/e3sm_cases/uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC_finalspin
./xmlchange CONTINUE_RUN=TRUE
./xmlchange STOP_OPTION=nyears,STOP_N=10
./xmlchange REST_OPTION=nyears,REST_N=2
./xmlchange JOB_WALLCLOCK_TIME=12:00:00
# optional: RESUBMIT=N for N automatic follow-on 10-year segments
./xmlchange RESUBMIT=0
./case.submit
```

Rules for an agent:

1. **Do not** set `CONTINUE_RUN=FALSE` again unless the user wants a brand-new
   startup from `finidat`. That would ignore `rpointer` and restart from the
   AI `0021` file at year 0401.
2. **Do not** edit `user_nl_elm` `finidat` for a continue run. CIME reads
   `run/rpointer.lnd` and `run/rpointer.drv`.
3. **Do not** delete the run directory or the `rpointer.*` files.
4. Confirm `rpointer.lnd` names an existing `elm.r.YYYY-01-01-00000.nc` and
   `rpointer.drv` names the matching `cpl.r.YYYY-01-01-00000.nc`.
5. Each successful 10-year segment writes five 2-year ELM restarts
   (`+2, +4, +6, +8, +10`) at ~49 GB each, plus coupler restarts and an
   annual `elm.h0` (because `hist_nhtfrq=-175200`).
6. If `CaseStatus` shows `model execution starting` with no later `success`
   or `error`, the segment is unfinished. Inspect the queue and the latest
   `elm.r` year before submitting again.

### 8.3 Restarts on disk (2026-09-13)

| Item | Value |
|---|---|
| AI IC | `…/AI_restartfile/updated_restart_normal_spinup_…elm.r.0021-01-01-00000.nc` |
| AD raw 0021 (not used as finalspin IC) | `e3sm_runs/…_ERA5REF_…/run/…elm.r.0021-01-01-00000.nc` |
| Finalspin Jan-1 ELM restarts | `0403, 0405, …, 0469` every 2 years |
| Last **successful** 10-year job | `477999` (2026-08-28) ended at **0461** |
| `rpointer` now | **0469-01-01** (`elm.r` + `cpl.r`) |
| Last job in CaseStatus | `491899` started 2026-09-05; no success/fail line yet |
| h0 snapshots | `0401`, `0421`, `0441`, `0461` |

Job `491899` wrote `0463`–`0469` (eight years of a 10-year segment) and left
`rpointer` at 0469. Treat **0469** as the latest usable continue point, and
**0461** as the last fully closed 10-year segment. Confirm whether `491899`
is still running or died before submitting the next continue.

### 8.4 What the continue run is for

Finalspin is **not** the end product. It relaxes the AI IC under normal BGC
(`spinup_state=0`) and writes Jan-1 restarts that a **transient** (historical
/ “transit”) case will read as `finidat`.

Use a **1 January** restart (`…elm.r.YYYY-01-01-00000.nc`), not mid-year or
the 10-day `0401-01-11` smoke file. Prefer a year that also has
`cpl.r.YYYY-01-01-00000.nc` if the transient case is hybrid/branch. For a
new `RUN_TYPE=startup` transient, ELM `finidat` alone is enough.

There is **no** TES_NORTH transient create script in `kmELM` yet. When the
user asks to start transit/transient:

1. Do **not** keep extending this finalspin case with historical DATM years.
   Create a **new** case (new name, e.g. `…_transient` or `…_20TR`).
2. Keep the same domain, surfdata, `DATM_MODE=uELM_TES`, PE family, and ELM
   flags (`spinup_state=0`, `suplphos='NONE'`, AD spinup off).
3. Set `finidat` to the chosen finalspin `elm.r.YYYY-01-01-00000.nc`.
4. Set `CONTINUE_RUN=FALSE` and a new `RUN_STARTDATE` for the transient
   calendar (do not reuse `0401-01-01` unless the user says to).
5. Point DATM at the years needed for transient. The forcing archive already
   has **1980–2023**; spinup only cycled 1980–1999.
6. Leave the finalspin case and its `rpointer` untouched so continue runs can
   resume if more spinup years are requested.

### 8.5 Agent checklist (next actions)

1. If the user wants **more finalspin years**: check job `491899` / queue;
   if the run dir is idle, `CONTINUE_RUN=TRUE` from `rpointer` 0469 and
   submit another `STOP_N=10` / `REST_N=2` segment. Do not recreate the case.
2. If the user wants **transient**: ask (or use their stated) restart year;
   default to the latest complete Jan-1 pair (`0469` if `elm.r` and `cpl.r`
   are both present and the segment looks healthy, else `0461`). Then create
   a new case as in §8.4. Document that new case in this file when it exists.
3. If the user wants to **recreate** finalspin from scratch: only then run
   `TES_NORTHERA5_finalspin_ref.sh` with `FORCE_RECREATE=1`, and only after
   confirming the AI restart file is still at the path in §7.

---

## 9. Directory layout to copy

Minimum tree for DATM + ELM (relative to a data root you choose):

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
  atm_forcing.datm7.km.1d/   # rebuild with NORTHERA5_softlink_creation.py
    domain.lnd.Daymet.km.1d.nc
    clmforc.Daymet.km.1d.Prec.YYYY-MM.nc
    clmforc.Daymet.km.1d.Solr.YYYY-MM.nc
    clmforc.Daymet.km.1d.TPQWL.YYYY-MM.nc
```

Set:

```bash
./xmlchange DIN_LOC_ROOT_CLMFORC=<DATA_ROOT>/entire_domain
./xmlchange ATM_DOMAIN_PATH=<DATA_ROOT>/entire_domain/domain_surfdata
./xmlchange LND_DOMAIN_PATH=<DATA_ROOT>/entire_domain/domain_surfdata
./xmlchange ATM_DOMAIN_FILE=NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc
./xmlchange LND_DOMAIN_FILE=NORTHERA5_domain.lnd.TES_NORTHERA5.4km.1d.c251009.nc
```

and in `user_nl_elm`:

```
fsurdat = '<DATA_ROOT>/entire_domain/domain_surfdata/surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc'
```

Disk for 1980–1999 only is about **400 GB** (20/44 of 878 GB). Full 1980–2023
is ~878 GB plus ~100 MB of domain/surfdata.

---

## 10. Recreate on another computer

1. Clone `kmELM` and initialize the `E3SM` submodule. Checkout a branch that
   has `uELM_TES` (fork `master` or `TESSFA_4km`). Overlay Pathfinder (or your
   machine) files if that branch lacks them. See
   [`e3sm_source_trees.md`](./e3sm_source_trees.md).
2. Copy the TES_NORTH data tree in §9. Rebuild `atm_forcing.datm7.km.1d`
   softlinks. Confirm domain and surfdata SHA256.
3. Install stock E3SM inputdata so the relative paths in §6 exist under
   `DIN_LOC_ROOT`. Confirm `clm_params_c211124.nc` and
   `CNP_parameters_c180529.nc` SHA256.
4. Run `TES_NORTHERA5_ref.sh` after editing `CLI185PROJ_ROOT` / `KMELM_ROOT` /
   `E3SM_DIN` / `DATA_ROOT` for the new machine, or `create_newcase` with the
   xmlchanges in that script.
5. Adjust `NTASKS_*`, `MAX_MPITASKS_PER_NODE`, queue, and wallclock.
6. AD: cold start, `ELM_ACCELERATED_SPINUP=on`, `spinup_state=1`,
   `suplphos='ALL'`, 20 years.
7. Finalspin first segment: `finidat` = **AI** `0021` restart,
   `RUN_STARTDATE=0401-01-01`, `CONTINUE_RUN=FALSE`,
   `ELM_ACCELERATED_SPINUP=off`, `spinup_state=0`, `suplphos='NONE'`.
8. Later finalspin years: `CONTINUE_RUN=TRUE` from `rpointer` (§8). Do not
   reset `finidat`.
9. Transient is a **new** case that reads a finalspin Jan-1 `elm.r` (§8.4).

Do not reuse ERAf09 namelists, f09 domain/surfdata, or the `E3SM-era5` tree
for this experiment.

---

## 11. Related products (not this baseline)

| Product | Difference |
|---|---|
| `TES_NORTHACCESS` | Same domain idea, ACCESS-CM2 forcing, different surfdata date stamps |
| `75Plus_TES_NORTHACCESS` | Longitude subset `xc >= -75` |
| `Daymet_ERA5_TESSFA2` / TES SE / TVA | Different TES domains |
| Global f09 ERA5 (`I1850ERACNPRDCTCBC`) | 0.9×1.25, `DATM_MODE=ERAf09`, stock f09 surfdata |
