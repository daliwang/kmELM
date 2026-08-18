# Campaign 2 report — `e3sm_land_developer` on Frontier (`maint-3.0`)

**Date:** 2026-08-18  
**Machine:** OLCF Frontier, project `cli115`  
**Status:** Generate and compare **complete**. Machines-only E3SM PR **deferred** to a later step.

This is the land-team report for porting five CLM cryosphere/hydrology bug fixes onto E3SM `maint-3.0`. Overlay notes (how Frontier was made usable) live in [`frontier_maint-3.0_testing_overlay.md`](frontier_maint-3.0_testing_overlay.md). Procedure: [`e3sm_land_developer_testing_procedure.md`](e3sm_land_developer_testing_procedure.md). Campaign 1 (master) remains in [`e3sm_land_developer_testing_results.md`](e3sm_land_developer_testing_results.md).

---

## Headline

| Question | Answer |
|---|---|
| Did the science branch run? | **Yes.** 50/50 `RUN` PASS on both gold and compare. |
| Did answers change vs parent `maint-3.0`? | **Yes, as expected.** 45/50 `BASELINE` FAIL (history DIFF). |
| Are restarts and namelists clean? | **Yes.** `COMPARE_base_rest` PASS on all 39 ERS tests; `NLCOMP` PASS on all 50. |
| Did MOSART-only tests change? | **No.** 5/5 bit-for-bit vs gold. |
| New crashes or walltime FAILs? | **None.** Two FATES `MEMLEAK` FAILs already present on parent gold. |
| Is the Frontier overlay in the science PR? | **No.** Local kmELM overlay only. A machines PR is saved for the next step. |

Treat **BASELINE DIFF** as expected for this science. Do **not** bless into shared Frontier gold.

---

## What was tested

