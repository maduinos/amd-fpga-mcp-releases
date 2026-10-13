param([Parameter(Mandatory)][string]$Bundle)
$ErrorActionPreference = 'Stop'
$stub = Join-Path $env:RUNNER_TEMP ('wsl-contract-' + [guid]::NewGuid())
New-Item -ItemType Directory $stub | Out-Null
$oldPath = $env:PATH
$env:AMD_TEST_LOG = Join-Path $stub 'calls.txt'
# A native executable preserves PowerShell's actual argv quoting and -- handling.
# Hosted runners cannot provision and reboot a user's WSL2 installation.
$code = @'
using System;
using System.IO;
public class WslContract {
    public static int Main(string[] args) {
        File.AppendAllText(Environment.GetEnvironmentVariable("AMD_TEST_LOG"), String.Join("|", args) + Environment.NewLine);
        string mode = Environment.GetEnvironmentVariable("AMD_TEST_MODE");
        if (args[0] == "--list") {
            Console.WriteLine(mode == "wsl1" ? "  Ubuntu-24.04    Stopped    1" : mode == "localized" ? "* Ubuntu-24.04    Angehalten    2" : "  Ubuntu-24.04    Stopped    2");
            return 0;
        }
        if (args.Length > 3 && args[3] == "wslpath") { Console.WriteLine("/mnt/c/bundle with spaces"); return 0; }
        return mode == "install-fails" ? 1 : 0;
    }
}
'@
try {
    Add-Type -TypeDefinition $code -OutputAssembly (Join-Path $stub 'wsl.exe') -OutputType ConsoleApplication
    $env:PATH = "$stub;$oldPath"
    foreach ($mode in @('english', 'localized')) {
        $env:AMD_TEST_MODE = $mode
        if (Test-Path $env:AMD_TEST_LOG) { Remove-Item $env:AMD_TEST_LOG }
        & "$Bundle/install.ps1"
        $calls = @(Get-Content $env:AMD_TEST_LOG)
        if ($calls.Count -ne 3) { throw 'Unexpected WSL invocation count' }
        if ($calls[2] -ne '-d|Ubuntu-24.04|--|bash|/mnt/c/bundle with spaces/install.sh') { throw "Incorrect native argv forwarding: $($calls[2])" }
    }
    foreach ($mode in @('wsl1', 'install-fails')) {
        $env:AMD_TEST_MODE = $mode
        $caught = $false
        try { & "$Bundle/install.ps1" } catch { $caught = $true }
        if (-not $caught) { throw "Installer failed to reject: $mode" }
    }
    # The intentional failing native process above must not leak its exit code
    # into GitHub Actions' automatic PowerShell step exit check.
    $global:LASTEXITCODE = 0
    Write-Host 'Downloaded ZIP integrity and native PowerShell wrapper contract passed. Full WSL2 provisioning/hardware is outside hosted CI.'
} finally {
    $env:PATH = $oldPath
    Remove-Item Env:\AMD_TEST_LOG, Env:\AMD_TEST_MODE -ErrorAction SilentlyContinue
}
