# Pathfinder TES_NORTH (TES_NORTHERA5)

4 km TES domain with Daymet-downscaled ERA5 (`DATM_MODE=uELM_TES`, `ELM_USRDAT`).
This is **not** the global f09 ERA5 spinup in `../ERAf09/`.

Use a **separate E3SM tree**. The f09 ERA5 branch lives in `E3SM-era5/`.
TES scripts point at `${KMELM_ROOT}/E3SM`. See
[`docs/e3sm_source_trees.md`](../../../docs/e3sm_source_trees.md).

## Scripts

| Script | Role |
|---|---|
| `TES_NORTHERA5_ref.sh` | AD / accelerated spinup (`I1850CNPRDCTCBC`, `uELM_TES`) |
| `TES_NORTHERA5_finalspin_ref.sh` | Final spinup from the AD 0401 restart |
| `TES_NORTHERA5.sh` | Alternate create using `I1850uELMTESCNPRDCTCBC` (needs `TESSFA_4km`) |

Data: `/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/TES_cases_data/Daymet_ERA5_TESSFA_NORTH`

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
