# E3SM land developer testing — procedure and Frontier paths

**Updated:** 2026-08-17  
**Machine:** Frontier (`login` nodes)  
**E3SM tree:** `/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM`

Active settings live in `kmELM/scripts/e3sm_land_developer.conf.sh`. Gold for each parent hash is kept under `kmELM/baselines/<hash>/` and is **not** overwritten by a later campaign.

| Campaign | Date | Parent / gold (`-b`) | Branch under test | Status | Results |
|---|---|---|---|---|---|
| **2 — maint-3.0** | 2026-08-17 | `maint-3.0` @ `34bd782d18` | `lnd/port-clm-cryosphere-fixes-maint-3.0` @ `3c77ed78f3` | generate launched | this file + results note (in progress) |
| 1 — master | 2026-08-14 | fork `master` @ `a899004464` | `lnd/port-clm-cryosphere-fixes-master` @ `fbfcc93f52` | **complete** | [`e3sm_land_developer_testing_results.md`](e3sm_land_developer_testing_results.md) |

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

Recommended settings for the **active** (maint-3.0) campaign:

```bash
export MY_BASELINE_DIR=/lustre/orion/cli115/world-shared/wangd/kmELM/baselines
export BASELINE_NAME=34bd782d18
```

After generate, gold files land in:

```text
/lustre/orion/cli115/world-shared/wangd/kmELM/baselines/34bd782d18/
```

Campaign 1 gold remains at `.../baselines/a899004464/` and must not be reused as the maint-3.0 reference.

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

Compiler for land I-compsets on Frontier:

- Campaign 2 (`maint-3.0`): **`gnu`** (CPU). `craygnu` is not a valid compiler name on this tag.
- Campaign 1 (`master` @ `a899004464`): **`craygnu`**.

---

## Launch scripts

Launch with **`nohup`** on a Frontier login node. `create_test` compiles here and submits separate Slurm jobs for the runs. `nohup` only keeps that login-node driver alive if SSH drops. Do not `sbatch` these scripts as one 2-hour job.

```bash
cd /lustre/orion/cli115/world-shared/wangd/kmELM/scripts

# Step 1 — generate gold from parent maint-3.0 (new directory, does not touch a899004464)
nohup ./e3sm_land_developer_generate.sh \
  > ../docs/e3sm_land_developer_generate_34bd782d18.nohup.log 2>&1 &

# Wait until ${SCRATCH}/cs.status.34bd782d18 is clean and squeue is empty, then:
# Step 2 — compare the maint-3.0 development branch
nohup ./e3sm_land_developer_compare.sh \
  > ../docs/e3sm_land_developer_compare_3c77ed78f3.nohup.log 2>&1 &
```

Follow the driver log with `tail -f ../docs/e3sm_land_developer_*34bd782d18*.nohup.log` (generate) or the compare log after step 2. Shared paths live in `e3sm_land_developer.conf.sh` (`MY_BASELINE_DIR`, hashes, compiler, project).

Campaign 1 (2026-08-14) used `cs.status.a899004464` / `cs.status.fbfcc93f52` and logs `e3sm_land_developer_compare.nohup.log`, `e3sm_land_developer_compare_fbfcc93f52.log`.

### Step 0 — variables

```bash
export E3SMROOT=/lustre/orion/cli115/world-shared/wangd/kmELM/E3SM
export MY_BASELINE_DIR=/lustre/orion/cli115/world-shared/wangd/kmELM/baselines
export BASELINE_NAME=34bd782d18          # parent maint-3.0 hash
export PROJECT=cli115
export MAIL_USER=wangd@ornl.gov          # optional
```

Test cases (build/run) go to the machine scratch root, not the baseline dir:

```text
/lustre/orion/cli115/proj-shared/wangd/e3sm_scratch
```

Override with `--test-root` / `--output-root` only if you want them under `kmELM` instead.

### Step 1 — generate baselines from parent hash

Checkout the hash this branch was built on, then generate (`-g`). Cases are named `*.G.*`.

```bash
cd ${E3SMROOT}
git checkout ${BASELINE_NAME}
git submodule update --init

cd cime/scripts
./create_test e3sm_land_developer \
  --machine frontier \
  --compiler gnu \
  --baseline-root ${MY_BASELINE_DIR} \
  -b ${BASELINE_NAME} \
  -t ${BASELINE_NAME} \
  -p ${PROJECT} \
  --walltime 01:30:00 \
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
git checkout lnd/port-clm-cryosphere-fixes-maint-3.0
git submodule update --init

DEV_ID=$(git rev-parse --short=10 HEAD)   # 3c77ed78f3

cd cime/scripts
./create_test e3sm_land_developer \
  --machine frontier \
  --compiler gnu \
  --baseline-root ${MY_BASELINE_DIR} \
  -b ${BASELINE_NAME} \
  -t ${DEV_ID} \
  -p ${PROJECT} \
  --walltime 01:30:00 \
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

Same five ELM science commits on both campaigns. Campaign 2 cherry-picks them onto `maint-3.0` (`34bd782d18`); campaign 1 had them on `master` (`a899004464`).

| Campaign 2 (maint-3.0) | Campaign 1 (master) | Subject |
|---|---|---|
| `36deec7f46` | `c304fff2d1` | Port CLM fractional-snow energy and melt-compaction fixes |
| `a63fb07099` | `3f7fd0f8cb` | Port CLM bedrock heat capacity fix in SoilTemperatureMod |
| `45e8c6e260` | `5bdf5f2212` | Port CLM active-element masking for ELM accumulators |
| `1b19ba5e35` | `4b7a01afc3` | Bug fixes for surface water runoff calculation |
| `3c77ed78f3` | `fbfcc93f52` | Fix snow balance accounting issue |

Not included: CPL_BYPASS longitude lookup, CRUJRA/OLMT, Pathfinder machine files.

---

## Checklist before launch (campaign 2)

- [ ] Confirm suite: `e3sm_land_developer` (not full `e3sm_developer`)
- [ ] Confirm compiler: `gnu` (not `craygnu`; that name is invalid on `maint-3.0`)
- [ ] `MY_BASELINE_DIR` is the **personal** kmELM path above
- [ ] Generate from `34bd782d18`, then compare from `lnd/port-clm-cryosphere-fixes-maint-3.0`
- [ ] Same `-b 34bd782d18` for both steps (do **not** point `-b` at `a899004464`)
- [ ] Different `-t` for generate vs compare (`34bd782d18` vs `3c77ed78f3`)
- [ ] Project `cli115`; walltime `01:30:00` (r05 tests timed out at 45 min in campaign 1)
- [ ] Launch generate and compare with `nohup` so `create_test` is not killed on logout (do not `sbatch` the whole suite)

---

## After tests finish

- Campaign 1 (master, complete): [`e3sm_land_developer_testing_results.md`](e3sm_land_developer_testing_results.md)
- Campaign 2 (maint-3.0): append a section to that same results file when `cs.status.34bd782d18` and `cs.status.3c77ed78f3` are final

Record:

- `cs.status` summary
- Tests that DIFF vs the **campaign parent** (`34bd782d18` for campaign 2, `a899004464` for campaign 1)
- Whether diffs match the five science commits
- Scratch and baseline paths actually used
