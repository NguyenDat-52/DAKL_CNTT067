param(
    [ValidateSet("Full", "Diff", "Log", "Setup")]
    [string]$Mode = "Full",
    [string]$Server = "KINGDOM-C",
    [string]$Database = "QL_CUA_HANG_VLXD",
    [string]$BackupDir = "",
    [int]$RetentionDays = 14
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$drSqlPath = Join-Path $scriptDir "Backup_Restore_DR_VLXD.sql"

if ($Mode -eq "Setup") {
    Write-Host "Deploying DR stored procedures to $Server..."
    & sqlcmd -S $Server -E -b -f 65001 -i $drSqlPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to deploy DR SQL procedures." }
    Write-Host "DR procedures deployed successfully."
    exit 0
}

$dirArg = if ([string]::IsNullOrWhiteSpace($BackupDir)) { "NULL" } else { "N'" + $BackupDir.Replace("'", "''") + "'" }
if (-not [string]::IsNullOrWhiteSpace($BackupDir) -and -not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$procName = switch ($Mode) {
    "Full" { "dbo.sp_VLXD_BackupFull" }
    "Diff" { "dbo.sp_VLXD_BackupDiff" }
    "Log"  { "dbo.sp_VLXD_BackupLog" }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$query = "EXEC $procName @BackupDir = $dirArg;"
Write-Host "Running $Mode backup on $Server.$Database..."
& sqlcmd -S $Server -d $Database -E -b -Q $query
if ($LASTEXITCODE -ne 0) { throw "Backup execution failed ($Mode)." }
$sw.Stop()
Write-Host ("Backup ($Mode) completed & VERIFYONLY passed in {0:N2}s." -f $sw.Elapsed.TotalSeconds)

if (-not [string]::IsNullOrWhiteSpace($BackupDir) -and $RetentionDays -gt 0) {
    $cutoff = (Get-Date).AddDays(-$RetentionDays)
    Get-ChildItem -Path $BackupDir -Filter "QL_CUA_HANG_VLXD_*" |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
