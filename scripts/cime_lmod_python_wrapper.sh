#!/bin/bash
# CIME Frontier workaround: run Lmod through bash `module`, then emit Python
# that syncs os.environ.
#
# CIME calls:  <this-script> python <action> [args...]
# because cmd_path lang="python" is  "<this-script> python".
#
# Direct `/usr/share/lmod/lmod/libexec/lmod python ...` hits
#   /sw/frontier/lmod/hooks/NSPLoggingHook.lua:24
#   attempt to index a nil value (field 'mname')
# and exits 1. Interactive `module` still returns 0 (stderr may contain the
# same hook traceback). CIME requires stat==0.
#
# Do not use this as a general Lmod replacement.

set -u

REAL_LMOD="${LMOD_CMD:-/usr/share/lmod/lmod/libexec/lmod}"

if [[ "${1:-}" != "python" ]]; then
  exec "${REAL_LMOD}" "$@"
fi
shift

ACTION="${1:-}"
if [[ -n "${ACTION}" ]]; then
  shift
fi

for init in /usr/share/lmod/lmod/init/bash /opt/cray/pe/lmod/lmod/init/bash; do
  if [[ -f "${init}" ]]; then
    # shellcheck disable=SC1090
    source "${init}"
    break
  fi
done

if ! type module >/dev/null 2>&1; then
  echo "cime_lmod_python_wrapper: module command not available" >&2
  exit 1
fi

# OLCF NSPLoggingHook.lua crashes on some load/reset events
# (t.mname is nil) and aborts the module command. CIME then never
# gets NETCDF_DIR from cray-netcdf. Disable the site hook for this
# subprocess only.
unset LMOD_PACKAGE_PATH

status=0
if [[ -n "${ACTION}" ]]; then
  # Keep stdout empty: CIME exec()s stdout as Python.
  # Hide Lmod swap chatter on stderr unless the command fails; CIME
  # treats nonempty stderr as failure unless allow_error is set.
  # CIME batches consecutive `load`s into one command. Load/unload one
  # module at a time so later modules see the updated MODULEPATH.
  errf="$(mktemp)"
  if [[ "${ACTION}" == "load" || "${ACTION}" == "unload" ]]; then
    for mod in "$@"; do
      module "${ACTION}" "${mod}" >/dev/null 2>"${errf}"
      status=$?
      if [[ "${status}" -ne 0 ]]; then
        cat "${errf}" >&2
        break
      fi
    done
  else
    module "${ACTION}" "$@" >/dev/null 2>"${errf}"
    status=$?
    if [[ "${status}" -ne 0 ]]; then
      cat "${errf}" >&2
    fi
  fi
  rm -f "${errf}"
fi

python3 - <<'PY'
import json
import os

print("import os")
print("_cime_lmod_new = %s" % json.dumps(dict(os.environ)))
print("for _k in list(os.environ):")
print("    if _k not in _cime_lmod_new:")
print("        del os.environ[_k]")
print("os.environ.update(_cime_lmod_new)")
PY

exit "${status}"
