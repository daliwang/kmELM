# Text for the land science PR (Frontier / `maint-3.0`)

Copy into the E3SM PR body for `lnd/port-clm-cryosphere-fixes-maint-3.0`. This is **not** a machines commit.

```markdown
## Testing (Frontier)

`e3sm_land_developer` on Frontier vs personal gold from parent `maint-3.0` @ `34bd782d18` (50 tests).

- Generate: 50/50 RUN+GENERATE PASS (2 FATES MEMLEAK already on parent; gold still written).
- Compare (`3c77ed78f3` vs `34bd782d18`): 50/50 RUN PASS; 45 BASELINE DIFF (expected science); 5 MOSART-only PASS; restarts and namelists PASS on every test that has those phases.

`maint-3.0` as shipped cannot use the current OLCF GNU stack (`PrgEnv-gnu/8.3.3` is gone; compiler name is still `gnu`; Lmod paths are login-only). Tests used a **local overlay** (not in this PR) that matches master’s working `craygnu` stack (`Core/25.03`, `PrgEnv-gnu`, `cpe/25.09`, `gcc-native/14.2`) on maint-3.0’s CIME skeleton. Overlay: https://github.com/daliwang/kmELM (docs/frontier_maint-3.0_testing_overlay.md). Full counts: docs/e3sm_land_developer_campaign2_maint-3.0_report.md.

This PR is science only (five cryosphere/hydrology commits). A separate `maint-3.0` machines PR should add `craygnu` + cmake macros + `/opt/cray/pe/lmod` paths so later land PRs do not need the overlay. Do not copy master’s full Frontier machine block (`frontier_slurm`, ADIOS2/BLOSC2) onto this tag.
```
