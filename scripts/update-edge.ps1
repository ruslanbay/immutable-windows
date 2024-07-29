param(
    [Parameter(Mandatory=$true, HelpMessage="Example: powershell.exe update-edge.ps1 -updatesDir 'D:\updates'")]
    [string]$updatesDir
)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run with administrator privileges"
    exit 1
}

$cabFiles = Get-ChildItem -Path $updatesDir -Filter "microsoftedgeenterprisex64_*.cab"
if ($cabFiles.Count -eq 0) {
    exit
}
$cabFile = $cabFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$cabFile = $cabFile.FullName
$msiFile = $cabFile -replace '\.cab$', '.msi'

try {
    $process = Start-Process -FilePath "expand.exe" -ArgumentList "$cabFile $msiFile" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "$_"
        exit 1
    }

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiFile`" /qn /norestart" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "$_"
        exit 1
    }
    Rename-Item "$msiFile" "$msiFile.INSTALLED"
    $cabFiles | Remove-Item -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "$_"
    exit 1
}
