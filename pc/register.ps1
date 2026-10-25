# Registers the Windows scheduled task (runs at logon and every hour)
$ErrorActionPreference = 'Stop'
$vbs = Join-Path $env:LOCALAPPDATA 'ChurchThumbnails\run-hidden.vbs'
$a  = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + $vbs + '"')
$t1 = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$t2 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours 1)
$s  = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
Register-ScheduledTask -TaskName 'ChurchThumbnailSync' -Action $a -Trigger $t1, $t2 -Settings $s -Force | Out-Null
