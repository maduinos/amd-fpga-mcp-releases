#!/usr/bin/env bash
set -euo pipefail
bundle_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
prefix="${1:-$HOME/.local/share/amd-fpga-mcp}"
python_bin="${PYTHON:-python3.12}"
if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo 'This bundle requires Linux x86_64 (Windows: use WSL2).' >&2; exit 1
fi
"$python_bin" -c 'import sys; assert sys.version_info[:2] == (3, 12), "Python 3.12 is required"'
(cd "$bundle_dir" && sha256sum --check --quiet MANIFEST.sha256)
version="$("$python_bin" -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$bundle_dir/release.json")"
target="$prefix/$version"
if [[ -e "$target" ]]; then echo "Installation already exists: $target" >&2; exit 1; fi
"$python_bin" -m venv "$target"
"$target/bin/python" -m pip install --no-index --find-links "$bundle_dir/wheelhouse" "amd-fpga-mcp==$version"
"$target/bin/python" -m pip check
(cd /tmp && env -u PYTHONPATH "$target/bin/python" "$bundle_dir/verify.py")
echo "MCP command: $target/bin/amd-fpga-mcp"
