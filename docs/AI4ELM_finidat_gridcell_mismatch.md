# AI4ELM `finidat` gridcell mismatch (94838 vs 94935)

**Date:** 2026-11-25  
**Machines:** Frontier (observed), Pathfinder (same fix)  
**Symptom:** ELM aborts at restart read with

```text
check_dim ERROR: mismatch of input dimension 94935 with expected value 94838 for variable gridcell
```

## Root cause

ELM’s compacted land mesh must match between:

1. the case’s `fsurdat` + land domain (`domain.lnd.r05_IcoswISC30E3r5.231121.nc`), and  
2. the `finidat` / `elm.r` restart.

Two incompatible restart families landed under the flat Frontier staging dir
`…/input_data/ai4elm_spinup/`:

| Mesh | `gridcell` | Safe to use with current GSW TOP/crop cases? |
|---|---|---|
| Jinyun Perlmutter AD / Frontier smoke / Pathfinder copy | **94838** | **Yes** |
| Alternate flat copies dated `20261015` (and some `rg.0002`) | **94935** | **No** |

Domain/surfdata themselves are 2-D (`720×360`); the compacted `gridcell` count
is what ELM checks in `ncdio_pio` when reading `finidat`.

## Confirmed locations and sizes (Frontier, 2026-11-25)

### Case / run roots (Jinyun notes)

| Role | Path |
|---|---|
| Perlmutter case | `/pscratch/sd/j/jinyun/elm/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup` |
| Perlmutter run | `/pscratch/sd/j/jinyun/e3sm_scratch/pm-cpu/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup` |
| Land domain | `…/share/domains/domain.lnd.r05_IcoswISC30E3r5.231121.nc` (`ni=720`, `nj=360`) |
| DATM domain | `…/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc` |
| `fsurdat` | `surfdata_0.5x0.5_50pfts_20250528.nc` (`lsmlon=720`, `lsmlat=360`) |

### Restarts on Frontier (`ncdump -h`)

| File | `gridcell` | Notes |
|---|---|---|
| `E3SM-ai4elm/AI_restart_files_Jinyun/…ad.spinup.elm.r.0021-01-01-00000.nc` | **94838** | **Use this** for code-start AD |
| `AI_restart_files_Jinyun/…rg.spinup.elm.r.0202-01-01-00000.nc` | **94838** | Same mesh (small file — verify pools before LandSim) |
| Frontier smoke `…adspinup…elm.r.0001-01-06-00000.nc` | **94838** | Matches case mesh |
| `ai4elm_spinup/20261009.…ad.spinup.elm.r.0202-01-01-00000.nc` | **94838** | OK mesh |
| `ai4elm_spinup/20261025.…rg.spinup.elm.r.0550-01-01-00000.nc` | **94838** | OK mesh |
| `ai4elm_spinup/20261015.…ad.spinup.elm.r.0018/0020/0022-…` | **94935** | **Do not use** with current cases |
| `ai4elm_spinup/20261017.…rg.spinup.elm.r.0002-…` | **94935** | **Do not use** |

Frontier job **5988293** (`ad0020_30node`) failed in ~1 min because
`user_nl_elm` pointed at the `20261015…elm.r.0020` (**94935**) file.

## Fix (Frontier and Pathfinder)

Code-start AD is **startup + ELM `finidat` only** (cold MOSART/DATM/cpl). Do
**not** `CONTINUE_RUN` from a Perlmutter coupler restart (PE-layout specific).

### 1. Point `finidat` at a 94838 restart

**Frontier (canonical):**

```text
/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/AI_restart_files_Jinyun/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0021-01-01-00000.nc
```

**Pathfinder (same basename under staged copy):**

```text
/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup/AI_restart_files_Jinyun/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0021-01-01-00000.nc
```

In the case directory:

```bash
# user_nl_elm
finidat = '<path-above>'
```

### 2. Match `RUN_STARTDATE` to the restart date

```bash
./xmlchange RUN_STARTDATE=0021-01-01
./preview_namelists
# no rebuild required for namelist / RUN_STARTDATE only
./case.submit
```

### 3. Prefer recreate scripts (repo)

| Machine | Script |
|---|---|
| Frontier | `case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_30node.sh` |
| Pathfinder | `case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node.sh` |

Both default to `elm.r.0021` (`94838`), `spinup_state=1`, `ELM_FORCE_COLDSTART=off`.

### 4. Quick mesh check before submit

```bash
ncdump -h "$FINIDAT" | grep 'gridcell ='
# expect: gridcell = 94838 ;
```

If you see `94935`, stop and retarget `finidat`.

## What not to do

- Do **not** edit the unrelated ERA5 case
  `E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_finalspinup/user_nl_elm`.
- Do **not** use flat `20261015…elm.r.0018/0020/0022` with the current
  `surfdata_0.5x0.5_50pfts_20250528` + `r05` domain cases.
- Do **not** assume every file under `ai4elm_spinup/` shares one mesh — check
  `gridcell` first.
- Pathfinder `ad0166_15node` / `rg0166_15node` still name missing `elm.r.0166`;
  use `ad0021_15node` (or copy `0166` from Perlmutter) instead.

## Related docs

- Perlmutter as-run: [`AI4ELM_Spinup_repeat.md`](./AI4ELM_Spinup_repeat.md)
- Jinyun CFS paths: [`Extra_Information_from_JinyunTang.md`](./Extra_Information_from_JinyunTang.md)
- Pathfinder status / LandSim: [`AI4ELM_Pathfinder_GSWP3_status_and_LandSim_plan.md`](./AI4ELM_Pathfinder_GSWP3_status_and_LandSim_plan.md)
- Frontier staging: [`../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md`](../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md)
- Pathfinder staging: [`../case_gene/PathFinder/AI4ELM_GSW/DATA.md`](../case_gene/PathFinder/AI4ELM_GSW/DATA.md)
