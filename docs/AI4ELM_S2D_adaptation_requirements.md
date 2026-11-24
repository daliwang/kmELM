# Adapting AI4ELM spinup to E3SM S2D cases — requirements (brief)

**Date:** 2026-11-12  
**Parent method:** `[AI4ELM_spinup_methodology_brief.md](./AI4ELM_spinup_methodology_brief.md)`  
**S2D case notes:** [CM Confluence page](https://e3sm.atlassian.net/wiki/spaces/CM/pages/6853427469)  
**Pilot context:** [E3SM S2D pilot (E3SMv3.LR)](https://e3sm.org/e3sm-seasonal-to-decadal-s2d-prediction-effort-a-pilot-study/)

## What we already do

AI4ELM learns AD land pools → normal-spinup pools, writes an `elm.r`, then ELM **finalspin** starts from that file. Current prototype: **1850 I-case**, global ~0.5°, GSWP3, crop/TOP (`I1850GSWCNPRDCTCBCTOPPHSWFMCROP`). Target for that prototype: **31 Dec 2026**.

## What S2D needs instead

S2D is **dated hindcast initialization**, not a single 1850 equilibrium. The v3.LR pilot uses ~50 km ELM–MOSART in a coupled E3SMv3, CMIP6 historical forcing, and land ICs from **FOSIRL** (offline land/river under reanalysis), reanalysis “brute force,” or weakly coupled DA. Hindcasts start **May and November**, many years (seasonal: 1980–2015; later decadal: 1960–2015+), 10 members.

AI4ELM can still supply a **spun-up land restart** for FOSIRL / offline land, but only if the following are met.


| Requirement                                                                                                              | Why                                                               |
| ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| **S2D land grid and compset** (E3SMv3.LR ELM–MOSART ~50 km, not the 1850 crop/TOP I-case unless the S2D group adopts it) | `elm.r` cell/PFT layout must match the hindcast                   |
| **Historical / reanalysis DATM** (FOSIRL), not GSWP3 1850 1901–1920 cycle                                                | S2D ICs are calendar-dated                                        |
| **Paired X/Y on that case** (AD or short offline land vs target normal/FOSIRL `elm.r` at the **same** date)              | LandSim cannot reuse Jinyun 0021/0202 or TES_NORTH 4 km weights   |
| **Water/energy fields as well as CNP** (soil moisture, snow, T)                                                          | S2D skill is initialization-driven; pools-only ICs are not enough |
| **Many init dates** (May/Nov; later 1960–2015)                                                                           | Model must generalize in time, not one 1850 state                 |
| **MOSART restart (and coupler if coupled)**                                                                              | Land-only `finidat` is incomplete for FOSIRL/coupled ingest       |
| **One smoke hindcast** in the S2D workflow before ensembles                                                              | Prove the AI `elm.r` is accepted and stable                       |


The 2026 S2D **pilot** itself is scheduled to conclude end of 2026; AI land ICs are a **follow-on**, not a replacement for that pilot’s three init methods.

## Dates (working estimates)


| When                  | What                                                                             |
| --------------------- | -------------------------------------------------------------------------------- |
| **Now – 31 Dec 2026** | Finish current 0.5° I-case AI4ELM (verify Y, train/infer, Pathfinder finalspin)  |
| **Jan – Mar 2027**    | Freeze S2D land case with the S2D group (grid, forcing, FOSIRL vs AD, variables) |
| **TBD**               | Produce paired S2D land restarts (X/Y) + surfdata/params/DATM bundle             |
| **TBD**               | Adapt LandSim (forcing, hydro+CNP IO, dated inference); write May/Nov `elm.r`    |
| **TBD**               | Insert one AI land IC into an S2D hindcast smoke (single date, few members)      |
| **TBD**               | Multi-date / 10-member production **if** the 2027 smoke is accepted              |


Critical path: **S2D-native X/Y restarts** (Q2 2027). Without those, LandSim cannot move off the 1850 GSWP3 prototype.