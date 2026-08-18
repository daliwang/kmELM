# Text for the land science PR (Frontier / `maint-3.0`)

Copy into the E3SM PR body for `lnd/port-clm-cryosphere-fixes-maint-3.0`. This is **not** a machines commit.

```markdown
## Testing (Frontier)

`e3sm_land_developer` on Frontier vs personal gold from parent `maint-3.0` @ `34bd782d18`.

`maint-3.0` as shipped cannot use the current OLCF GNU stack (`PrgEnv-gnu/8.3.3` is gone; compiler name is still `gnu`; Lmod paths are login-only). Tests used a **local overlay** (not in this PR) that matches master’s working `craygnu` stack (`Core/25.03`, `PrgEnv-gnu`, `cpe/25.09`, `gcc-native/14.2`) on maint-3.0’s CIME skeleton. Overlay and procedure: https://github.com/daliwang/kmELM (docs/frontier_maint-3.0_testing_overlay.md).

This PR is science only (five cryosphere/hydrology commits). A separate `maint-3.0` machines PR should add `craygnu` + cmake macros + `/opt/cray/pe/lmod` paths so later land PRs do not need the overlay. Do not copy master’s full Frontier machine block (`frontier_slurm`, ADIOS2/BLOSC2) onto this tag.
```
