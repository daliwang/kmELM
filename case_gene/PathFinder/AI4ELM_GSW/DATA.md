# Pathfinder data staging for AI4ELM GSWP3 TOP/crop

Science and custom-file provenance: [`docs/AI4ELM_Spinup_repeat.md`](../../../docs/AI4ELM_Spinup_repeat.md),
[`docs/Extra_Information_from_JinyunTang.md`](../../../docs/Extra_Information_from_JinyunTang.md).  
Pathfinder inventory, 15-node case, and LandSim plan (2026-11-12):
[`docs/AI4ELM_Pathfinder_GSWP3_status_and_LandSim_plan.md`](../../../docs/AI4ELM_Pathfinder_GSWP3_status_and_LandSim_plan.md).

## Destinations (Pathfinder)

| Role | Path |
|---|---|
| Stock DIN | `/projects/hpcl-cli185/world-shared/e3sm/inputdata` |
| GSWP3 forcing | `$DIN/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/{Solar,Precip,TPHWL}` |
| Custom five NetCDFs | `/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup/` |
| Jinyun restarts (Frontier copy, 2026-11-12) | `$CUSTOM/AI_restart_files_Jinyun/` (`elm.r.0021` AD 22 GB; `rg.spinup` `elm.r.0202` 47 MB — verify; **no `0166`**) |
| DATM domain | `$DIN/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc` |

For the AD/smoke cycle you need **1901–1920** complete in Solar, Precip, and TPHWL
(240 months each). The TPQW stream reads **TPHWL** (no separate TPQW directory).

## Recommended: pull from Frontier (already staged there)

On **Pathfinder**:

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
# MODE=smoke → customs + domain + check GSWP3 years present
# MODE=spinup → also rsync missing 1901-1920 GSWP3 months from Frontier
MODE=spinup bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh
```

Defaults pull from `wangd@frontier.olcf.ornl.gov`. Override with `SRC_HOST` /
`SRC_USER` if needed.

## Manual scp of the five customs (from Frontier or NERSC CFS)

Pathfinder destination:

```bash
DEST=/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup
mkdir -p "$DEST"
```

From Frontier staging (already verified on OLCF):

```text
/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup/
```

From NERSC CFS (Jinyun paths):

```text
/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/surfdata/surfdata_0.5x0.5_50pfts_20250528.nc
/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/paramdata/clm_params_c251006.nc
/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/ndepdata/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc
/global/cfs/cdirs/e3sm/inputdata/rof/mosart/MOSART_Global_half_20250523.nc
/global/cfs/cdirs/e3sm/inputdata/rof/mosart/global_reservoir_halfdegree_c20200917.nc
```

## Jinyun restarts

Frontier source (OTP/passcode):

```text
/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/AI_restart_files_Jinyun
```

```bash
DEST=/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup/AI_restart_files_Jinyun
mkdir -p "$DEST"
scp -r wangd@frontier.olcf.ornl.gov:/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/AI_restart_files_Jinyun/. \
  "$DEST/"
```

On Pathfinder as of 2026-11-12: AD `elm.r.0021` (22 GB, `gridcell=94838`) and rg/normal `elm.r.0202` (47 MB, same dims — verify before LandSim). **`elm.r.0166` is not present.** The 15-node case `user_nl_elm` still names `0166`; retarget `finidat` to `0021` or copy `0166` before submit. Details: the status/LandSim report linked above.

Perlmutter `0166` (if still needed):

```text
/pscratch/sd/j/jinyun/e3sm_scratch/pm-cpu/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup/run/20261009.I1850GSWCNPRDCTCBCTOPPHSWFMCROP.ad.spinup.elm.r.0166-01-01-00000.nc
```

## Verify

```bash
CASE=.../e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke
cd "$CASE"
./check_input_data   # expect 0 missing before submit
```
