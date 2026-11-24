# AI4ELM land spinup — methodology (brief)

#   
**Date:** 2026-11-12

## Goal

Replace centuries of ELM **normal (final) spinup** with a learned mapping from a short **accelerated-decomposition (AD)** state to an equivalent **normal-spinup** land restart, then continue ELM from that AI restart.

The target date is 12/31/2026

## ELM chain

1. **AD spinup** (`spinup_state=1`): soil C–N–P turnover is accelerated so pools approach equilibrium faster.
2. **Normal spinup** (`spinup_state=0`): same physics, no acceleration; this is the expensive step AI is meant to skip or shorten.
3. **After AI:** ELM finalspin starts from the AI-updated `elm.r` (`finidat`), not from a cold start.

This experiment is global **0.5°** GSWP3, 1850, crop + TOP radiation + irrigation, C–N–P ELM, MOSART rivers. Compset `I1850GSWCNPRDCTCBCTOPPHSWFMCROP`. 

## AI method (LandSim / CNP surrogate)

Same idea as TES_NORTH, new model on this mesh:

- **X** = AD restart (pools after AD)
- **Y** = paired normal-spinup restart (target pools)
- Plus surfdata, ELM parameters, and cycling GSWP3 (1901–1920)
- Train a CNP model on a subset of land cells; infer on the full land list (`gridcell ≈ 94,838`)
- Write predictions **only into CNP pool fields** of a copy of the AD `elm.r`; hydrology and other state stay from AD

Jinyun Tang’s Perlmutter AD (branch `jinyuntang/elm/fix-top-crop-compsets` @ `48d8ff20cc`) supplies the science configuration and restarts. On Pathfinder we currently have AD `elm.r.0021` (X) and regular-spinup `elm.r.0202` (Y candidate). We do **not** reuse the TES_NORTH trained weights.

## Then ELM

Build a **finalspin** case from the same compset/grid, AD off, `finidat` = the AI `elm.r`. First job is a startup from that file; later jobs continue from ELM `rpointer` files.

## Status (one line)

Pathfinder can build/run the GSWP3 TOP/crop case (5-day smoke passed). Next: confirm the Y restart, train/infer LandSim, then a Pathfinder finalspin from the AI restart.

S2D follow-on (after this I-case): [`AI4ELM_S2D_adaptation_requirements.md`](./AI4ELM_S2D_adaptation_requirements.md).