# Pathfinder ERAf09 case scripts

Machine-specific create scripts for OLCF **Pathfinder**. Science settings match the completed Frontier `I1850ERACNPRDCTCBC` f09 ERA5 spinup.

Scripts live here. **Cases and runs do not go under `E3SM/`.** They are created at:

```text
${KMELM_ROOT}/e3sm_cases/<case>
${KMELM_ROOT}/e3sm_runs/<case>
```

Default `KMELM_ROOT` is the git toplevel of this repo (on Pathfinder usually `/projects/hpcl-cli185/proj-shared/wangd/kmELM`).

This is not the TES 4 km experiment in `../TES_NORTHERA5/`.

| Script | Role |
|---|---|
| `I1850ERACNPRDCTCBC_f09_smoke.sh` | 5-day 1980 smoke (`NCPL=24`) |
| `I1850ERACNPRDCTCBC_f09_adspinup.sh` | AD 400 yr, DATM 1980–1999 |
| `I1850ERACNPRDCTCBC_f09_finalspinup.sh` | Final 800 yr after AD |

Process note: `docs/I1850ERACNPRDCTCBC_f09_era5_spinup_process.md`

## Defaults

| Item | Value |
|---|---|
| Machine | `pathfinder` / `gnu` / `openmpi` |
| Compset / res | `I1850ERACNPRDCTCBC` / `f09_f09` |
| DATM | `ERAf09`, 1980–1999 (smoke: 1980 only) |
| `DIN_LOC_ROOT` | `/projects/hpcl-cli185/world-shared/e3sm` |
| `DIN_LOC_ROOT_CLMFORC` | `/projects/hpcl-cli185/proj-shared/wangd/kiloCraft` |
| Forcing | `$DIN_LOC_ROOT_CLMFORC/ERA5_6hr_f09` |
| Queue | `batch_ccsi` |
| PE | 1280 tasks, 128 MPI/node (smoke: 128) |
| Walltime | 06:00:00 (smoke: 02:00:00) |

Requires E3SM with `%ERAf09` (branch `lnd/clm_glacier_fixes_era5`) and Pathfinder machine files in that tree. Stage 1980–1999 forcing before submitting AD/final.

```bash
# On Pathfinder, after E3SM and forcing are in place:
bash case_gene/PathFinder/ERAf09/I1850ERACNPRDCTCBC_f09_smoke.sh
# then: cd ${KMELM_ROOT}/e3sm_cases/I1850ERACNPRDCTCBC_f09_smoke1980 && ./case.build && ./case.submit

bash case_gene/PathFinder/ERAf09/I1850ERACNPRDCTCBC_f09_adspinup.sh
# wait for .../e3sm_runs/I1850ERACNPRDCTCBC_f09_adspinup/run/...elm.r.0401-01-01-00000.nc

bash case_gene/PathFinder/ERAf09/I1850ERACNPRDCTCBC_f09_finalspinup.sh
```

Override paths or PE with environment variables (`KMELM_ROOT`, `E3SM_DIN`, `FORC_ROOT`, `NTASKS_ALL`, `WALLTIME`, `JOB_QUEUE`, …).
