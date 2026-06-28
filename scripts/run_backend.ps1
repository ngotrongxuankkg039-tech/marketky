$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location "$root\backend"

if (-not $env:MYSQL_HOST) { $env:MYSQL_HOST = "127.0.0.1" }
if (-not $env:MYSQL_PORT) { $env:MYSQL_PORT = "3306" }
if (-not $env:MYSQL_USER) { $env:MYSQL_USER = "root" }
if (-not $env:MYSQL_PASSWORD) { $env:MYSQL_PASSWORD = "root" }
if (-not $env:MYSQL_DATABASE) { $env:MYSQL_DATABASE = "marketky_shop" }
if (-not $env:JWT_SECRET) { $env:JWT_SECRET = "dev-marketky-course-design-secret" }
if (-not $env:PORT) { $env:PORT = "8080" }

dart pub get
dart run bin/server.dart
