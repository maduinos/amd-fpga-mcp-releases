"""Build two host entry bundles from a tested source checkout."""
import argparse
import hashlib
import json
from email.parser import BytesParser
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import zipfile

p = argparse.ArgumentParser()
p.add_argument("source", type=Path)
p.add_argument("version")
p.add_argument("commit")
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / "dist"
out.mkdir(exist_ok=True)
bundle = out / f"amd-fpga-mcp-{a.version}"
bundle.mkdir()
wheelhouse = bundle / "wheelhouse"
wheelhouse.mkdir()
subprocess.run([sys.executable, "-m", "pip", "wheel", "--no-deps", "--wheel-dir", str(wheelhouse), str(a.source.resolve())], check=True)
wheel = next(wheelhouse.glob("amd_fpga_mcp-*.whl"))
if wheel.name != f"amd_fpga_mcp-{a.version}-py3-none-any.whl":
    raise SystemExit("Source version does not match release version")
subprocess.run([sys.executable, "-m", "pip", "download", "--only-binary=:all:", "--dest", str(wheelhouse), str(wheel)], check=True)
locked = []
for dependency in sorted(wheelhouse.glob('*.whl')):
    with zipfile.ZipFile(dependency) as archive:
        metadata = BytesParser().parsebytes(archive.read(next(n for n in archive.namelist() if n.endswith('.dist-info/METADATA'))))
    locked.append(f"{metadata['Name']}=={metadata['Version']} --hash=sha256:{hashlib.sha256(dependency.read_bytes()).hexdigest()}")
(bundle / 'requirements.lock').write_text('\n'.join(locked) + '\n')
shutil.copy(a.source / "LICENSE", bundle)
shutil.copy(a.source / "tests/integration/live_installed.py", bundle / "verify.py")
for name in ("install.sh", "install.ps1"):
    shutil.copy(root / "bundle" / name, bundle)
readme = (root / "README.md").read_text()
readme = readme.replace('(docs/MAINTAINERS.md)', '(https://github.com/maduinos/amd-fpga-mcp-releases/blob/main/docs/MAINTAINERS.md)')
(bundle / "README.md").write_text(readme)
(bundle / "release.json").write_text(json.dumps({"version": a.version, "source_commit": a.commit, "python": "3.12", "backend": "Linux x86_64; Windows uses WSL2"}, indent=2) + "\n")
lines = [f"{hashlib.sha256(f.read_bytes()).hexdigest()}  {f.relative_to(bundle).as_posix()}" for f in sorted(bundle.rglob("*")) if f.is_file()]
(bundle / "MANIFEST.sha256").write_text("\n".join(lines) + "\n")
linux = out / f"amd-fpga-mcp-{a.version}-linux-x86_64.tar.gz"
with tarfile.open(linux, "w:gz") as archive:
    archive.add(bundle, arcname=bundle.name)
windows = out / f"amd-fpga-mcp-{a.version}-windows-wsl2-x86_64.zip"
with zipfile.ZipFile(windows, "w", zipfile.ZIP_DEFLATED) as archive:
    for f in sorted(bundle.rglob("*")):
        if f.is_file():
            archive.write(f, f.relative_to(out))
assets = [linux, windows]
(out / "SHA256SUMS").write_text("".join(f"{hashlib.sha256(f.read_bytes()).hexdigest()}  {f.name}\n" for f in assets))
print(json.dumps({"assets": [f.name for f in assets], "source_commit": a.commit}))
