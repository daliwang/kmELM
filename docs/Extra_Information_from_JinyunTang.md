# Extra file locations from Jinyun Tang

Jinyun reported that the five custom ELM/MOSART inputs for the AI4ELM AD spinup
are available under the **NERSC E3SM CFS inputdata** tree (not only under his
home/`pscratch` paths). Original note (verbatim paths):

```text
fsurdat = '/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/surfdata/surfdata_0.5x0.5_50pfts_20250528.nc'
paramfile = '/global/cfs/cdirs/e3sm/inputdata//lnd/clm2/paramdata/clm_params_c251006.nc'
frivinp_rtm = '/global/cfs/cdirs/e3sm/inputdata/rof/mosart/MOSART_Global_half_20250523.nc'
parafile = '/global/cfs/cdirs/e3sm/inputdata/rof/mosart/global_reservoir_halfdegree_c20200917.nc'
stream_fldfilename_ndep = '/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/ndepdata/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc'
```

(The double slash in `paramfile` is harmless.)

## Status on Frontier (checked 2026-10-27)

| File | NERSC CFS (source) | OLCF `DIN_LOC_ROOT` | Flat staging `ai4elm_spinup/` (case `user_nl`) |
|---|---|---|---|
| `surfdata_0.5x0.5_50pfts_20250528.nc` | CFS surfdata | **missing** | **missing** |
| `clm_params_c251006.nc` | CFS paramdata | present | **missing** |
| `ndep_from_CMIP7_..._c260515.nc` | CFS ndepdata | **missing** | **missing** |
| `MOSART_Global_half_20250523.nc` | CFS mosart | **missing** | **missing** |
| `global_reservoir_halfdegree_c20200917.nc` | CFS mosart | present | **missing** |

Atmospheric **GSWP3 v1 for 1901–1920** (`Solar` / `Precip` / `TPHWL`) is
**complete** on Frontier. DATM domain
`domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc` is present. No monthly GSWP3
forcing files need Globus for this AD cycle.

## Globus (recommended)

- **Source:** NERSC Perlmutter / CFS — `/global/cfs/cdirs/e3sm/inputdata/...`
- **Path list:** [`../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/GLOBUS_file_list.txt`](../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/GLOBUS_file_list.txt)
- **Destination (matches current case namelists):**  
  `/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup/`  
  (place only the basenames in that directory)

Minimal transfer if you instead install into OLCF DIN and retarget `user_nl_*`:
only the three **missing** DIN files above.

## rsync / scp from Perlmutter → Frontier (flat staging)

```bash
DEST=/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup
SRC=wangd@perlmutter.nersc.gov
mkdir -p "$DEST"

rsync -avP --info=progress2 \
  "$SRC:/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/surfdata/surfdata_0.5x0.5_50pfts_20250528.nc" \
  "$SRC:/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/paramdata/clm_params_c251006.nc" \
  "$SRC:/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/ndepdata/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc" \
  "$SRC:/global/cfs/cdirs/e3sm/inputdata/rof/mosart/MOSART_Global_half_20250523.nc" \
  "$SRC:/global/cfs/cdirs/e3sm/inputdata/rof/mosart/global_reservoir_halfdegree_c20200917.nc" \
  "$DEST/"
```

See also [`AI4ELM_Spinup_repeat.md`](./AI4ELM_Spinup_repeat.md) and
[`../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md`](../case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md).
