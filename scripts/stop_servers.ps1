$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$runtimeDir = Join-Path $root ".runtime"

function Stop-PidFile {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return }
  $pidText = Get-Content -Raw $Path
  $processId = 0
  if ([int]::TryParse($pidText.Trim(), [ref]$processId)) {
    Stop-Process -Id $processId -ErrorAction SilentlyContinue
  }
  Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
}

Stop-PidFile (Join-Path $runtimeDir "backend.pid")
Stop-PidFile (Join-Path $runtimeDir "web.pid")

Write-Host "MarketKy local servers stopped."
