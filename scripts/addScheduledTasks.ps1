$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$Action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Unrestricted -File "C:\ScheduledScripts\update-windows.ps1"  -imagesDir  "D:\images" -updatesDir "D:\updates" -baseImageName "win11pro23h2x64"'
$Action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Unrestricted -File "C:\ScheduledScripts\update-drivers.ps1"  -driversDir "D:\drivers"'
$Action3 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Unrestricted -File "C:\ScheduledScripts\update-defender.ps1" -updatesDir "D:\updates"'
$Action4 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Unrestricted -File "C:\ScheduledScripts\update-edge.ps1"     -updatesDir "D:\updates"'

Register-ScheduledTask -TaskName "RunScriptAtLogon-UpdateWindows"  -Action $Action1 -Trigger $Trigger -Principal $Principal -Settings $Settings
Register-ScheduledTask -TaskName "RunScriptAtLogon-UpdateDrivers"  -Action $Action2 -Trigger $Trigger -Principal $Principal -Settings $Settings
Register-ScheduledTask -TaskName "RunScriptAtLogon-UpdateDefender" -Action $Action3 -Trigger $Trigger -Principal $Principal -Settings $Settings
Register-ScheduledTask -TaskName "RunScriptAtLogon-UpdateEdge"     -Action $Action4 -Trigger $Trigger -Principal $Principal -Settings $Settings