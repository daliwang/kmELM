#!/usr/bin/env python3
"""Local Frontier overlay for maint-3.0 land testing.

Do not replace the whole Frontier <machine> block with master's: master
CIME env vars (ADIOS2_ROOT, BLOSC2_ROOT, ...) make maint-3.0 cmake look
for Blosc2. Keep maint-3.0's CIME skeleton (slurm, env vars, mpirun)
and splice only master's current GNU compiler stack.

From lnd/port-clm-cryosphere-fixes-master (local testing only):
- Lmod paths /usr/share/lmod -> /opt/cray/pe/lmod (compute nodes)
- python cmd_path -> cime_lmod_python_wrapper.sh (OLCF hook exits 1)
- add craygnu to COMPILERS and insert master's craygnu module block
  (drop libunwind; sequential wrapper load cannot see it)
- copy craygnu.cmake / Depends.craygnu.cmake (+ -lstdc++ for maint-3.0 CIME)
- drop duplicate `use elm_varctl, only:` in controlMod.F90 (gfortran 14)

Do not commit the patched E3SM files to the science branch.
"""
from __future__ import print_function

import argparse
import os
import re
import shutil
import sys

FRONTIER_RE = re.compile(
    r'(<machine MACH="frontier">)(.*?)(</machine>)',
    re.DOTALL,
)
PYTHON_CMD_RE = re.compile(r'<cmd_path lang="python">.*?</cmd_path>')
COMPILERS_RE = re.compile(r"<COMPILERS>(.*?)</COMPILERS>")
CRAYGNU_MOD_RE = re.compile(
    r'[ \t]*<modules compiler="craygnu\.\*">.*?</modules>\n',
    re.DOTALL,
)
LIBUNWIND_RE = re.compile(
    r"^[ \t]*<command name=\"load\">libunwind</command>[ \t]*\n",
    re.MULTILINE,
)
GENERIC_MODULES_RE = re.compile(
    r"(<modules>)\s*(<command name=\"load\">cray-python)",
    re.DOTALL,
)
DUPLICATE_ELM_VARCTL_ONLY = re.compile(
    r"^[ \t]*use elm_varctl[ \t]*,[ \t]*only[ \t]*:.*\n",
    re.MULTILINE | re.IGNORECASE,
)

OLD_LMOD = "/usr/share/lmod/lmod"
NEW_LMOD = "/opt/cray/pe/lmod/lmod"
GENERIC_COMPILER_ATTR = (
    'gnu.*|amdclang.*|crayclang.*|gnugpu|amdclanggpu|crayclanggpu'
)

OVERLAY_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "frontier_craygnu_overlay"
)


def wrapper_cmd_path(wrapper):
    return '<cmd_path lang="python">{} python</cmd_path>'.format(wrapper)


def master_craygnu_modules():
    path = os.path.join(OVERLAY_DIR, "frontier_machine.xml")
    if not os.path.isfile(path):
        raise SystemExit("Missing {}".format(path))
    with open(path) as fh:
        text = fh.read()
    match = CRAYGNU_MOD_RE.search(text)
    if not match:
        raise SystemExit("No craygnu modules block in {}".format(path))
    block = LIBUNWIND_RE.sub("", match.group(0))
    if not block.endswith("\n"):
        block += "\n"
    return block


