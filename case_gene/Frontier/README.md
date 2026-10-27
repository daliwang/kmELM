# Frontier case scripts

Machine-specific case creation scripts for OLCF **Frontier**, analogous to:

- `case_gene/ORNL_baseline/` — CADES baseline
- `case_gene/PathFinder/ERAf09/` — Pathfinder port of this f09 ERA5 experiment
- `case_gene/PathFinder/TES_NORTHERA5/` — Pathfinder TES 4 km (different experiment)

## I1850ERACNPRDCTCBC_f09 (ERA5 → f09)

| Script | Role |
|---|---|
| `I1850ERACNPRDCTCBC_f09_smoke.sh` | 5-day smoke (`1980`) |
| `I1850ERACNPRDCTCBC_f09_adspinup.sh` | AD spinup 400 yr, DATM 1980–1999 |
| `I1850ERACNPRDCTCBC_f09_finalspinup.sh` | Final spinup 800 yr after AD |

Docs:

- `docs/I1850ERACNPRDCTCBC_f09_smoke1980_report.md`
- `docs/I1850ERACNPRDCTCBC_f09_spinup_report.md`
- `docs/I1850ERACNPRDCTCBC_f09_era5_spinup_process.md` (as-run Frontier process + Pathfinder port)

Forcing: `kiloCraft/ERA5_6hr_f09` (DATM mode `ERAf09`). Requires E3SM branch with `%ERAf09` / `I1850ERACNPRDCTCBC` (e.g. `lnd/clm_glacier_fixes_era5`).

On Pathfinder that branch is pinned in `E3SM-era5/` so `E3SM/` can track TES_NORTH.
See [`docs/e3sm_source_trees.md`](../../docs/e3sm_source_trees.md).

```bash
bash case_gene/Frontier/I1850ERACNPRDCTCBC_f09/I1850ERACNPRDCTCBC_f09_adspinup.sh
```

## I1850GSWCNPRDCTCBCTOPPHSWFMCROP (GSWP3 global, AI4ELM AD)

Perlmutter reproduction notes: [`docs/AI4ELM_Spinup_repeat.md`](../../docs/AI4ELM_Spinup_repeat.md).

| Script | Role |
|---|---|
| `I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh` | Cold-start AD spinup, GSWP3 1901–1920 cycle |

Uses `E3SM-ai4elm` @ `48d8ff20cc` (`--driver moab`, `craygnu`). Custom surfdata/params/ndep/MOSART files: [`DATA.md`](I1850GSWCNPRDCTCBCTOPPHSWFMCROP/DATA.md).

```bash
bash case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh
```

Pathfinder port of the same science: [`../PathFinder/AI4ELM_GSW/`](../PathFinder/AI4ELM_GSW/).
