# E3SM land developer testing — procedure and Frontier paths

**Date:** 2026-08-14  
**Machine:** Frontier (`login03`)  
**E3SM tree:** `/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM`  
**Branch under test:** `lnd/port-clm-cryosphere-fixes-master` (`fbfcc93f52`)  
**Parent master:** `a899004464` (fork `origin/master`, synced 2026-08-13)

Primary home: **`kmELM/docs/`** (this file), matching other experiment notes.

| Location | Role |
|---|---|
| **`kmELM/docs/`** | Testing procedure and later results |
| **`kmELM/E3SM/`** | Source tree used by `create_test` |
| **`kmELM/baselines/`** | Recommended personal baseline root (see below) |

Sources: [ELM Testing](https://docs.e3sm.org/E3SM/ELM/dev-guide/testing/), [CIME system testing](http://esmci.github.io/cime/versions/master/html/system_testing.html), Frontier stanza in `cime_config/machines/config_machines.xml`.

---

## What `${MY_BASELINE_DIR}` is in this case

`${MY_BASELINE_DIR}` is **not** a CIME environment variable. It is the directory you pass to `create_test --baseline-root`. CIME then writes/reads gold results at:

```text
${MY_BASELINE_DIR}/${BASELINE_NAME}/<test-case-name>/
```

There are two different baseline roots on Frontier. Use the **personal** one for this work.

| Kind | Path | Use |
|---|---|---|
| **Personal (use this)** | `/lustre/orion/cli115/world-shared/wangd/kmELM/baselines` | Generate (`-g`) and compare (`-c`) for this branch |
| Prior personal PR tree | `/lustre/orion/cli115/world-shared/wangd/E3SM/PRtest_scratch/baselines` | Older kmELM PR (`PR_kmelm_03312025`); do not mix with the new master hash |
| Shared E3SM gold | `/lustre/orion/cli115/world-shared/e3sm/baselines/frontier/$COMPILER` | Machine default `BASELINE_ROOT`. **Do not `-g` here** |

Recommended settings for this campaign:

```bash
export MY_BASELINE_DIR=/lustre/orion/cli115/world-shared/wangd/kmELM/baselines
export BASELINE_NAME=a899004464
```

After generate, gold files land in:

```text
/lustre/orion/cli115/world-shared/wangd/kmELM/baselines/a899004464/
```

`mkdir -p` is not required; `create_test -g` creates the tree. Keep generate and compare on the **same** `MY_BASELINE_DIR` and `BASELINE_NAME`.

### Why not the shared Frontier gold?

`config_machines.xml` for `MACH=frontier` sets:

```text
BASELINE_ROOT = /lustre/orion/cli115/world-shared/e3sm/baselines/frontier/$COMPILER
CIME_OUTPUT_ROOT = /lustre/orion/cli115/proj-shared/$USER/e3sm_scratch
PROJECT = cli115
DIN_LOC_ROOT = /lustre/orion/cli115/world-shared/e3sm/inputdata
```

That shared `BASELINE_ROOT` is the site gold used by nightly/AT. Generating into it would overwrite community baselines. The ELM docs therefore use a **private** `--baseline-root`.

---

## Which suite

For this ELM cryosphere / hydrology PR, run **`e3sm_land_developer`**.

That is the documented land-PR minimum. It includes ELM I-compsets, restart (ERS), MOSART, FATES, and related land tests.

Do **not** confuse with:

| Suite | What it is |
|---|---|
| `e3sm_developer` | Land + atmosphere + sea ice + MPAS cryo + GCAM + extra coupled tests |
| `e3sm_cryo_developer` | MPAS ice-shelf / ocean, **not** ELM snow/soil |

Compiler for land I-compsets on Frontier: **`craygnu`** (CPU), same as kmELM f09 cases. Default compiler list starts with `craygnu-mphipcc` (GPU); pass `--compiler craygnu` explicitly.

---

## Launch scripts

Launch with **`nohup`** on a Frontier login node. `create_test` compiles here and submits separate Slurm jobs for the runs. `nohup` only keeps that login-node driver alive if SSH drops. Do not `sbatch` these scripts as one 2-hour job.

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM/scripts

# Step 1 — generate gold from parent master
nohup ./e3sm_land_developer_generate.sh > ../docs/e3sm_land_developer_generate.nohup.log 2>&1 &

# Wait until ${SCRATCH}/cs.status.a899004464 is clean and squeue is empty, then:
# Step 2 — compare the development branch
nohup ./e3sm_land_developer_compare.sh > ../docs/e3sm_land_developer_compare.nohup.log 2>&1 &
```

Follow the driver log with `tail -f ../docs/e3sm_land_developer_*.nohup.log`. Shared paths live in `e3sm_land_developer.conf.sh` (`MY_BASELINE_DIR`, hashes, compiler, project).

### Step 0 — variables

```bash
export E3SMROOT=/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM
export MY_BASELINE_DIR=/lustre/orion/cli115/world-shared/wangd/kmELM/baselines
export BASELINE_NAME=a899004464          # parent master hash
export PROJECT=cli115
export MAIL_USER=wangd@ornl.gov          # optional
```

Test cases (build/run) go to the machine scratch root, not the baseline dir:

```text
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch
```

Override with `--test-root` / `--output-root` only if you want them under `kmELM` instead.

### Step 1 — generate baselines from parent master

Checkout the hash this branch was built on, then generate (`-g`). Cases are named `*.G.*`.

```bash
cd ${E3SMROOT}
git checkout ${BASELINE_NAME}
git submodule update --init

cd cime/scripts
./create_test e3sm_land_developer \
  --machine frontier \
  --compiler craygnu \
  --baseline-root ${MY_BASELINE_DIR} \
  -b ${BASELINE_NAME} \
  -t ${BASELINE_NAME} \
  -p ${PROJECT} \
  --walltime 00:45:00 \
  --mail-user ${MAIL_USER} \
  --mail-type fail \
  -g -v -j 4
```

Wait until generate jobs finish. Check:

```bash
# typically under CIME_OUTPUT_ROOT
ls /lustre/orion/cli115/proj-shared/wangd/e3sm_scratch/cs.status.${BASELINE_NAME}*
./cs.status.${BASELINE_NAME}    # run from that scratch dir
```

Generate must succeed before compare. These bug-fix commits are expected to change answers; the generate run is the **old** answers, so it should be bit-for-bit with itself (PASS), not with the branch.

### Step 2 — compare the development branch

Use the **same** `--baseline-root` and `-b`. Change `-t` so generate and compare case directories do not collide. Cases are named `*.C.*`.

```bash
cd ${E3SMROOT}
git checkout lnd/port-clm-cryosphere-fixes-master
git submodule update --init

DEV_ID=$(git rev-parse --short=10 HEAD)   # fbfcc93f52

cd cime/scripts
./create_test e3sm_land_developer \
  --machine frontier \
  --compiler craygnu \
  --baseline-root ${MY_BASELINE_DIR} \
  -b ${BASELINE_NAME} \
  -t ${DEV_ID} \
  -p ${PROJECT} \
  --walltime 00:45:00 \
  --mail-user ${MAIL_USER} \
  --mail-type fail \
  -c -v -j 4
```

Monitor with `cs.status.${DEV_ID}` in scratch.

### Step 3 — interpret

| Phase | Meaning |
|---|---|
| SHAREDLIB_BUILD / MODEL_BUILD | Compile |
| RUN | Test ran |
| COMPARE_base_rest (ERS) | Restart bit-for-bit vs itself |
| NLCOMP | Namelist vs baseline |
| BASELINE | History vs gold in `${MY_BASELINE_DIR}/${BASELINE_NAME}` |

Expected for this branch:

- Restart / debug tests should still PASS internally.
- **BASELINE diffs are likely** (snow energy, bedrock heat capacity, accumulator masking, surface-water runoff, snow balance). Record which tests DIFF and put that in the PR.
- Bless (`bless_test_results`) only if the diffs are intended and reviewers agree. Do **not** bless into the shared Frontier gold path.

---

## Commits on the branch under test

On `a899004464`:

1. Port CLM fractional-snow energy and melt-compaction fixes  
2. Port CLM bedrock heat capacity fix in SoilTemperatureMod  
3. Port CLM active-element masking for ELM accumulators  
4. Bug fixes for surface water runoff calculation  
5. Fix snow balance accounting issue  

Not included: CPL_BYPASS longitude lookup, CRUJRA/OLMT, Pathfinder machine files.

---

## Checklist before launch

- [ ] Confirm suite: `e3sm_land_developer` (not full `e3sm_developer`)
- [ ] Confirm compiler: `craygnu`
- [ ] `MY_BASELINE_DIR` is the **personal** kmELM path above
- [ ] Generate from `a899004464`, then compare from `lnd/port-clm-cryosphere-fixes-master`
- [ ] Same `-b a899004464` for both steps
- [ ] Different `-t` for generate vs compare
- [ ] Project `cli115`; queue/walltime acceptable on Frontier
- [ ] Launch generate and compare with `nohup` so `create_test` is not killed on logout (do not `sbatch` the whole suite)

---

## After tests finish

Save a short results note alongside this file, for example `e3sm_land_developer_testing_results.md`, with:

- `cs.status` summary
- Tests that DIFF vs `a899004464`
- Whether diffs match the five science commits
- Scratch and baseline paths actually used
