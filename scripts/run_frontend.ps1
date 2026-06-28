$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location "$root\frontend"

$apiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://localhost:8080/api" }

flutter pub get
flutter run -d chrome --dart-define="API_BASE_URL=$apiBaseUrl"
