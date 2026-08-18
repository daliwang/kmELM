# Frontier testing overlay for `maint-3.0`

**Date:** 2026-08-18  
**Science branch (do not mix with this overlay):** [`lnd/port-clm-cryosphere-fixes-maint-3.0`](https://github.com/daliwang/E3SM/tree/lnd/port-clm-cryosphere-fixes-maint-3.0)  
**Reference that already works on current Frontier:** [`lnd/port-clm-cryosphere-fixes-master`](https://github.com/daliwang/E3SM/tree/lnd/port-clm-cryosphere-fixes-master) (`craygnu`)

These changes are **machine/compiler/CIME site work**, not ELM cryosphere science. They live in `kmELM/scripts/` and are applied to a checkout of `maint-3.0` only for `e3sm_land_developer` on Frontier. They must **not** be committed onto the science branch.

Paste-ready PR text: [`e3sm_pr_frontier_testing_note.md`](e3sm_pr_frontier_testing_note.md).

---

## Recommendation: separate PR?

**Yes — keep configuration out of the land science PR.**  
`lnd/port-clm-cryosphere-fixes-maint-3.0` should stay the five snow/soil/hydrology commits. Reviewers should not have to digest Frontier Lmod paths, GNU module pins, or gfortran-14 namelist USE cleanup in the same PR.

**A follow-up E3SM PR targeting `maint-3.0` is worth doing, but only for the mergeable subset**, and it should go to the **machines / CIME** reviewers (cc land), not be hidden inside the cryosphere PR.

| Change | Put in science PR? | Separate `maint-3.0` machines PR? | Keep as kmELM overlay? |
|---|---|---|---|
| `craygnu` compiler name + `Core/25.03` / `PrgEnv-gnu` / `cpe/25.09` / `gcc-native/14.2` | No | **Yes** — this is the real site update | Yes until that PR lands |
| `craygnu.cmake` + `Depends.craygnu.cmake` | No | **Yes** (add `-lstdc++` for maint-3.0 CIME’s Fortran link) | Yes until that PR lands |
| Lmod paths `/usr/share/lmod` → `/opt/cray/pe/lmod` | No | **Yes** — compute nodes only have the Cray path | Yes until that PR lands |
| `cime_lmod_python_wrapper.sh` (OLCF `NSPLoggingHook.lua`) | No | **No** until OLCF/CIME agree — this is a site hook workaround | **Yes** |
| Drop `libunwind` from the GNU module list | No | Maybe (wrapper cannot load it one-at-a-time) | Yes |
| Duplicate `use elm_varctl, only:` removal in `controlMod.F90` | No | **Tiny ELM PR / commit**, not machines XML | Yes for testing |
| Copy master’s full Frontier `<machine>` block (`frontier_slurm`, ADIOS2/BLOSC2, …) | No | **No** — maint-3.0 CMake then fails looking for Blosc2; CIME has no `frontier_slurm` type | Never |

Until a machines PR exists, Frontier land tests on `maint-3.0` should keep using this overlay. Campaign 2 gold/compare was produced that way. **Campaign 2 report (complete):** [`e3sm_land_developer_campaign2_maint-3.0_report.md`](e3sm_land_developer_campaign2_maint-3.0_report.md). The machines PR is deferred to a later step.

---

## Why `maint-3.0` is not “the same as master” on Frontier

Compsets and ELM namelist *definitions* for `e3sm_land_developer` are the same suite. What drifted is the **Frontier machine file** and the **GNU compiler stack**:

| | `maint-3.0` as shipped (`34bd782d18`) | Current Frontier / master `craygnu` |
|---|---|---|
| Compiler name | `gnu` | `craygnu` |
| PrgEnv pin | `PrgEnv-gnu/8.3.3` + `gcc/12.2.0` (gone) | `Core/25.03` + `PrgEnv-gnu` + `cpe/25.09` + `gcc-native/14.2` |
| Lmod paths | `/usr/share/lmod/...` (login only) | `/opt/cray/pe/lmod/...` (login + compute) |
| `lmod python` | exits 1 in `NSPLoggingHook.lua` | master CIME still calls it; this overlay wraps it |
| Batch type | `slurm` | `frontier_slurm` (maint-3.0 CIME does not know this name) |

That is why SETUP, link, and `elm_inparm` failed until the overlay. They were not land-science or compset bugs.

---

## What the overlay actually does

Applied after `git checkout` by `scripts/e3sm_land_developer_generate.sh`, `_compare.sh`, and `_smoke.sh` via `workaround_frontier_lmod_reset.py`.

1. **Keep** maint-3.0’s Frontier CIME skeleton: `BATCH_SYSTEM=slurm`, mpirun, NETCDF env, no ADIOS/BLOSC.
2. **Add** `craygnu` to `COMPILERS` and insert master’s `craygnu.*` module block (from `scripts/frontier_craygnu_overlay/frontier_machine.xml`), dropping `libunwind`.
3. **Rewrite** Lmod `init_path` / `cmd_path` from `/usr/share/lmod` to `/opt/cray/pe/lmod`.
4. **Point** python `cmd_path` at `scripts/cime_lmod_python_wrapper.sh` so CIME SETUP gets exit 0 despite the OLCF hook.
5. **Copy** `craygnu.cmake` (master macros + `-lgfortran -lstdc++`) and `Depends.craygnu.cmake`.
6. **Delete** the extra `use elm_varctl, only:` lines in `controlMod.F90`, leaving the existing `use elm_varctl`. gfortran 14 otherwise omits later namelist members (`use_dynroot`, …) and RUN aborts with `ERROR reading elm_inparm`. Master already collapsed those USEs.

Do not `git add` the resulting dirty files under `E3SM/` onto `lnd/port-clm-cryosphere-fixes-maint-3.0`.

---

## Files in this repo (the testing-enablement branch)

| Path | Role |
|---|---|
| `scripts/e3sm_land_developer.conf.sh` | hashes, `craygnu`, walltime, smoke tests |
| `scripts/e3sm_land_developer_generate.sh` | gold from parent `34bd782d18` |
| `scripts/e3sm_land_developer_compare.sh` | compare science branch vs that gold |
| `scripts/e3sm_land_developer_smoke.sh` | two cheap cases on the science branch |
| `scripts/workaround_frontier_lmod_reset.py` | apply overlay to a checkout |
| `scripts/cime_lmod_python_wrapper.sh` | CIME `lmod python` stand-in |
| `scripts/frontier_craygnu_overlay/` | master’s Frontier GNU files + cmake |

Procedure: [`e3sm_land_developer_testing_procedure.md`](e3sm_land_developer_testing_procedure.md).  
Results: [`e3sm_land_developer_testing_results.md`](e3sm_land_developer_testing_results.md).
