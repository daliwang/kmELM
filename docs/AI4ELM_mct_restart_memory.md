# AI4ELM restart memory packing (Frontier MCT → PathFinder)

**Date:** 2026-11-26  
**Machines:** Frontier (observed). Apply the same cap on PathFinder.  
**Mesh note:** [`AI4ELM_finidat_gridcell_mismatch.md`](./AI4ELM_finidat_gridcell_mismatch.md) (`gridcell=94838`).

Reading a ~57 GB `elm.r` needs about **42 GiB of RAM per rank**. Dense packing
aborts in MCT map init after the restart read succeeds. The file is fine.

## What failed and what finished

Frontier node RAM is ~512 GiB. Both restarts below are 57 GB on Frontier:

- smoke `…adspinup.elm.r.0001-01-06-00000.nc`
- Jinyun `…ad.spinup.elm.r.0021-01-01-00000.nc` (`gridcell=94838`)

| Job | Layout | Result |
|---|---|---|
| **5994423** | 128 ranks, **64 MPI/node**, 2 nodes (~8 GiB/rank) | Restart read succeeded, then glibc `corrupted size vs. prev_size`. MaxRSS **44.3 GiB/rank**. |
| **6005996** | 128 ranks, **8 MPI/node**, 16 nodes, `PIO_TYPENAME=netcdf` | CONTINUE `0001-01-06` → `0001-01-11` (5 days, ~10 min). `SUCCESSFUL TERMINATION OF CPL7-MCT`. MaxRSS **41.6 GiB/rank**. |
| **6006679** | same 16×8 layout, code-start `finidat` = year-21 `elm.r.0021` | Submitted; still pending when this note was written. |

Abort site on 5994423: `component_init_aream` → `seq_map_readdata`
(`driver-mct/main/seq_map_mod.F90`, `mct_gsmap_OrderedPoints` / `pio_initdecomp`
for `area_b`). Same heap abort class showed up at finalize on a cold MCT smoke
run at high packing. A 30×60 layout (~8 GiB/rank) has the same problem.

`PIO_TYPENAME=netcdf` was set together with the 8 MPI/node layout on the job
that finished. Keep both.

## Working layout

Stay at **≤8 MPI/node** (~64 GiB/rank on Frontier, ~56 GiB/rank under
PathFinder `--mem=450g`). Ten per node is the edge (MaxRSS was already ~42 GiB).

| Goal | Ranks | MPI/node | Nodes |
|---|---:|---:|---:|
| Smoke that finished (Frontier 6005996) | 128 | 8 | 16 |
| Frontier `ad0021_30node` script default | 240 | 8 | 30 |
| PathFinder `ad0021_15node` script default | 120 | 8 | 15 |

More ranks means more nodes at 8 MPI/node. Raising MPI/node to fill a node
brings the heap abort back.

Frontier create scripts now default to this cap. PathFinder `ad0021_15node`
overrides the shared env default of 128 MPI/node.

## Duplicate on an existing PathFinder case

PathFinder `hpcl-cli185` nodes are ~503 GB with `--mem=450g`. The create script
stays on `--driver moab` (Frontier used MCT after MOAB/Zoltan failed there).
The RAM cap still applies: 128 MPI/node leaves only a few GiB per rank.

On the existing case (no science-namelist change). 15 nodes × 8 ranks:

```bash
cd e3sm_cases/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node

./xmlchange MAX_MPITASKS_PER_NODE=8,MAX_TASKS_PER_NODE=8
./xmlchange NTASKS=120
./xmlchange NTASKS_ATM=120,NTASKS_LND=120,NTASKS_ROF=120
./xmlchange NTASKS_ICE=120,NTASKS_OCN=120,NTASKS_CPL=120
./xmlchange NTASKS_GLC=120,NTASKS_WAV=120
./xmlchange PIO_TYPENAME=netcdf

# finidat must stay on the 94838 year-21 file; see the mesh note.
./case.setup --reset
./xmlchange BUILD_COMPLETE=TRUE
./preview_run
./case.submit
```

`BUILD_COMPLETE=TRUE` matches the Frontier test: PE and PIO only, same binary.
Rebuild if `case.submit` rejects the executable.

A 16-node smoke matching job 6005996 is `NTASKS=128` at 8 MPI/node (16 nodes).
`hpcl-cli185` has 20 nodes, so 16 fits. The 15-node script uses 120 ranks so
the case still occupies 15 nodes.

Confirm before submit:

```bash
./xmlquery NTASKS,MAX_MPITASKS_PER_NODE,PIO_TYPENAME,COMP_INTERFACE
ncdump -h "$(grep finidat user_nl_elm | sed -n "s/.*'\(.*\)'.*/\1/p")" | grep 'gridcell ='
# expect: gridcell = 94838 ;
```

## Recreate from the repo

```bash
# Frontier: 30 nodes × 8 MPI = 240 ranks, PIO=netcdf, finidat=elm.r.0021
bash case_gene/Frontier/I1850GSWCNPRDCTCBCTOPPHSWFMCROP/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_30node.sh

# PathFinder: 15 nodes × 8 MPI = 120 ranks
bash case_gene/PathFinder/AI4ELM_GSW/I1850GSWCNPRDCTCBCTOPPHSWFMCROP_ad0021_15node.sh
```

Override with `NTASKS_ALL` and `MAX_MPITASKS_PER_NODE` (Frontier) or
`AI4ELM_PPN` (PathFinder). Either script exits if MPI/node is above 10.
