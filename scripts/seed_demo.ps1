$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mysqlUser = if ($env:MYSQL_USER) { $env:MYSQL_USER } else { "root" }
$mysqlPassword = if ($env:MYSQL_PASSWORD) { $env:MYSQL_PASSWORD } else { "root" }
$seed = "$root\database\demo_seed.sql".Replace("\", "/")

mysql --host=127.0.0.1 --port=3306 --user=$mysqlUser --password=$mysqlPassword --execute="source $seed"

Write-Host "Demo database is ready."
