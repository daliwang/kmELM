# Text for the land science PR (Frontier / `maint-3.0`)

Open against **`E3SM-Project/E3SM` `maint-3.0`**, not `master`.  
Head: `daliwang:lnd/port-clm-cryosphere-fixes-maint-3.0` @ `3c77ed78f3`.  
This is **not** a machines commit. Overlay stays in kmELM.

Compare URL (create PR in the browser if `gh` is not logged in on Frontier):

https://github.com/E3SM-Project/E3SM/compare/maint-3.0...daliwang:lnd/port-clm-cryosphere-fixes-maint-3.0?expand=1

Existing master PR [#8638](https://github.com/E3SM-Project/E3SM/pull/8638) (`lnd/port-clm-cryosphere-fixes-master`) should be closed or left as the master counterpart; do not retarget it. This is the `maint-3.0` PR.

---

**Title**

```
Port CLM cryosphere and hydrology fixes into ELM on maint-3.0
```

**Body**

```markdown
## Summary
- Port CLM cryosphere / hydrology bug fixes into ELM on `maint-3.0` (fractional-snow energy and melt compaction, bedrock heat capacity, active-element accumulator masking, surface-water runoff, snow balance accounting).
- ELM biogeophysics and accumulator code only. Same five commits as the master branch PR (#8638), cherry-picked onto `maint-3.0` @ `34bd782d18`.
- Answer-changing. Do not bless new gold until reviewers agree the diffs match the science.

## Commits
- Port CLM fractional-snow energy and melt-compaction fixes (`36deec7f46`)
- Port CLM bedrock heat capacity fix in SoilTemperatureMod (`a63fb07099`)
- Port CLM active-element masking for ELM accumulators (`45e8c6e260`)
- Bug fixes for surface water runoff calculation (`1b19ba5e35`)
- Fix snow balance accounting issue (`3c77ed78f3`)

## Testing (Frontier)

`e3sm_land_developer` on Frontier vs personal gold from parent `maint-3.0` @ `34bd782d18` (50 tests). Full report: https://github.com/daliwang/kmELM/blob/main/docs/e3sm_land_developer_campaign2_maint-3.0_report.md

- Branch: `lnd/port-clm-cryosphere-fixes-maint-3.0` @ `3c77ed78f3`
- Gold generated from parent `maint-3.0` @ `34bd782d18`, then compared on this branch
- Personal baseline root (not shared Frontier gold): `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines`

| Result | Count | Notes |
|---|---|---|
| RUN PASS | 50/50 | Generate and compare |
| BASELINE DIFF | 45 | Expected: snow, soil T, runoff, coupled fluxes change vs `34bd782d18` |
| PASS vs gold | 5 | MOSART-only tests; bit-for-bit |
| MEMLEAK FAIL | 2 | FATES `elm-fates_rd` / `elm-fates_eca`; already present on parent gold |

Namelists (`NLCOMP`) PASS on all 50. All 39 ERS tests passed `COMPARE_base_rest` (restart is bit-for-bit with itself). Debug builds DIFF; they do not crash. Both r05 ELM tests finished at 90 min (they timed out at 45 min on the master campaign).

`maint-3.0` as shipped cannot use the current OLCF GNU stack (`PrgEnv-gnu/8.3.3` is gone; compiler name is still `gnu`; Lmod paths are login-only). Tests used a **local overlay** (not in this PR) that matches master’s working `craygnu` stack (`Core/25.03`, `PrgEnv-gnu`, `cpe/25.09`, `gcc-native/14.2`) on maint-3.0’s CIME skeleton. Overlay: https://github.com/daliwang/kmELM/blob/main/docs/frontier_maint-3.0_testing_overlay.md

This PR is science only. A separate `maint-3.0` machines PR (later) should add `craygnu` + cmake macros + `/opt/cray/pe/lmod` paths so later land PRs do not need the overlay. Do not copy master’s full Frontier machine block (`frontier_slurm`, ADIOS2/BLOSC2) onto this tag.
```
