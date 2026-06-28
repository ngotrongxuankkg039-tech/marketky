$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location "$root\frontend"

$apiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://localhost:8080/api" }

flutter pub get
flutter build web --release --dart-define="API_BASE_URL=$apiBaseUrl"

Write-Host "Flutter Web assets are in frontend\build\web"
