param([Parameter(Mandatory)][string]$Bundle)
$ErrorActionPreference = 'Stop'
$global:AmdReleaseWrapperCalls = [System.Collections.Generic.List[string]]::new()
$global:AmdReleaseWrapperMode = 'english'
# Hosted Windows runners cannot provision and reboot a user's WSL2 installation.
# Test the native wrapper contract; Linux jobs test both actual downloaded backends.
function global:wsl.exe {
    $global:AmdReleaseWrapperCalls.Add(($args -join '|'))
    $global:LASTEXITCODE = 0
    if ($args[0] -eq '--list') {
        if ($global:AmdReleaseWrapperMode -eq 'wsl1') { return "  Ubuntu-24.04    Stopped    1" }
        if ($global:AmdReleaseWrapperMode -eq 'localized') { return "* Ubuntu-24.04    Angehalten    2" }
        return "  Ubuntu-24.04    Stopped    2"
    }
    if ($args[3] -eq 'wslpath') { return '/mnt/c/bundle with spaces' }
    if ($global:AmdReleaseWrapperMode -eq 'install-fails') { $global:LASTEXITCODE = 1 }
}
try {
    foreach ($mode in @('english', 'localized')) {
        $global:AmdReleaseWrapperMode = $mode
        $global:AmdReleaseWrapperCalls.Clear()
        & "$Bundle/install.ps1"
        if ($global:AmdReleaseWrapperCalls.Count -ne 3) { throw 'Unexpected WSL invocation count' }
        if ($global:AmdReleaseWrapperCalls[2] -ne '-d|Ubuntu-24.04|--|bash|/mnt/c/bundle with spaces/install.sh') { throw 'Unsafe or incorrect argument forwarding' }
    }
    foreach ($mode in @('wsl1', 'install-fails')) {
        $global:AmdReleaseWrapperMode = $mode
        $caught = $false
        try { & "$Bundle/install.ps1" } catch { $caught = $true }
        if (-not $caught) { throw "Installer failed to reject: $mode" }
    }
    Write-Host 'Downloaded ZIP integrity and native PowerShell wrapper contract passed. Full WSL2 provisioning/hardware is outside hosted CI.'
} finally { Remove-Item Function:\wsl.exe; Remove-Variable AmdReleaseWrapperCalls, AmdReleaseWrapperMode -Scope Global }
