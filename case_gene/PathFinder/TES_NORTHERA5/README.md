# Pathfinder TES_NORTH (TES_NORTHERA5)

4 km TES domain with Daymet-downscaled ERA5 (`DATM_MODE=uELM_TES`, `ELM_USRDAT`).
This is **not** the global f09 ERA5 spinup in `../ERAf09/`.

Use a **separate E3SM tree**. The f09 ERA5 branch lives in `E3SM-era5/`.
TES scripts point at `${KMELM_ROOT}/E3SM`. See
[`docs/e3sm_source_trees.md`](../../../docs/e3sm_source_trees.md).

## Scripts

| Script | Role |
|---|---|
| `TES_NORTHERA5_ref.sh` | AD 20 yr (`I1850CNPRDCTCBC`, `uELM_TES`) — matches the successful AD case |
| `TES_NORTHERA5_finalspin_ref.sh` | Continuous run from the AI 0021 restart — matches `..._finalspin` |
| `TES_NORTHERA5.sh` | Alternate create using `I1850uELMTESCNPRDCTCBC` (needs `TESSFA_4km`) |

The two `_ref` scripts **refuse to delete** an existing case unless `FORCE_RECREATE=1`.

Data: `/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH`

Successful Pathfinder cases
`uELM_NORTHERA5_ERA5REF_I1850uELMCNPRDCTCBC` and `..._finalspin` use:

| Item | AD | finalspin |
|---|---|---|
| Surfdata | `surfdata.TESSFA_DOMAIN1.4km.1d.NALCMS.c260218_yw.nc` | same |
| `DIN_LOC_ROOT` | `/projects/hpcl-cli185/world-shared/e3sm` (not `.../inputdata`) | same |
| History | `hist_nhtfrq=-175200`, `hist_mfilt=1` (hourly `hist_fincl2` commented out) | same |
| `finidat` | cold start | AI `...elm.r.0021-01-01-00000.nc` (`RUN_STARTDATE=0401-01-01`) |
| PE | LND 840, ATM 50, CPL 1, 84 MPI/node | ATM/CPL/LND 1920, 128 MPI/node |
| Segment | `STOP_N=20`, `REST_N=5`, wall 24 h, queue `parallel` | `STOP_N=10`, `REST_N=2`, wall 12 h, queue `hpcl-cli185` |

The Pathfinder machine file defaults `DIN_LOC_ROOT` to `.../e3sm/inputdata`. These two cases override it to the parent `e3sm` tree so ELM reads `$DIN_LOC_ROOT/lnd/clm2/...` and `$DIN_LOC_ROOT/atm/datm7/...` as in the completed runs. `TES_NORTHERA5_ref.sh` and `TES_NORTHERA5_finalspin_ref.sh` match that.

Existing cases under `${KMELM_ROOT}/e3sm_cases/uELM_NORTHERA5_*` were created
with `SRCROOT=.../kmELM/E3SM`. Checkout the TES branch in that tree before
recreating them:

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
# ERA5 branch must already live in E3SM-era5 (do not checkout it here)
bash scripts/setup_e3sm_era5_worktree.sh   # no-op if the worktree exists
git -C E3SM fetch origin
git -C E3SM checkout TESSFA_4km            # or master / your TES branch
git -C E3SM submodule update --init --recursive
```

`TESSFA_4km` has the `I1850uELMTESCNPRDCTCBC` alias. It does not yet include
Pathfinder machine files; overlay those from `E3SM-era5` before `create_newcase`
on Pathfinder. `TES_NORTHERA5_ref.sh` uses stock `I1850CNPRDCTCBC` plus
`DATM_MODE=uELM_TES` and can run on a fork `master` that already has Pathfinder
support.
