# Staging input data for AI4ELM GSWP3 TOP/crop AD (Frontier)

Case namelists already point at the destinations below. Filenames must match
exactly (no rename unless you also edit `user_nl_elm` / `user_nl_mosart`).

Verify what’s missing anytime:

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup
module load cray-python/3.11.7
./check_input_data
```

---

## A. Five custom NetCDFs (must copy from NERSC)

These are **not** on the E3SM inputdata server. They live under jinyun’s
Perlmutter paths (see `docs/AI4ELM_Spinup_repeat.md`). You need read access
there (or ask the owner to stage a shared copy).

### Destination (Frontier)

```text
/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup/
```

| Destination basename | NERSC source |
|---|---|
| `surfdata_0.5x0.5_50pfts_20250528.nc` | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/surfdata_0.5x0.5_50pfts_20250528.nc` |
| `clm_params_c251006.nc` | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/clm_params_c251006.nc` |
| `ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc` | `/global/homes/j/jinyun/pscratch/cmip7/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc` |
| `MOSART_Global_half_20250523.nc` | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/MOSART_Global_half_20250523.nc` |
| `global_reservoir_halfdegree_c20200917.nc` | `/global/homes/j/jinyun/cbgcv3_scratch/input_data/global_reservoir_halfdegree_c20200917.nc` |

### Option 1 — `scp` / `rsync` from Perlmutter → Frontier

On **Perlmutter** (after you can log in), push to Frontier:

```bash
DEST=wangd@frontier.olcf.ornl.gov:/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup/
mkdir -p /tmp/ai4elm_stage   # optional local bundle

# Prefer rsync if you have SSH Frontier↔Perlmutter both ways; else scp.
rsync -avP --info=progress2 \
  /global/homes/j/jinyun/cbgcv3_scratch/input_data/surfdata_0.5x0.5_50pfts_20250528.nc \
  /global/homes/j/jinyun/cbgcv3_scratch/input_data/clm_params_c251006.nc \
  /global/homes/j/jinyun/cbgcv3_scratch/input_data/MOSART_Global_half_20250523.nc \
  /global/homes/j/jinyun/cbgcv3_scratch/input_data/global_reservoir_halfdegree_c20200917.nc \
  /global/homes/j/jinyun/pscratch/cmip7/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc \
  "$DEST"
```

If you cannot SSH Frontier from Perlmutter, pull **from Frontier** instead
(run on Frontier login):

```bash
DEST=/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup
mkdir -p "$DEST"
# Replace USER with your NERSC username (must be able to read jinyun paths,
# or have jinyun copy into a world-readable staging dir first).
SRC=USER@perlmutter.nersc.gov

scp "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/surfdata_0.5x0.5_50pfts_20250528.nc" "$DEST/"
scp "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/clm_params_c251006.nc" "$DEST/"
scp "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/MOSART_Global_half_20250523.nc" "$DEST/"
scp "$SRC:/global/homes/j/jinyun/cbgcv3_scratch/input_data/global_reservoir_halfdegree_c20200917.nc" "$DEST/"
scp "$SRC:/global/homes/j/jinyun/pscratch/cmip7/ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc" "$DEST/"
```

### Option 2 — Globus (recommended for large/ndep)

1. NERSC endpoint: Perlmutter/CFS (or `/global/homes`, `/pscratch` collections).
2. OLCF endpoint: Frontier/Orion Lustre.
3. Transfer the five files into
   `/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup/`.

### Option 3 — Ask jinyun to drop a tarball

Have the owner create one archive on a path you can read, e.g.:

```bash
# on Perlmutter (owner)
cd /global/homes/j/jinyun/cbgcv3_scratch/input_data
tar -cvf ai4elm_custom_inputs.tar \
  surfdata_0.5x0.5_50pfts_20250528.nc \
  clm_params_c251006.nc \
  MOSART_Global_half_20250523.nc \
  global_reservoir_halfdegree_c20200917.nc
# plus the ndep file from pscratch/cmip7/...
```

Then `scp`/`Globus` the tarball to Frontier and:

```bash
cd /lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup
tar -xvf /path/to/ai4elm_custom_inputs.tar
# ensure ndep basename matches the table above
ls -lh
```

### Confirm custom files

```bash
DEST=/lustre/orion/cli115/proj-shared/wangd/input_data/ai4elm_spinup
ls -lh "$DEST"/{surfdata_0.5x0.5_50pfts_20250528.nc,clm_params_c251006.nc,ndep_from_CMIP7_184901-202312_v2.0_1.9x2.5_aave_c260515.nc,MOSART_Global_half_20250523.nc,global_reservoir_halfdegree_c20200917.nc}
```

If you stage elsewhere, update the three paths in the case’s `user_nl_elm` and
two in `user_nl_mosart`, then `./preview_namelists`.

`./check_input_data --download` **will not** fetch these five files (paths are
absolute custom locations, not under the public inputdata tree).

---

## B. DATM domain `domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc`

Required path (already in `CaseDocs/datm_in`):

```text
/lustre/orion/cli115/world-shared/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc
```

Land domain `domain.lnd.r05_IcoswISC30E3r5.231121.nc` is already present; this
**ne30pg2** DATM target domain is not.

### Option B1 — CIME download (try first)

You can write into the shared `DIN_LOC_ROOT` domains dir on this project. From
the case:

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM/E3SM-ai4elm/e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup
module load cray-python/3.11.7
./check_input_data --download
```

That walks all missing lists (domain + any incomplete GSWP3 months). Confirm:

```bash
ls -lh /lustre/orion/cli115/world-shared/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc
```

If download fails (firewall / server), use B2.

### Option B2 — Copy from NERSC E3SM inputdata

On NERSC the stock file is:

```text
/global/cfs/cdirs/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc
```

From Frontier:

```bash
DIN=/lustre/orion/cli115/world-shared/e3sm/inputdata/share/domains
SRC=USER@perlmutter.nersc.gov:/global/cfs/cdirs/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc
scp "$SRC" "$DIN/"
```

Or from Perlmutter push:

```bash
scp /global/cfs/cdirs/e3sm/inputdata/share/domains/domain.lnd.ne30pg2_IcoswISC30E3r5.231121.nc \
  wangd@frontier.olcf.ornl.gov:/lustre/orion/cli115/world-shared/e3sm/inputdata/share/domains/
```

---

## C. Related: GSWP3 forcing completeness (not the “five custom” files)

`./check_input_data` currently also reports many missing GSWP3 Solar months, and
the OLCF tree has only ~37 files under `Solar`/`Precip`/`TPHWL` (full 1901–1920
needs 240 monthly files each). Streams expect a `TPQW` directory as well.

Stock location:

```text
/lustre/orion/cli115/world-shared/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/
```

NERSC mirror:

```text
/global/cfs/cdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/
```

Either run `./check_input_data --download` until GSWP3 is complete, or `rsync`
the missing years/streams from NERSC into that OLCF directory (~60 GB full set).

---

## D. Ready checklist

```bash
CASE=.../I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup
cd "$CASE"
module load cray-python/3.11.7
./check_input_data   # no missing custom files, domain, or 1901–1920 GSWP3
./case.build
# then short smoke before multi-year AD
```

Do **not** `./case.submit` a multi-year AD segment until A + B are done (and GSWP3
covers 1901–1920).
