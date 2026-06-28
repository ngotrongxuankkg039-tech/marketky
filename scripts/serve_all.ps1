param(
  [int]$ApiPort = 8080,
  [int]$WebPort = 9000,
  [switch]$SkipBuild,
  [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$runtimeDir = Join-Path $root ".runtime"
$frontendDir = Join-Path $root "frontend"
$backendDir = Join-Path $root "backend"
$webDir = Join-Path $frontendDir "build\web"

New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null

function Get-CommandPath {
  param(
    [string]$Name,
    [string]$Fallback
  )
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  if (Test-Path $Fallback) { return $Fallback }
  throw "Cannot find $Name. Please add it to PATH or install it at $Fallback"
}

function Test-PortListening {
  param([int]$Port)
  $matches = netstat -ano | Select-String ":$Port\s+.*LISTENING"
  return [bool]$matches
}

$flutter = Get-CommandPath "flutter" "C:\Users\xuyug\Documents\flutter\bin\flutter.bat"
$dart = Get-CommandPath "dart" "C:\Users\xuyug\Documents\flutter\bin\dart.bat"

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
  $pythonCommand = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $pythonCommand) {
  throw "Cannot find python or py. Install Python or add it to PATH to serve Flutter Web static files."
}
$python = $pythonCommand.Source

$apiBaseUrl = "http://localhost:$ApiPort/api"
$webUrl = "http://localhost:$WebPort"

if (-not $SkipBuild -or -not (Test-Path (Join-Path $webDir "index.html"))) {
  Push-Location $frontendDir
  try {
    & $flutter pub get
    & $flutter build web --release --dart-define="API_BASE_URL=$apiBaseUrl"
  } finally {
    Pop-Location
  }
}

if (-not (Test-PortListening $ApiPort)) {
  $backendCommand = @"
`$ErrorActionPreference = 'Stop'
`$env:MYSQL_HOST = if (`$env:MYSQL_HOST) { `$env:MYSQL_HOST } else { '127.0.0.1' }
`$env:MYSQL_PORT = if (`$env:MYSQL_PORT) { `$env:MYSQL_PORT } else { '3306' }
`$env:MYSQL_USER = if (`$env:MYSQL_USER) { `$env:MYSQL_USER } else { 'root' }
`$env:MYSQL_PASSWORD = if (`$env:MYSQL_PASSWORD) { `$env:MYSQL_PASSWORD } else { 'root' }
`$env:MYSQL_DATABASE = if (`$env:MYSQL_DATABASE) { `$env:MYSQL_DATABASE } else { 'marketky_shop' }
`$env:JWT_SECRET = if (`$env:JWT_SECRET) { `$env:JWT_SECRET } else { 'dev-marketky-course-design-secret' }
`$env:PORT = '$ApiPort'
Set-Location '$backendDir'
& '$dart' run bin/server.dart
"@
  $backendProcess = Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $backendCommand -PassThru
  Set-Content -Path (Join-Path $runtimeDir "backend.pid") -Value $backendProcess.Id
  Start-Sleep -Seconds 3
}

if (-not (Test-PortListening $WebPort)) {
  $webArgs = if ($pythonCommand.Name -eq "py.exe" -or $pythonCommand.Name -eq "py") {
    @("-3", "-m", "http.server", "$WebPort", "--bind", "127.0.0.1", "--directory", "$webDir")
  } else {
    @("-m", "http.server", "$WebPort", "--bind", "127.0.0.1", "--directory", "$webDir")
  }
  $webProcess = Start-Process $python -ArgumentList $webArgs -PassThru -WindowStyle Hidden
  Set-Content -Path (Join-Path $runtimeDir "web.pid") -Value $webProcess.Id
  Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "MarketKy servers are ready."
Write-Host "Frontend: $webUrl"
Write-Host "Backend : http://localhost:$ApiPort"
Write-Host "API     : $apiBaseUrl"
Write-Host ""
Write-Host "Use scripts\stop_servers.ps1 to stop servers started by this script."

if (-not $NoBrowser) {
  Start-Process $webUrl
}