| Item | Value |
|---|---|
| Science branch | [`lnd/port-clm-cryosphere-fixes-maint-3.0`](https://github.com/daliwang/E3SM/tree/lnd/port-clm-cryosphere-fixes-maint-3.0) @ `3c77ed78f3` |
| Parent / gold | `maint-3.0` @ `34bd782d18` |
| Suite | `e3sm_land_developer` only (50 tests; not full `e3sm_developer`) |
| Compiler | `craygnu` via kmELM overlay (`Core/25.03`, `PrgEnv-gnu`, `cpe/25.09`, `gcc-native/14.2`) |
| Walltime | `01:30:00` (campaign 1 r05 tests timed out at 45 min) |
| Personal gold | `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines/34bd782d18/` |
| Scratch / `cs.status` | `/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch` |
| Generate cases | `*.G.34bd782d18` — `cs.status.34bd782d18` |
| Compare cases | `*.C.3c77ed78f3` — `cs.status.3c77ed78f3` |
| Smoke (science branch) | `elm-snowveg_arctic` ERS **PASS** (RUN + restart); `elm-force_netcdf_pio` SMS **PASS** (RUN) |

Gold was written only to the **personal** kmELM baseline root. Shared `/lustre/orion/cli115/world-shared/e3sm/baselines/frontier/$COMPILER` was not used.

```bash
module load cray-python/3.11.7
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.34bd782d18   # generate
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.3c77ed78f3   # compare
```

---

## Science on the branch

Cherry-picked onto `maint-3.0` @ `34bd782d18`. Same five commits as campaign 1 (master). Not included: CPL_BYPASS longitude lookup, CRUJRA/OLMT, Pathfinder machine files, Frontier overlay.

| Commit | Subject |
|---|---|
| `36deec7f46` | Port CLM fractional-snow energy and melt-compaction fixes |
| `a63fb07099` | Port CLM bedrock heat capacity fix in `SoilTemperatureMod` |
| `45e8c6e260` | Port CLM active-element masking for ELM accumulators |
| `1b19ba5e35` | Bug fixes for surface water runoff calculation |
| `3c77ed78f3` | Fix snow balance accounting issue |

These are expected to change snow energy, snow mass, soil temperature, accumulators, surface-water runoff, and (by coupling) many downstream ELM/CPL fields.

---

## Step 1 — generate gold from parent `maint-3.0`

Queue empty; 50 cases.

| Phase | Result |
|---|---|
| SETUP / MODEL_BUILD / RUN | **50/50 PASS** |
| GENERATE | **50/50 PASS** (gold `.nc` written) |
| `COMPARE_base_rest` | **39 PASS**, 11 n/a (SMS has no restart compare) |
| `NLCOMP` | **50/50 PASS** |
| `MEMLEAK` | **48 PASS**, **2 FAIL** (FATES; gold still written) |

MEMLEAK FAILs (already on parent; not introduced by the science):

- `SMS_D_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates_rd`
- `SMS_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates_eca`

Unlike campaign 1, both r05 ELM tests (`elm-cbudget`, `elm-V2_ELM_MOSART_features`) **finished** at `01:30:00` and have gold.

---

## Step 2 — compare science branch vs gold `34bd782d18`

Driver `e3sm_land_developer_compare.sh` submitted 2026-08-18 ~07:45 EDT; builds/submits finished ~08:14; Slurm queue empty when this report was written. 50 cases.

| Phase | Result |
|---|---|
| RUN | **50/50 PASS** |
| `BASELINE` | **45 FAIL** (history DIFF vs gold), **5 PASS** |
| `COMPARE_base_rest` | **39 PASS**, 11 n/a |
| `NLCOMP` | **50/50 PASS** |
| `MEMLEAK` | same 2 FATES FAILs as generate |

CIME records history mismatch as `BASELINE FAIL`. That is the expected science DIFF, not a crash.

### Interpretation

| Signal | Result | Why it matters |
|---|---|---|
| `NLCOMP` | PASS on all 50 | Namelists unchanged vs gold |
| `COMPARE_base_rest` | PASS on every ERS | Restart is bit-for-bit with itself |
| MOSART-only vs gold | PASS (5/5) | River model answers unchanged when ELM is not the science |
| ELM I-compsets vs gold | DIFF (all that ran ELM) | Snow, soil T, runoff, albedo, fluxes |
| FATES vs gold | DIFF | Same land physics under FATES |
| Debug (`ERS_D` / `SMS_D`) | DIFF, not crash | No debug-build failure |
| Walltime | none | r05 tests completed with `01:30:00` |

The diffs line up with the five science commits, not with a compile or restart bug. Pattern matches campaign 1 on master.

---

## Tests that PASS vs gold (MOSART-only)

Bit-for-bit with `34bd782d18`. Expected: the five commits do not change MOSART.

- `ERS.MOS_USRDAT.RMOSGPCC.frontier_craygnu.mosart-mos_usrdat`
- `ERS.MOS_USRDAT.RMOSNLDAS.frontier_craygnu.mosart-sediment`
- `ERS.r05_r05.RMOSGPCC.frontier_craygnu.mosart-gpcc_1972`
- `ERS.r05_r05.RMOSGPCC.frontier_craygnu.mosart-heat`
- `SMS.MOS_USRDAT.RMOSGPCC.frontier_craygnu.mosart-unstructure`

---

## Tests that DIFF vs `34bd782d18` (45)

Overall CIME `BASELINE FAIL`. Grouped for PR text. The two FATES MEMLEAK tests are also in this list.

### Debug ELM

- `ERS_D.f09_f09.IELM.frontier_craygnu.elm-koch_snowflake`
- `ERS_D.f09_f09.IELM.frontier_craygnu.elm-solar_rad`
- `ERS_D.f09_g16.I1850ELMCN.frontier_craygnu`
- `ERS_D.f19_f19.IELM.frontier_craygnu.elm-ic_f19_f19_ielm`
- `ERS_D.f19_g16.I1850GSWCNPRDCTCBC.frontier_craygnu.elm-ctc_f19_g16_I1850GSWCNPRDCTCBC`
- `ERS_D.ne4pg2_oQU480.I20TRELM.frontier_craygnu.elm-disableDynpftCheck`

### Standard ELM I-compsets

- `ERS.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-snowveg_arctic`
- `ERS.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-usrpft_codetest_I1850CNPRDCTCBC`
- `ERS.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-usrpft_default_I1850CNPRDCTCBC`
- `ERS.ELM_USRDAT.I1850ELM.frontier_craygnu.elm-usrdat`
- `ERS.ELM_USRDAT.IELM.frontier_craygnu.elm-surface_water_dynamics`
- `ERS.f09_g16.I1850ELMCN.frontier_craygnu.elm-bgcinterface`
- `ERS.f09_g16.I1850GSWCNPRDCTCBC.frontier_craygnu.elm-vstrd`
- `ERS.f09_g16.IELMBC.frontier_craygnu`
- `ERS.f09_g16.IELMBC.frontier_craygnu.elm-simple_decomp`
- `ERS.f19_f19.I1850ELMCN.frontier_craygnu`
- `ERS.f19_f19.I20TRELMCN.frontier_craygnu`
- `ERS.f19_g16.I1850CNECACNTBC.frontier_craygnu.elm-eca`
- `ERS.f19_g16.I1850CNECACTCBC.frontier_craygnu.elm-eca`
- `ERS.f19_g16.I1850CNRDCTCBC.frontier_craygnu.elm-rd`
- `ERS.f19_g16.I1850ELM.frontier_craygnu.elm-betr`
- `ERS.f19_g16.I1850ELM.frontier_craygnu.elm-vst`
- `ERS.f19_g16.I1850GSWCNPECACNTBC.frontier_craygnu.elm-eca_f19_g16_I1850GSWCNPECACNTBC`
- `ERS.f19_g16.I20TRGSWCNPECACNTBC.frontier_craygnu.elm-eca_f19_g16_I20TRGSWCNPECACNTBC`
- `ERS.f19_g16.I20TRGSWCNPRDCTCBC.frontier_craygnu.elm-ctc_f19_g16_I20TRGSWCNPRDCTCBC`
- `ERS.f19_g16.IERA56HRELM.frontier_craygnu`
- `ERS.f19_g16.IERA5ELM.frontier_craygnu`
- `ERS.hcru_hcru.IELM.frontier_craygnu.elm-multi_inst`
- `ERS.r05_r05.ICNPRDCTCBC.frontier_craygnu.elm-cbudget`
- `ERS.r05_r05.IELM.frontier_craygnu.elm-V2_ELM_MOSART_features`
- `ERS.r05_r05.IELM.frontier_craygnu.elm-lnd_rof_2way`
- `SMS.r05_r05.I1850ELMCN.frontier_craygnu.elm-qian_1948`
- `SMS.r05_r05.IELM.frontier_craygnu.elm-topounit`
- `SMS_Ld1.hcru_hcru.I1850CRUELMCN.frontier_craygnu`
- `SMS_Ly2_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-fan`
- `SMS_Ly2_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-force_netcdf_pio`
- `SMS_Ly2_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-per_crop`
- `SMS_Ly2_P1x1_D.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-lulcc_sville`

### FATES (also two MEMLEAK FAILs, already on parent)

- `ERS_D_Ld15.f45_g37.IELMFATES.frontier_craygnu.elm-fates_cold_treedamage`
- `ERS_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates`
- `ERS_Ld30.f45_f45.IELMFATES.frontier_craygnu.elm-fates_satphen`
- `ERS_Ld30.f45_g37.IELMFATES.frontier_craygnu.elm-fates_cold_sizeagemort`
- `SMS_D_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates_rd` (MEMLEAK FAIL)
- `SMS_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates_eca` (MEMLEAK FAIL)
- `SMS_Ld5_PS.f19_g16.IELMFATES.frontier_craygnu.elm-fates_cold`

---

## vs campaign 1 (master, 2026-08-14)

| | Campaign 1 (master) | Campaign 2 (`maint-3.0`) |
|---|---|---|
| Parent | `a899004464` | `34bd782d18` |
| Science tip | `fbfcc93f52` | `3c77ed78f3` |
| Suite size | 55 | 50 |
| Compiler | shipped `craygnu` | overlay `craygnu` (shipped name is still `gnu`) |
| RUN PASS | 53 (2 r05 walltime FAIL at 45 min) | **50/50** at 90 min |
| BASELINE DIFF | 48 of 53 that ran | **45 of 50** |
| MOSART PASS vs gold | 5 | 5 |
| Restart / NLCOMP | clean | clean |
| MEMLEAK on parent | 4 | 2 (same FATES pair; suite has fewer tests) |

---

## Frontier overlay (testing only — not in the science PR)

`maint-3.0` as shipped cannot SETUP on current Frontier: compiler name `gnu`, pins `PrgEnv-gnu/8.3.3` + `gcc/12.2.0` (gone), Lmod `/usr/share/lmod` (login-only), and `lmod python` exits 1 because of OLCF `NSPLoggingHook.lua`.

Campaign 2 used a **local overlay** applied after checkout by the generate/compare/smoke scripts (`scripts/workaround_frontier_lmod_reset.py`). Dirty files under `E3SM/` must **not** be `git add`ed onto `lnd/port-clm-cryosphere-fixes-maint-3.0`.

What the overlay does (detail in [`frontier_maint-3.0_testing_overlay.md`](frontier_maint-3.0_testing_overlay.md)):

1. Keep maint-3.0 CIME skeleton (`BATCH_SYSTEM=slurm`, no ADIOS/BLOSC).
2. Add master’s `craygnu` modules (`Core/25.03` / `cpe/25.09` / `gcc-native/14.2`); drop `libunwind`.
3. Point Lmod at `/opt/cray/pe/lmod` and wrap `lmod python`.
4. Copy `craygnu.cmake` plus `-lgfortran -lstdc++`.
5. Collapse duplicate `use elm_varctl, only:` in `controlMod.F90` so gfortran 14 reads `elm_inparm`.

Do **not** paste master’s full Frontier `<machine>` block: `ADIOS2_ROOT`/`BLOSC2_ROOT` make maint-3.0 CMake fail looking for Blosc2, and this CIME has no `frontier_slurm` batch type.

---

## Recommendation and next steps

1. **Land science PR:** five cryosphere/hydrology commits only. Paste [`e3sm_pr_frontier_testing_note.md`](e3sm_pr_frontier_testing_note.md). Cite this report for counts.
2. **BASELINE DIFF** is expected. Do not bless `34bd782d18` or `3c77ed78f3` into shared Frontier gold until reviewers agree the diffs match the science.
3. **Machines-only E3SM PR targeting `maint-3.0`:** saved for the **next step**. Mergeable subset is `craygnu` + cmake (`-lstdc++`) + `/opt/cray/pe/lmod` paths. Reviewers: machines/CIME, cc land. Until that lands, keep using the kmELM overlay for Frontier land tests on this tag.
4. **Stay overlay-only until agreed:** Lmod python wrapper; full master Frontier block; `controlMod.F90` USE cleanup (tiny ELM follow-up if desired).
5. Overlay is still required for SETUP on today’s Frontier even after a machines PR, unless OLCF/CIME fix `NSPLoggingHook.lua`.
