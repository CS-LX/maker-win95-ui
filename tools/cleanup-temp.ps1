# Manual cleanup of this repository's disposable .tmp directory only.
# Close previews first. This does not remove dist, assets, sources or Git data.
[CmdletBinding(SupportsShouldProcess = $true)]
param()

$workspaceRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if (-not (Test-Path -LiteralPath (Join-Path $workspaceRoot 'scripts/win95/init.lua'))) {
    throw 'Run this script only from the maker-win95-ui tools directory.'
}
$tempTarget = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot '.tmp'))
if ($tempTarget -ne "$workspaceRoot\.tmp") { throw 'Unexpected temporary path.' }
if (-not (Test-Path -LiteralPath $tempTarget)) { return }
if ((Get-Item -LiteralPath $tempTarget).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw 'Refusing to remove a redirected temporary directory.'
}
if ($PSCmdlet.ShouldProcess($tempTarget, 'Remove this repository temporary validation files')) {
    Remove-Item -LiteralPath $tempTarget -Recurse -Force
}
