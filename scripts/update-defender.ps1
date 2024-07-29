param(
    [Parameter(Mandatory=$true, HelpMessage="Please provide a value for updatesDir`r`nExample: powershell.exe update-defender.ps1 -updatesDir 'D:\updates'")]
    [string]$updatesDir
)

$defenderUpdates = Get-ChildItem -Path $updatesDir -Filter "mpam-fe*.exe"

if ($defenderUpdates.Count -eq 0) {
    exit
}

$defenderUpdate = $defenderUpdates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$defenderUpdate = $defenderUpdate.FullName

try {
    $process = Start-Process -FilePath $defenderUpdate -PassThru -NoNewWindow -Wait
    if ($process.ExitCode -ne 0) {
        Write-Error "$_"
        exit 1
    }
    $date = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmm")
    Rename-Item $defenderUpdate "$defenderUpdate.$date-INSTALLED"
    $defenderUpdates | Remove-Item -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "$_"
    exit 1
}