def patch_block(block, wrapper):
    notes = []
    new_block = block
    if OLD_LMOD in new_block:
        new_block = new_block.replace(OLD_LMOD, NEW_LMOD)
        notes.append("lmod paths {} -> {}".format(OLD_LMOD, NEW_LMOD))
    elif NEW_LMOD in new_block:
        notes.append("lmod paths already {}".format(NEW_LMOD))

    new_block, n_cmd = PYTHON_CMD_RE.subn(wrapper_cmd_path(wrapper), new_block, count=1)
    if n_cmd:
        notes.append("python cmd_path -> {}".format(wrapper))
    elif wrapper in new_block:
        notes.append("python cmd_path already set")
    else:
        raise SystemExit("No python cmd_path in target XML block")

    def add_craygnu(match):
        compilers = match.group(1)
        parts = [p.strip() for p in compilers.split(",") if p.strip()]
        if "craygnu" in parts:
            return match.group(0)
        notes.append("added craygnu to COMPILERS")
        return "<COMPILERS>craygnu,{}</COMPILERS>".format(compilers)

    new_block, n_comp = COMPILERS_RE.subn(add_craygnu, new_block, count=1)
    if n_comp == 0 and "<COMPILERS>" in block:
        notes.append("COMPILERS already processed")

    craygnu_mods = master_craygnu_modules()
    if 'compiler="craygnu.*"' not in new_block:
        marker = '      <modules compiler="crayclang.*">'
        gnu_marker = '      <modules compiler="gnu.*">'
        if marker in new_block:
            new_block = new_block.replace(marker, craygnu_mods + marker, 1)
        elif gnu_marker in new_block:
            new_block = new_block.replace(gnu_marker, craygnu_mods + gnu_marker, 1)
        else:
            raise SystemExit("Could not find insertion point for craygnu modules")
        notes.append("inserted master's craygnu module block (no libunwind)")
    else:
        notes.append("craygnu module block already present")

    scoped = '<modules compiler="{}">'.format(GENERIC_COMPILER_ATTR)
    new_block, n_generic = GENERIC_MODULES_RE.subn(
        scoped + r"\n        \2", new_block, count=1
    )
    if n_generic:
        notes.append("scoped generic modules away from craygnu")

    return new_block, notes


def patch_text(text, wrapper):
    frontier = FRONTIER_RE.search(text)
    if frontier:
        new_block, notes = patch_block(frontier.group(2), wrapper)
        print("Frontier: {}".format("; ".join(notes)))
        return (
            text[: frontier.start()]
            + frontier.group(1)
            + new_block
            + frontier.group(3)
            + text[frontier.end() :]
        )
    raise SystemExit("No MACH=frontier block in {}".format("input XML"))


def copy_macros(e3smroot):
    pairs = [
        (
            os.path.join(OVERLAY_DIR, "craygnu.cmake"),
            os.path.join(e3smroot, "cime_config/machines/cmake_macros/craygnu.cmake"),
        ),
        (
            os.path.join(OVERLAY_DIR, "Depends.craygnu.cmake"),
            os.path.join(e3smroot, "cime_config/machines/Depends.craygnu.cmake"),
        ),
    ]
    for src, dst in pairs:
        if not os.path.isfile(src):
            raise SystemExit("Overlay file missing: {}".format(src))
        shutil.copy2(src, dst)
        print("Copied {}".format(dst))


def patch_controlmod(e3smroot):
    path = os.path.join(e3smroot, "components/elm/src/main/controlMod.F90")
    if not os.path.isfile(path):
        raise SystemExit("controlMod.F90 not found: {}".format(path))
    with open(path) as fh:
        original = fh.read()
    patched, n = DUPLICATE_ELM_VARCTL_ONLY.subn("", original)
    if n:
        with open(path, "w") as fh:
            fh.write(patched)
        print(
            "controlMod.F90: removed {} duplicate use elm_varctl, only: line(s) "
            "(match master / gfortran 14 namelist)".format(n)
        )
    else:
        print("controlMod.F90: no duplicate use elm_varctl, only: lines")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "xml_file",
        help="E3SM config_machines.xml or a case env_mach_specific.xml",
    )
    parser.add_argument(
        "--wrapper",
        default=os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            "cime_lmod_python_wrapper.sh",
        ),
        help="Absolute path to cime_lmod_python_wrapper.sh",
    )
    parser.add_argument(
        "--e3sm-root",
        default="",
        help="E3SM root for copying craygnu.cmake / Depends.craygnu.cmake",
    )
    args = parser.parse_args()
    path = args.xml_file
    wrapper = os.path.abspath(args.wrapper)
    if not os.path.isfile(path):
        raise SystemExit("File not found: {}".format(path))
    if not os.path.isfile(wrapper):
        raise SystemExit("Wrapper not found: {}".format(wrapper))
    if not os.access(wrapper, os.X_OK):
        raise SystemExit("Wrapper is not executable: {}".format(wrapper))

    with open(path) as fh:
        original = fh.read()
    patched = patch_text(original, wrapper)
    if patched != original:
        with open(path, "w") as fh:
            fh.write(patched)

    e3smroot = args.e3sm_root
    if not e3smroot and path.endswith("cime_config/machines/config_machines.xml"):
        e3smroot = os.path.abspath(os.path.join(os.path.dirname(path), "..", ".."))
    if e3smroot:
        copy_macros(e3smroot)
        patch_controlmod(e3smroot)
    return 0


if __name__ == "__main__":
    sys.exit(main())
