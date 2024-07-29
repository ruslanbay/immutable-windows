param(
    [Parameter(Mandatory=$true, HelpMessage="Example: powershell.exe update-windows.ps1 -imagesDir 'D:\images' -updatesDir 'D:\updates' -baseImageName 'win11pro23h2x64'")]
    [string]$imagesDir,
    [string]$updatesDir,
    [string]$baseImageName = "win11pro23h2x64"
)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run with administrator privileges"
    exit 1
}

$currentImagePath = bcdedit.exe /enum "{current}" /v | select-string "osdevice" | % { $_ -match '(\[[a-zA-Z]:\][a-zA-Z0-9:\\-]+.vhdx)' } | % { $Matches[0] }
$currentImagePath = $currentImagePath -replace "[\[\]]", ""
$currentImage = Get-ChildItem $currentImagePath

$bcdIds = bcdedit /enum /v | Where-Object { $_ -match "^identifier\s+(?<id>\{[0-9a-fA-F-]+\})" } | ForEach-Object {
    if ($Matches) {
        $Matches["id"]
    }
}

$updates = Get-ChildItem -Path $updatesDir -Filter "*.msu" | Sort-Object LastWriteTime -Descending
if ($updates.Count -eq 0) {
    exit
}

switch ($currentImage.Name) {
    "$baseImageName-A.vhdx" {
        $updatedImageName = "$baseImageName-B.vhdx"
    }
    "$baseImageName-B.vhdx" {
        $updatedImageName = "$baseImageName-A.vhdx"
    }
    default {
        Write-Error "Error: The image name $currentImage should be '$baseImageName-A.vhdx' or '$baseImageName-B.vhdx'"
        exit 1
    }
}
$updatedImagePath = "$imagesDir\$updatedImageName"
Remove-Item -Path "$updatedImagePath" -Force -ErrorAction SilentlyContinue

try {
    New-VHD -ParentPath "$imagesDir\$baseImageName.vhdx" -Path "$updatedImagePath" -Differencing -ErrorAction Stop
    $vhdx = Mount-VHD -Path "$updatedImagePath" -PassThru
    $driveLetter = (Get-Partition -DiskNumber $vhdx.DiskNumber | Where-Object {$_.Type -eq "Basic"}).DriveLetter


    foreach ($updateFile in $updates) {
        $updateFile = $updateFile.FullName
        $process = Start-Process -FilePath "dism.exe" -ArgumentList "/image:$driveLetter`:\ /add-package /packagepath:$updateFile" -PassThru -Wait -NoNewWindow
        if ($process.ExitCode -ne 0) {
            Write-Error "$_"
            exit 1
        }
        Rename-Item $updateFile "$updateFile.INSTALLED"
    }

    forEach ($bcdId in $bcdIds){
        $bcdEntry = bcdedit /enum "$bcdId" /v
        if ($bcdEntry -match "$updatedImageName") {
            bcdedit /default $bcdId
            exit 0
        }
    }
}
catch {
    Write-Error "$_"
    exit 1
}
