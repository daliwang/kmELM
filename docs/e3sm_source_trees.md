# E3SM source trees in kmELM

One `E3SM/` checkout cannot hold two branches at once. Pin each campaign to its
own tree so Pathfinder ERA5 f09 and TES_NORTH (and Frontier land-developer
testing) do not clobber each other.

Cases and runs stay under the shared kmELM repo (`e3sm_cases/`, `e3sm_runs/`).
Only the **source** is split.

## Pathfinder (this clone)

| Tree | Branch (typical) | Experiment | Create scripts |
|---|---|---|---|
| **`E3SM-era5/`** | `lnd/clm_glacier_fixes_era5` @ `c2d41815c1` (science through `2a1960cd8a`) | Global f09 + remapped ERA5, compset `I1850ERACNPRDCTCBC`, `DATM_MODE=ERAf09` | `case_gene/PathFinder/ERAf09/` |
| **`E3SM/`** (submodule) | whatever the other project needs — often `TESSFA_4km` or `master` | TES_NORTH 4 km, `ELM_USRDAT`, `DATM_MODE=uELM_TES` | `case_gene/PathFinder/TES_NORTHERA5/` |

Create or repair the ERA5 tree:

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
bash scripts/setup_e3sm_era5_worktree.sh
```

`E3SM-era5` is a **git worktree** of the `E3SM` submodule (shared objects,
separate working copy). It is gitignored (`E3SM-*/`). Do not `git add` it.

The setup script initializes **CIME, MCT, and SCORPIO** only (enough for
`I1850ERACNPRDCTCBC`). It does not recurse into unused EAM/MPAS/sBETR
third-party clones.

After the worktree exists, `E3SM/` is detached (or on another branch) so you can:

```bash
git -C E3SM fetch origin
git -C E3SM checkout TESSFA_4km    # TES / TESSFA 4 km science
# or
git -C E3SM checkout master
git -C E3SM submodule update --init --recursive
```

`TESSFA_4km` has `I1850uELMTESCNPRDCTCBC` / `%uELMTES`. It does **not** currently
ship Pathfinder machine files; copy or overlay those from `lnd/clm_glacier_fixes_era5`
(`cime_config/machines/config_machines.xml`, `config_batch.xml`,
`cmake_macros/pathfinder_gnu.cmake`) before creating a Pathfinder TES case on
that branch.

`master` on this fork has `uELM_TES` DATM streams and Pathfinder machine files,
but **not** `%ERAf09` / `I1850ERACNPRDCTCBC`.

## Do not mix

| Action | Why it fails |
|---|---|
| `create_newcase --compset I1850ERACNPRDCTCBC` against `E3SM/` on `master` or `TESSFA_4km` | alias and `ERAf09` streams are only on `lnd/clm_glacier_fixes_era5` |
| `create_newcase --compset I1850uELMTESCNPRDCTCBC` against `E3SM-era5` | that alias is on `TESSFA_4km`, not the ERA5 branch |
| Reusing TES namelists for f09 ERA5 (or the reverse) | different grid, DATM mode, surfdata, PE layout |
| `git submodule update --remote -- E3SM` while ERA5 cases are mid-port | moves the **submodule** pointer toward `origin/master`; does not update `E3SM-era5` |

ERAf09 scripts default to `E3SM-era5` when that directory exists, and they abort
if the chosen tree has no `%ERAf09`. Override with `E3SM_SRCROOT=...` if needed.

TES scripts hardcode `${KMELM_ROOT}/E3SM`. Keep it that way.

## Existing Pathfinder cases (SRCROOT)

| Case | Built against | Note |
|---|---|---|
| `e3sm_cases/I1850ERACNPRDCTCBC_f09_smoke1980` | `.../kmELM/E3SM` | Pathfinder smoke **passed** (job `524272`, 2026-09-12). Recreate against `E3SM-era5` if you rebuild. |
| `e3sm_cases/uELM_NORTHERA5_*` | `.../kmELM/E3SM` | TES_NORTH. Leave `E3SM/` on the branch those cases were built with until you recreate them. |

## Frontier (Lustre clone)

Same idea, different names. Land-developer gold/compare uses
`E3SM-master-pr` (`scripts/e3sm_land_developer.conf.sh`). The production ERA5
AD/final cases were built from the submodule working tree on
`lnd/clm_glacier_fixes_era5`. See
[`I1850ERACNPRDCTCBC_f09_era5_spinup_process.md`](./I1850ERACNPRDCTCBC_f09_era5_spinup_process.md).

## Docs by experiment

| Experiment | Process / status |
|---|---|
| ERA5 f09 spinup (Frontier as-run + Pathfinder port) | [`I1850ERACNPRDCTCBC_f09_era5_spinup_process.md`](./I1850ERACNPRDCTCBC_f09_era5_spinup_process.md) |
| ERA5 f09 short card | [`I1850ERACNPRDCTCBC_f09_spinup_report.md`](./I1850ERACNPRDCTCBC_f09_spinup_report.md) |
| ERA5 f09 Frontier smoke | [`I1850ERACNPRDCTCBC_f09_smoke1980_report.md`](./I1850ERACNPRDCTCBC_f09_smoke1980_report.md) |
| TES_NORTH on Pathfinder | [`TES_NORTH_baseline_on_pathfinder.md`](./TES_NORTH_baseline_on_pathfinder.md) (domain / forcing / surfdata / params); create scripts: [`../case_gene/PathFinder/TES_NORTHERA5/README.md`](../case_gene/PathFinder/TES_NORTHERA5/README.md) |
| TES_NORTH on a new machine (Polaris) | [`TES_NORTH_repeat_on_new_machine.md`](./TES_NORTH_repeat_on_new_machine.md) |
| TES_NORTH data inventory + Frontier transfer | [`TES_NORTH_data_inventory_and_frontier_transfer.md`](./TES_NORTH_data_inventory_and_frontier_transfer.md) |
| TES_NORTH training and inference | [`TES_NORTH_training_and_inference_guide.md`](./TES_NORTH_training_and_inference_guide.md) |
