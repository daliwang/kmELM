# Pathfinder data staging for AI4ELM GSWP3 TOP/crop

Science and custom-file provenance: [`docs/AI4ELM_Spinup_repeat.md`](../../../docs/AI4ELM_Spinup_repeat.md),
[`docs/Extra_Information_from_JinyunTang.md`](../../../docs/Extra_Information_from_JinyunTang.md).

## Destinations (Pathfinder)

| Role | Path |
|---|---|
| Stock DIN | `/projects/hpcl-cli185/world-shared/e3sm/inputdata` |
| GSWP3 forcing | `$DIN/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/{Solar,Precip,TPHWL}` |
| Custom five NetCDFs | `/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup/` |
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

## Verify

```bash
CASE=.../e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke
cd "$CASE"
./check_input_data   # expect 0 missing before submit
```
