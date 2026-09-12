# I1850ERACNPRDCTCBC f09 AD + final spinup

Companion to [I1850ERACNPRDCTCBC_f09_smoke1980_report.md](./I1850ERACNPRDCTCBC_f09_smoke1980_report.md).

**Full process (Frontier as-run + Pathfinder port checklist):**
[I1850ERACNPRDCTCBC_f09_era5_spinup_process.md](./I1850ERACNPRDCTCBC_f09_era5_spinup_process.md)

Smoke (5-day 1980) succeeded. Production AD (400 yr) and final (800 yr) **completed** on Frontier.

## Forcing cycle

- **DATM cycle:** 1980–1999 (20 years); `DATM_CLMNCEP_YR_START=1980`, `YR_END=1999`, `YR_ALIGN=1`
- **On disk:** full **1979–2022** under `kiloCraft/ERA5_6hr_f09/` (108 files/year)
- **2000+:** present on disk but **not** used in the 20-year spinup cycle
- Expected files for spinup cycle: \(20 × 12 × 9 = 2160\) — **complete**

## Cases

Canonical scripts: `case_gene/Frontier/I1850ERACNPRDCTCBC_f09/`  
Wrappers: `scripts/frontier/`

E3SM branch used: **`lnd/clm_glacier_fixes_era5` @ `2a1960cd8a`**. Production coupling is **`NCPL=24`** (hourly), not the smoke’s `NCPL=4`.

### AD — `I1850ERACNPRDCTCBC_f09_adspinup`

- Case: `E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_adspinup`
- Length: **400 yr** (`STOP_N=10`, `RESUBMIT=39`, `REST_N=10`)
- AD on: `ELM_ACCELERATED_SPINUP=on`, `spinup_state=1`, cold start `RUN_STARTDATE=0001-01-01`
- Walltime: **02:00:00**; PE layout: 1280 tasks, 64 MPI/node
- **Done.** Restart: `e3sm_runs/..._adspinup/run/..._adspinup.elm.r.0401-01-01-00000.nc`

### Final — `I1850ERACNPRDCTCBC_f09_finalspinup`

- Case: `E3SM/e3sm_cases/I1850ERACNPRDCTCBC_f09_finalspinup`
- Length: **800 yr** (`STOP_N=10`, `RESUBMIT=79`, `REST_N=10`)
- `finidat` from AD 0401 restart; `spinup_state=0`; `ELM_ACCELERATED_SPINUP=off`; `RUN_STARTDATE=0401-01-01`
- Walltime: **02:00:00**; PE layout: 1280 tasks, 64 MPI/node
- **Done.** Restart: `e3sm_runs/..._finalspinup/run/..._finalspinup.elm.r.1201-01-01-00000.nc`

## Submit order

1. Build/submit **AD**.
2. After AD produces `elm.r.0401-01-01-00000.nc`, build/submit **final**.
