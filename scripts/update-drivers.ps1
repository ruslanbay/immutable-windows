param(
    [Parameter(Mandatory=$true, HelpMessage="Please provide a value for driversDir`r`nExample: powershell.exe update-drivers.ps1 -driversDir 'D:\drivers'")]
    [string]$driversDir
)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run with administrator privileges"
    exit 1
}

$msiFiles = Get-ChildItem -Path $driversDir -Filter "SurfacePro7_Win11_*.msi"
if ($msiFiles.Count -eq 0) {
    exit
}
$msiFile = $msiFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$msiFile = $msiFile.FullName

Remove-Item -Path "$driversDir\temp" -Force -ErrorAction SilentlyContinue
try {
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/a `"$msiFile`" TargetDir=`"$driversDir\temp`" /qn" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "$_"
        exit 1
    }

    $process = Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$driversDir\temp`" /subdirs /install /reboot" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "$_"
        exit 1
    }

    Rename-Item $msiFile "$msiFile.INSTALLED" -PassThru
    $msiFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$driversDir\temp" -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "$_"
    exit 1
}
