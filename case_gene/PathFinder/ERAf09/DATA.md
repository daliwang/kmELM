# Forcing and input data for Pathfinder ERAf09 cases

DATM reads `$DIN_LOC_ROOT_CLMFORC/ERA5_6hr_f09`. The Pathfinder create scripts set:

```text
DIN_LOC_ROOT_CLMFORC=/projects/hpcl-cli185/proj-shared/wangd/kiloCraft
DIN_LOC_ROOT         =/projects/hpcl-cli185/world-shared/e3sm/inputdata
```

Do **not** copy the native 0.25° ERA5 tree. The cases use the remapped f09 product only.

## What to copy

| Set | Size | When |
|---|---|---|
| **Smoke** — 1980 only (108 files) | **~3 GB** | First Pathfinder test |
| **Spinup** — 1980–1999 (2160 files) | **~58 GB** | AD + final (required) |
| Full archive — 1979–2022 (4752 files) | ~126 GB | Optional; years outside 1980–1999 are unused |
| Domain file (real copy, not a symlink) | 5.3 MB | Always |
| Stock ELM/MOSART/mapping (`WITH_STOCK=1`) | **~1.4 GB** | Only if Pathfinder `DIN_LOC_ROOT` is incomplete |

Frontier source: `/lustre/orion/cli115/world-shared/wangd/kiloCraft/ERA5_6hr_f09`  
Pathfinder dest: `/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/ERA5_6hr_f09`

The Frontier `domain.lnd.fv0.9x1.25_gx1v6.090309.nc` is a **symlink** into `e3sm/inputdata`. A naive `rsync` without `--copy-links` leaves a dangling path on Pathfinder. The stage script copies it as a regular file.

Layout after transfer:

```text
ERA5_6hr_f09/
  domain.lnd.fv0.9x1.25_gx1v6.090309.nc
  lwdn/  pbot/  prec/  swdn/  tbot/  tdew/  wind/
    elmforc.ERA5.c2018.0.9x1.25.<var>.YYYY-MM.nc
```

## Transfer (run on Pathfinder)

Pull from Frontier Lustre over SSH. The script opens one OLCF login (`frontier.olcf.ornl.gov`) and reuses it for rsync (RSA once).

```bash
# On Pathfinder after git pull of kmELM:
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM

# 1) smoke year only (~3 GB)
MODE=smoke bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh

# 2) spinup cycle (~58 GB) — needed for AD/final
MODE=spinup bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh

# Optional: also pull the ~1.4 GB stock files listed below
MODE=spinup WITH_STOCK=1 bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh

# Preview commands without transferring
DRY_RUN=1 MODE=smoke bash case_gene/PathFinder/ERAf09/stage_eraf09_forcing.sh
```

The script logs into Frontier as `wangd` (not the Pathfinder `$USER`). Override `SRC_HOST`, `SRC_USER`, `DEST_FORC`, or `DEST_DIN` if needed. Globus from the Frontier Lustre collection to Pathfinder `/projects` is an alternative for the large spinup copy; still land a regular domain file at the dest path.

## Stock files (if `./check_input_data` fails)

These live under Frontier `DIN_LOC_ROOT` (`.../e3sm/inputdata`). CIME can download many of them; transferring the list below is faster and matches the Frontier AD case exactly.

| File | ~size |
|---|---|
| `share/domains/domain.lnd.fv0.9x1.25_gx1v6.090309.nc` | 5 MB |
| `lnd/clm2/surfdata_map/surfdata_0.9x1.25_simyr1850_c180306.nc` | 456 MB |
| `lnd/clm2/ndepdata/fndep_elm_cbgc_exp_simyr1849-2101_1.9x2.5_ssp245_c240903.nc` | 40 MB |
| `lnd/clm2/pdepdata/fpdep_clm_hist_simyr2000_1.9x2.5_c150929.nc` | <1 MB |
| `lnd/clm2/firedata/elmforc.Li_20181205_mod_hist_SSP2_CMIP6_hdm_0.5x0.5_AVHRR_simyr1850-2100_c240906.nc` | 251 MB |
| `atm/datm7/NASA_LIS/clmforc.Li_2012_climo1995-2011.T62.lnfm_Total_c140423.nc` | 201 MB |
| `lnd/clm2/snicardata/snicar_optics_5bnd_mam_c160322.nc` | <1 MB |
| `lnd/clm2/snicardata/snicar_drdt_bst_fit_60_c070416.nc` | <1 MB |
| `lnd/clm2/paramdata/clm_params_c211124.nc` | <1 MB |
| `lnd/clm2/paramdata/CNP_parameters_c180529.nc` | <1 MB |
| `rof/mosart/US_reservoir_8th_NLDAS3_c20161220_updated_20170314.nc` | 327 MB |
| `rof/mosart/MOSART_global_half_20180721a.nc` | 41 MB |
| `share/meshes/rof/SCRIPgrid_0.5x0.5_nomask_c110308.nc` | 21 MB |
| `lnd/clm2/mappingdata/maps/0.9x1.25/map_0.9x1.25_nomask_to_0.5x0.5_nomask_aave_da_c120522.nc` | 39 MB |
| `lnd/clm2/mappingdata/maps/0.9x1.25/map_0.5x0.5_nomask_to_0.9x1.25_nomask_aave_da_c121019.nc` | 39 MB |

`DIN_LOC_ROOT` on this Pathfinder is `/projects/hpcl-cli185/world-shared/e3sm/inputdata`. Those stock files are already there, so `WITH_STOCK=1` is not needed. If you do pull them, set `DEST_DIN` to that `inputdata` directory, not the parent `e3sm` tree.

## Checks on Pathfinder

```bash
FORC=/projects/hpcl-cli185/proj-shared/wangd/kiloCraft/ERA5_6hr_f09
find "$FORC" -name 'elmforc.ERA5.c2018.0.9x1.25.*.19[89][0-9]-*.nc' | wc -l   # 2160
ls -l "$FORC/domain.lnd.fv0.9x1.25_gx1v6.090309.nc"   # regular file, not a dangling symlink
```
