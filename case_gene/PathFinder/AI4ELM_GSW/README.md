# Pathfinder AI4ELM GSWP3 TOP/crop (port of Frontier / Perlmutter AD)

Duplicate the Frontier cold-start AD experiment
`I1850GSWCNPRDCTCBCTOPPHSWFMCROP` on OLCF **Pathfinder**.

Perlmutter notes: [`docs/AI4ELM_Spinup_repeat.md`](../../../docs/AI4ELM_Spinup_repeat.md)  
Frontier create: [`../../Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/`](../../Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/)  
Jinyun CFS paths: [`docs/Extra_Information_from_JinyunTang.md`](../../../docs/Extra_Information_from_JinyunTang.md)

## Checklist (on Pathfinder)

```bash
cd /projects/hpcl-cli185/proj-shared/wangd/kmELM
git pull   # get these scripts

# 1) Source pin + Pathfinder machine overlay
bash scripts/setup_e3sm_ai4elm_worktree.sh
# (auto-sets OVERLAY_PATHFINDER=1 on Pathfinder hosts)

# 2) Stage customs + domain + GSWP3 1901-1920 from Frontier
MODE=spinup bash case_gene/PathFinder/AI4ELM_GSW/stage_ai4elm_inputs.sh

# 3) Create 5-day smoke (128 ranks)
bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke.sh
cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_smoke
./case.build && ./case.submit

# 4) After smoke OK — AD case (1280 ranks, 2-year segments by default)
bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup.sh
cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_adspinup
./case.build && ./case.submit
```

## Defaults

| Item | Value |
|---|---|
| Source | `E3SM-ai4elm` @ `48d8ff20cc` + Pathfinder machine overlay |
| Machine | `pathfinder` / `gnu` / `openmpi` |
| Compset / res | `I1850GSWCNPRDCTCBCTOPPHSWFMCROP` / `ne30pg2_r05_IcoswISC30E3r5` |
| Driver | `moab` |
| DATM | GSWP3 v1, 1901–1920, align 1 |
| `DIN_LOC_ROOT` | `/projects/hpcl-cli185/world-shared/e3sm/inputdata` |
| Custom data | `/projects/hpcl-cli185/proj-shared/wangd/input_data/ai4elm_spinup` |
| Smoke PE | 128 tasks (1 node) |
| AD PE | 1280 tasks (10×128); Pathfinder max ~30 nodes |
| Queue | `parallel` (override `JOB_QUEUE=hpcl-cli185` if needed) |

Cases: `${KMELM_ROOT}/e3sm_cases/…`  
Runs: `${KMELM_ROOT}/e3sm_runs/…`

Do **not** point these scripts at `E3SM-era5` (wrong branch) or TES `E3SM/` without the AI4ELM pin and Pathfinder overlay.

Data details: [`DATA.md`](DATA.md).
