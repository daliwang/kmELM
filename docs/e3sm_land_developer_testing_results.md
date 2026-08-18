# `e3sm_land_developer` results

Two Frontier campaigns share this note. Gold directories are separate; campaign 2 does **not** reuse `a899004464`.

| Campaign | Parent / gold | Branch | Status |
|---|---|---|---|
| **2 — maint-3.0** | `34bd782d18` | `lnd/port-clm-cryosphere-fixes-maint-3.0` @ `3c77ed78f3` | **complete** 2026-08-18 — [report](e3sm_land_developer_campaign2_maint-3.0_report.md) |
| 1 — master | `a899004464` | `lnd/port-clm-cryosphere-fixes-master` @ `fbfcc93f52` | **complete** 2026-08-14 |

Procedure: [`e3sm_land_developer_testing_procedure.md`](e3sm_land_developer_testing_procedure.md).

---

## Campaign 2 — maint-3.0 (complete)

**Full report:** [`e3sm_land_developer_campaign2_maint-3.0_report.md`](e3sm_land_developer_campaign2_maint-3.0_report.md). Overlay: [`frontier_maint-3.0_testing_overlay.md`](frontier_maint-3.0_testing_overlay.md).

**Date:** 2026-08-17–18  
**Machine:** Frontier (`craygnu` overlay, project `cli115`)  
**Status:** Generate and compare **complete**. 50/50 RUN PASS; 45 BASELINE DIFF vs gold (expected science); 5 MOSART PASS; restarts and namelists clean; 2 FATES MEMLEAK already on parent. Machines PR saved for the next step.

