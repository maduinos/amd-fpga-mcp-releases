param([string]$Distribution = "Ubuntu-24.04")
$ErrorActionPreference = "Stop"
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "WSL2 is required. Run: wsl --install -d Ubuntu-24.04; restart Windows and initialize Ubuntu."
}
$wslList = (& wsl.exe --list --verbose | Out-String) -replace "`0", ""
if ($wslList -notmatch ("(?m)^\s*\*?\s*" + [regex]::Escape($Distribution) + "\s+[^\r\n]+\s+2\s*$")) {
    throw "The selected distribution must use WSL2. Check: wsl --list --verbose"
}
$linuxPath = (& wsl.exe -d $Distribution -- wslpath -a $PSScriptRoot | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw "Cannot translate bundle path." }
& wsl.exe -d $Distribution -- bash "$linuxPath/install.sh"
if ($LASTEXITCODE -ne 0) { throw "Installation failed. In Ubuntu install python3.12 and python3.12-venv, then retry." }
Write-Host "Use wsl.exe -d $Distribution -- /home/<linux-user>/.local/share/amd-fpga-mcp/<version>/bin/amd-fpga-mcp in your MCP client."
