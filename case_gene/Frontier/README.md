# Frontier case scripts

Machine-specific case creation scripts for OLCF **Frontier**, analogous to:

- `case_gene/ORNL_baseline/` — CADES baseline
- `case_gene/PathFinder/` — PathFinder

## I1850ERACNPRDCTCBC_f09 (ERA5 → f09)

| Script | Role |
|---|---|
| `I1850ERACNPRDCTCBC_f09_smoke.sh` | 5-day smoke (`1980`) |
| `I1850ERACNPRDCTCBC_f09_adspinup.sh` | AD spinup 400 yr, DATM 1980–1999 |
| `I1850ERACNPRDCTCBC_f09_finalspinup.sh` | Final spinup 800 yr after AD |

Docs:

- `docs/I1850ERACNPRDCTCBC_f09_smoke1980_report.md`
- `docs/I1850ERACNPRDCTCBC_f09_spinup_report.md`

Forcing: `kiloCraft/ERA5_6hr_f09` (DATM mode `ERAf09`). Requires E3SM branch with `%ERAf09` / `I1850ERACNPRDCTCBC` (e.g. `lnd/clm_glacier_fixes_era5`).

```bash
bash case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh
```