| Item | Value |
|---|---|
| Branch | [`lnd/port-clm-cryosphere-fixes-maint-3.0`](https://github.com/daliwang/E3SM/tree/lnd/port-clm-cryosphere-fixes-maint-3.0) @ `3c77ed78f3` |
| Parent / gold | `maint-3.0` @ `34bd782d18` |
| Suite | `e3sm_land_developer` — not full `e3sm_developer` |
| Generate (`-g`) | `-t 34bd782d18`, cases `*.G.34bd782d18` — 50/50 GENERATE PASS |
| Compare (`-c`) | `-t 3c77ed78f3`, cases `*.C.3c77ed78f3` — 45 BASELINE FAIL, 5 PASS |
| Personal baseline root | `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines` |
| Gold files | `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines/34bd782d18/` |
| Scratch / `cs.status` | `/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch` |
| Walltime | `01:30:00` (campaign 1 r05 tests timed out at 45 min; both finished here) |
| Compiler | `craygnu` (local overlay; same stack as campaign 1) |
| Driver logs | `docs/e3sm_land_developer_generate_34bd782d18.nohup.log`, `docs/e3sm_land_developer_compare_3c77ed78f3.nohup.log` |

```bash
module load cray-python/3.11.7
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.34bd782d18   # generate
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.3c77ed78f3   # compare
```

Do not bless into shared Frontier gold.

---

## Campaign 1 — `lnd/port-clm-cryosphere-fixes-master`

**Date:** 2026-08-14  
**Machine:** Frontier (`craygnu`, project `cli115`)  
**Status:** Compare suite **complete**. Answer changes vs parent master are widespread and consistent with the five science commits. Restarts and namelists are clean. Two r05 tests still need a longer walltime.

This note is for land-team review of the fork branch. Procedure and launch commands: [`e3sm_land_developer_testing_procedure.md`](e3sm_land_developer_testing_procedure.md).

| Item | Value |
|---|---|
| Branch | [`lnd/port-clm-cryosphere-fixes-master`](https://github.com/daliwang/E3SM/tree/lnd/port-clm-cryosphere-fixes-master) @ `fbfcc93f52` |
| Parent / gold | fork `master` @ `a899004464` (synced 2026-08-13) |
| Suite | `e3sm_land_developer` (55 tests) — not full `e3sm_developer` |
| Generate (`-g`) | `-t a899004464`, cases `*.G.a899004464` |
| Compare (`-c`) | `-t fbfcc93f52`, cases `*.C.fbfcc93f52` |
| Personal baseline root | `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines` |
| Gold files | `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines/a899004464/` |
| Scratch / `cs.status` | `/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch` |
| E3SM tree | `/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM` |

Gold was written only to the **personal** kmELM baseline root. The shared Frontier path `/lustre/orion/cli115/world-shared/e3sm/baselines/frontier/$COMPILER` was not used.

---

## Recommendation

1. Treat **BASELINE DIFF** as expected for this PR. Do **not** bless into shared Frontier gold until reviewers agree the diffs match the science.
2. Restarts (`COMPARE_base_rest`) and namelists (`NLCOMP`) **PASS** on every test that finished. The branch is internally bit-for-bit.
3. MOSART-only tests **PASS** vs gold (ELM physics not exercised).
4. The four **MEMLEAK** FAILs are already present on parent master generate; they are not new on this branch.
5. Optional follow-up: resubmit the two r05 tests with walltime > 45 min (`elm-cbudget`, `elm-V2_ELM_MOSART_features`). Both also timed out on generate, so they have no gold either.

---

## What is on the branch

Cherry-picked onto `a899004464` (fork `master`). Not included: CPL_BYPASS longitude lookup, CRUJRA/OLMT, Pathfinder machine files.

| Commit | Subject |
|---|---|
| `c304fff2d1` | Port CLM fractional-snow energy and melt-compaction fixes |
| `3f7fd0f8cb` | Port CLM bedrock heat capacity fix in SoilTemperatureMod |
| `5bdf5f2212` | Port CLM active-element masking for ELM accumulators |
| `4b7a01afc3` | Bug fixes for surface water runoff calculation |
| `fbfcc93f52` | Fix snow balance accounting issue |

These are expected to change snow energy, snow mass, soil temperature, accumulators, surface-water runoff, and (by coupling) many downstream ELM/CPL fields.

---

## Headline counts

**Step 1 — generate from parent master** (`cs.status.a899004464`)

| Overall | Count | Notes |
|---|---|---|
| PASS | 49 | Gold files written |
| FAIL (MEMLEAK) | 4 | Gold still written; memleak already on parent |
| FAIL (RUN, walltime) | 2 | No gold; `time=2714` vs 45 min wall |

**Step 2 — compare the branch** (`cs.status.fbfcc93f52`, queue empty as of 2026-08-14 15:53 EDT)

| Overall | Count | Notes |
|---|---|---|
| DIFF | 44 | RUN + restart PASS; history differs from `a899004464` |
| PASS | 5 | MOSART-only; bit-for-bit vs gold |
| FAIL | 6 | 2 RUN walltime + 4 MEMLEAK (those four also BASELINE DIFF) |

**BASELINE DIFF total:** 48 of 53 tests that completed a run (44 DIFF + 4 MEMLEAK).  
**No `PEND`.** Compare `create_test` submitted 08:24 and returned 08:50; Slurm jobs finished later the same day.

---

## Interpretation vs the five commits

| Signal | Result | Why it matters |
|---|---|---|
| `NLCOMP` | PASS on all tests | Namelists unchanged vs gold |
| `COMPARE_base_rest` | PASS on every ERS that finished | Restart is bit-for-bit with itself |
| MOSART-only vs gold | PASS (5/5) | River model answers unchanged when ELM is not the science |
| ELM I-compsets vs gold | DIFF | Snow, soil T, runoff, albedo, fluxes |
| FATES vs gold | DIFF | Same land physics under FATES |
| Debug (`ERS_D` / `SMS_D`) | DIFF, not crash | No debug-build failure |

The diffs line up with the science, not with a compile or restart bug.

### Sample `cprnc` (branch vs gold `a899004464`)

`ERS_Ld150...elm-snowveg_arctic` ELM `h0` (most relevant to snow/veg):

- 562 fields compared; **414** with non-zero differences; no missing fields, no fill-pattern change.
- Example RMS (normalized): `FSNO` 8.1e-4 (1.3e-2), `H2OSNO` 4.5e-2 (2.9e-2), `SNOWDP` 9.2e-5 (9.2e-3), `QSNOMELT` 6.4e-8 (1.2e-2), `QSNOFRZ` 1.3e-7 (3.7e-1), `QOVER` 7.5e-7 (5.3e-1), `QH2OSFC` 7.2e-7 (9.5), `H2OSFC` 1.8e-1 (1.4), `QRUNOFF` 2.9e-8 (2.0e-2), `TSOI` 1.8e-1 (6.3e-4), `FGR` 1.4e-1 (1.1e-2).

`ERS...elm-surface_water_dynamics` coupler hist: 159 fields, **28** differ. `l2x_Flrl_rofsur` normalized RMS ~12 (surface runoff), plus `l2x_Sl_snowh`, albedo, latent/sensible heat.

`ERS_D...elm-koch_snowflake` and `ERS...elm-vst` coupler hist: 186 fields, **41** differ; restart `cprnc` on the same files is **IDENTICAL**.

---

## Tests that PASS vs gold (MOSART-only)

These are bit-for-bit with `a899004464`. Expected: the five commits do not change MOSART.

- `ERS.MOS_USRDAT.RMOSGPCC.frontier_craygnu.mosart-mos_usrdat`
- `ERS.MOS_USRDAT.RMOSNLDAS.frontier_craygnu.mosart-sediment`
- `ERS.r05_r05.RMOSGPCC.frontier_craygnu.mosart-gpcc_1972`
- `ERS.r05_r05.RMOSGPCC.frontier_craygnu.mosart-heat`
- `SMS.MOS_USRDAT.RMOSGPCC.frontier_craygnu.mosart-unstructure`

---

## Tests that FAIL (not science DIFF)

### RUN — 45-minute walltime (same two as generate)

`time≈2696–2702` s on compare; `time=2714` on generate. No BASELINE phase.

| Test | Generate | Compare |
|---|---|---|
| `ERS.r05_r05.ICNPRDCTCBC.frontier_craygnu.elm-cbudget` | RUN FAIL | RUN FAIL |
| `ERS.r05_r05.IELM.frontier_craygnu.elm-V2_ELM_MOSART_features` | RUN FAIL | RUN FAIL |

Resubmit with `--walltime 01:30:00` (or similar) if these need to be in the PR table.

### MEMLEAK — present on parent master

Memory numbers on compare match generate to ~1 MB. Not introduced by the cryosphere/hydrology commits. All four also **BASELINE DIFF**.

| Test | Generate memleak | Compare memleak |
|---|---|---|
| `SMS_D_Ld20.f45_f45.IELMFATES...elm-fates_rd` | 1248 → 2180 MB / 18 d | 1249 → 2182 MB / 18 d |
| `SMS_Ld20.f45_f45.IELMFATES...elm-fates_eca` | 1241 → 2170 MB / 18 d | 1241 → 2169 MB / 18 d |
| `SMS_Ly1.ELM_USRDAT.I1850CNPRDCTCBC...elm-kilocraft` | 362 → 411 MB / 1129 d | 362 → 412 MB / 1129 d |
| `SMS_Ly5_P1x1...IELMCNCROP...elm-force_netcdf_pio` | 323 → 362 MB / 41129 d | 323 → 362 MB / 41129 d |

---

## Tests that DIFF vs `a899004464`

Overall DIFF (44), plus the four MEMLEAK tests above (also BASELINE DIFF). Grouped for PR text.

### Debug ELM

- `ERS_D.f09_f09.IELM.frontier_craygnu.elm-koch_snowflake`
- `ERS_D.f09_f09.IELM.frontier_craygnu.elm-solar_rad`
- `ERS_D.f09_g16.I1850ELMCN.frontier_craygnu`
- `ERS_D.f19_f19.IELM.frontier_craygnu.elm-ic_f19_f19_ielm`
- `ERS_D.f19_g16.I1850GSWCNPRDCTCBC.frontier_craygnu.elm-ctc_f19_g16_I1850GSWCNPRDCTCBC`
- `ERS_D.ne4pg2_oQU480.I20TRELM.frontier_craygnu.elm-disableDynpftCheck`

### Standard ELM I-compsets

- `ERS.1x1_icycape.I1850GSWCNPRDCTCBC.frontier_craygnu.elm-polygonal_tundra`
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
- `ERS_Vmct.hcru_hcru.IELM.frontier_craygnu.elm-multi_inst`
- `SMS_Ld1.hcru_hcru.I1850CRUELMCN.frontier_craygnu`
- `SMS.r05_r05.I1850ELMCN.frontier_craygnu.elm-qian_1948`
- `SMS.r05_r05.IELM.frontier_craygnu.elm-topounit`
- `SMS.r05_r05.IELM.frontier_craygnu.elm-topounit_im2`
- `SMS_Vmct.ELM_USRDAT.GTSM2ELM.frontier_craygnu.elm-lnd_docn_1way`

### USRDAT / hydrology / snow-veg

- `ERS.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-usrpft_codetest_I1850CNPRDCTCBC`
- `ERS.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-usrpft_default_I1850CNPRDCTCBC`
- `ERS.ELM_USRDAT.I1850ELM.frontier_craygnu.elm-usrdat`
- `ERS.ELM_USRDAT.IELM.frontier_craygnu.elm-finetop_rad`
- `ERS.ELM_USRDAT.IELM.frontier_craygnu.elm-surface_water_dynamics`
- `ERS_Ld150.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-snowveg_arctic`
- `ERS.r05_r05.IELM.frontier_craygnu.elm-lnd_rof_2way`

### FATES

- `ERS_D_Ld15.f45_g37.IELMFATES.frontier_craygnu.elm-fates_cold_treedamage`
- `ERS_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates`
- `ERS_Ld30.f45_f45.IELMFATES.frontier_craygnu.elm-fates_satphen`
- `ERS_Ld30.f45_g37.IELMFATES.frontier_craygnu.elm-fates_cold_sizeagemort`
- `SMS_Ld5_PS.f19_g16.IELMFATES.frontier_craygnu.elm-fates_cold`
- `SMS_D_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates_rd` *(also MEMLEAK)*
- `SMS_Ld20.f45_f45.IELMFATES.frontier_craygnu.elm-fates_eca` *(also MEMLEAK)*

### Crop / smallville

- `SMS_Ly2_P1x1.1x1_smallvilleIA.I20TRGSWCNPCROP.frontier_craygnu.elm-lulcc_sville`
- `SMS_Ly2_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-fan`
- `SMS_Ly5_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-per_crop`
- `SMS_Ly5_P1x1.1x1_smallvilleIA.IELMCNCROP.frontier_craygnu.elm-force_netcdf_pio` *(also MEMLEAK)*
- `SMS_Ly1.ELM_USRDAT.I1850CNPRDCTCBC.frontier_craygnu.elm-kilocraft` *(also MEMLEAK)*

---

## How to re-read status

```bash
module load cray-python/3.11.7
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.a899004464   # generate
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.fbfcc93f52   # compare
```

Driver logs:

- `/lustre/orion/cli115/world-shared/wangd/kmELM/docs/e3sm_land_developer_compare.nohup.log`
- `/lustre/orion/cli115/world-shared/wangd/kmELM/docs/e3sm_land_developer_compare_fbfcc93f52.log`

Per-test `cprnc` lives under each `*.C.fbfcc93f52/` case in scratch (`TestStatus.log` and `*.cprnc.out`).

Launch scripts: `kmELM/scripts/e3sm_land_developer_{generate,compare}.sh` with shared settings in `e3sm_land_developer.conf.sh`.

---

## Suggested PR language

> `e3sm_land_developer` on Frontier/`craygnu` vs personal gold from parent `a899004464`: namelists unchanged; all completed ERS restarts bit-for-bit. 48 ELM tests DIFF vs gold (snow fraction/mass, melt/freeze, surface water, runoff, soil T, coupled fluxes), consistent with the five CLM-port / hydrology / snow-balance commits. Five MOSART-only tests PASS. Four MEMLEAK FAILs match parent master. Two r05 tests (`elm-cbudget`, `elm-V2_ELM_MOSART_features`) hit the 45-minute wall on both generate and compare.
