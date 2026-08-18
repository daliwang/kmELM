# Frontier `craygnu` overlay for `maint-3.0`

Taken from `lnd/port-clm-cryosphere-fixes-master` and applied locally by `../workaround_frontier_lmod_reset.py`.

| File | Source | Local tweak |
|---|---|---|
| `frontier_machine.xml` | master’s Frontier `<machine>` block | used only for the `craygnu.*` modules + Lmod paths; not spliced in whole |
| `craygnu.cmake` | master’s GNU macros | extra `-lgfortran -lstdc++` for maint-3.0 CIME |
| `Depends.craygnu.cmake` | master | none |

Do not commit these into the land science branch. See `docs/frontier_maint-3.0_testing_overlay.md`.
