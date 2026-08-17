# I1850ERACNPRDCTCBC f09 AD + final spinup

Companion to [I1850ERACNPRDCTCBC_f09_smoke1980_report.md](./I1850ERACNPRDCTCBC_f09_smoke1980_report.md).
Smoke (5-day 1980) succeeded; this note covers production spinup setup.

## Forcing cycle

- **DATM cycle:** 1980–1999 (20 years); `DATM_CLMNCEP_YR_START=1980`, `YR_END=1999`, `YR_ALIGN=1`
- **On disk:** full **1979–2022** under `kiloCraft/ERA5_6hr_f09/` (~126 GB; 108 files/year)
- **2000+:** present on disk but **not** used in the 20-year spinup cycle
- Expected files for spinup cycle: \(20 × 12 × 9 = 2160\) — **complete**

## Cases

Canonical scripts (Frontier-specific, same layout idea as PathFinder / ORNL_baseline):

`case_gene/Frontier/I1850ERACNPRDCTCBC_f09/`

Thin wrappers also exist under `scripts/frontier/` for convenience.

### AD — `I1850ERACNPRDCTCBC_f09_adspinup`

- Case: `.../E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_adspinup`
- Script: `case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh`
- Length: **400 yr** (`STOP_N=20`, `RESUBMIT=19`, `REST_N=20`)
- AD on: `ELM_ACCELERATED_SPINUP=on`, `spinup_state=1`, cold start `RUN_STARTDATE=0001-01-01`
- Walltime: **06:00:00**
- Expected end restart: `.../e3sm_runs/..._adspinup/run/..._adspinup.elm.r.0401-01-01-00000.nc`

### Final — `I1850ERACNPRDCTCBC_f09_finalspinup`

- Case: `.../E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_finalspinup`
- Script: `case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_finalspinup.sh`
- Length: **800 yr** (`STOP_N=20`, `RESUBMIT=39`)
- `finidat` from AD 0401 restart; `spinup_state=0`; `ELM_ACCELERATED_SPINUP=off`; `RUN_STARTDATE=0401-01-01`
- Walltime: **06:00:00**
- Do **not** submit until AD restart `...elm.r.0401-01-01-00000.nc` exists

## Submit order

1. Build/submit **AD** (`./case.build && ./case.submit`).
2. After AD produces `elm.r.0401-01-01-00000.nc`, build/submit **final**.

Requires E3SM with `%ERAf09` / `I1850ERACNPRDCTCBC` (e.g. fork branch `lnd/clm_glacier_fixes_era5`).
