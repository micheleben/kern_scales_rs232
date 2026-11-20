#!/usr/bin/env bash
# Run Python from the virtual environment named by VIRTUAL_ENV in .env.
#
#   ./run.sh setup                              # create the venv (if missing) + install requirements.txt
#   ./run.sh src_python/core.py /dev/ttyUSB0 w  # run a script with the venv's python
#   ./run.sh -m pip list                        # any python arguments work
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="$root/.env"

if [ ! -f "$env_file" ]; then
    echo ".env not found. Copy .env-example to .env and set VIRTUAL_ENV." >&2
    exit 1
fi

# read VIRTUAL_ENV (accepts "KEY=value", "KEY = value", quotes, CRLF line endings)
venv="$(sed -n -E 's/^[[:space:]]*(export[[:space:]]+)?VIRTUAL_ENV[[:space:]]*=[[:space:]]*(.*)$/\2/p' "$env_file" \
        | tail -n 1 | tr -d '\r' | sed -E 's/[[:space:]]+$//; s/^["'\'']//; s/["'\'']$//')"
if [ -z "$venv" ]; then
    echo "VIRTUAL_ENV is not set in .env" >&2
    exit 1
fi
case "$venv" in
    /*|[A-Za-z]:*) ;;               # absolute (POSIX or Windows drive)
    *) venv="$root/$venv" ;;
esac

find_python() {
    if   [ -x "$venv/bin/python" ];         then echo "$venv/bin/python"
    elif [ -x "$venv/Scripts/python.exe" ]; then echo "$venv/Scripts/python.exe"   # Git Bash on Windows
    fi
}
python="$(find_python)"

if [ "${1:-}" = "setup" ]; then
    if [ -z "$python" ]; then
        echo "Creating virtual environment at $venv"
        if command -v python3 >/dev/null 2>&1; then python3 -m venv "$venv"; else python -m venv "$venv"; fi
        python="$(find_python)"
    fi
    "$python" -m pip install --upgrade pip
    "$python" -m pip install -r "$root/requirements.txt"
    exit 0
fi

if [ -z "$python" ]; then
    echo "No python found in '$venv'. Run './run.sh setup' first." >&2
    exit 1
fi
if [ $# -eq 0 ]; then
    echo "Using $python"
    exec "$python" --version
fi
exec "$python" "$@"
