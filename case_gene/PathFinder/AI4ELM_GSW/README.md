# Pathfinder AI4ELM GSWP3 TOP/crop (port of Frontier / Perlmutter AD)

Duplicate the Frontier cold-start AD experiment
`I1850GSWCNPRDCTCBCTOPPHSWFMCROP` on OLCF **Pathfinder**.

Perlmutter notes: [`docs/AI4ELM_Spinup_repeat.md`](../../../docs/AI4ELM_Spinup_repeat.md)  
Frontier create: [`../../Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/`](../../Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/)  
Jinyun CFS paths: [`docs/Extra_Information_from_JinyunTang.md`](../../../docs/Extra_Information_from_JinyunTang.md)  
Pathfinder status + LandSim plan: [`docs/AI4ELM_Pathfinder_GSWP3_status_and_LandSim_plan.md`](../../../docs/AI4ELM_Pathfinder_GSWP3_status_and_LandSim_plan.md)

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

# 5) 15-node hpcl-cli185, 1 AD year from Jinyun elm.r.0021 (on disk, gridcell=94838)
#    Do NOT point finidat at Frontier flat 20261015…elm.r.0020 (94935) — see
#    docs/AI4ELM_finidat_gridcell_mismatch.md
bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node.sh
cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node
ncdump -h "$(grep finidat user_nl_elm | sed -n "s/.*'\(.*\)'.*/\1/p")" | grep 'gridcell ='
./case.build && ./case.submit

# 5b) Legacy: 15-node parallel AD from elm.r.0166 (0166 not on Pathfinder)
# bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0166_15node.sh

# 6) 15-node hpcl-cli185, 1 regular-spinup year from Jinyun AD elm.r.0166
#    Copy 0166 first (not on Pathfinder yet). AD off / spinup_state=0.
bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_rg0166_15node.sh
cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_rg0166_15node
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
| 15-node AD from Jinyun `0021` | 1920 tasks, `hpcl-cli185`, `--mem=450g`, 1 year; `finidat` = on-disk `elm.r.0021` |
| 15-node AD from Jinyun `0166` (legacy) | 1920 tasks, `parallel` / NDR; `0166` **not** on Pathfinder |
| 15-node regular from Jinyun `0166` | 1920 tasks, `hpcl-cli185`, `--mem=450g`, 1 year; `spinup_state=0`, AD off; copy `0166` before submit |
| Queue | `parallel` (override `JOB_QUEUE=hpcl-cli185` if needed); ad0021 / rg0166 default to `hpcl-cli185` |

Cases: `${KMELM_ROOT}/e3sm_cases/…`  
Runs: `${KMELM_ROOT}/e3sm_runs/…`

Do **not** point these scripts at `E3SM-era5` (wrong branch) or TES `E3SM/` without the AI4ELM pin and Pathfinder overlay.

Data details: [`DATA.md`](DATA.md).
