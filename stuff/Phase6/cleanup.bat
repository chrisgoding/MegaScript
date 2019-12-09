::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: cleanup.bat
:: v1.1
:: Fixed issue where it would hang while checking the status of the component store
::
:: disables services
:: disables startup entries
:: disables office plugins
:: disables scheduled tasks
:: misc temp files cleanup
:: automated disk cleanup custom ruleset maker
:: runs DISM cleanup commands. Some of the commands are OS version specific, so it checks if you have 7 or 10 and runs the appropriate scripts.
:: runs defraggler
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

if not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"
set RunFlag="%~1"
Call :Services
Call :StartupEntries
Call :OfficePlugins
Call :ScheduledTasks
Call :TempFolderRemoval
Call :TempFilesInaFolder
Call :ObsoleteITFilesRemoval
Call :GoogleGUMTemp
Call :DISMCleanup
Call :DiskCleanup
Call :Defrag
goto eof

:::::::::::::
::FUNCTIONS::
:::::::::::::

:Services &:: disables services listed in the Services.txt file
	for /F "tokens=*" %%A in ( CleanupRulesets\Services.txt ) do (
	"%SystemPath%\sc.exe" query %%A | "%SystemPath%\find.exe" "RUNNING"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\net.exe" stop %%A && "%SystemPath%\sc.exe" config %%A start= disabled)
	exit /b

:StartupEntries &:: disables startup entries listed in the StartupEntries.txt file
	for /F "tokens=*" %%B in ( CleanupRulesets\StartupEntries.txt ) do (
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" | "%SystemPath%\find.exe" "%%B"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\reg.exe" delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "%%B" /f)
	for /F "tokens=*" %%C in ( CleanupRulesets\StartupEntries.txt ) do (
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" | "%SystemPath%\find.exe" "%%C"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\reg.exe" delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "%%C" /f)
	exit /b

:OfficePlugins &:: disables office plugins listed in the OfficePlugins.txt file
	for /F "tokens=*" %%D in ( CleanupRulesets\OfficePlugins.txt ) do (
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Office\Outlook\Addins" | "%SystemPath%\find.exe" "%%D"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\reg.exe" delete "HKLM\SOFTWARE\Microsoft\Office\Outlook\Addins\%%D" /f)
	for /F "tokens=*" %%E in ( CleanupRulesets\OfficePlugins.txt ) do (
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\Outlook\Addins" | "%SystemPath%\find.exe" "%%E"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\reg.exe" delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\Outlook\Addins\%%E" /f)
	exit /b

:ScheduledTasks &:: disables scheduled tasks listed in the ScheduledTasks.txt file
	for /F "tokens=*" %%F in ( CleanupRulesets\ScheduledTasks.txt ) do (
	"%SystemPath%\schtasks.exe" /query | "%SystemPath%\find.exe" "%%F"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\schtasks.exe" /delete /tn "%%F" /f)
	exit /b

:TempFolderRemoval &:: For all folders listed in tempfolders.txt, removes all subfolders within the folder, then all the files, then removes the folder itself.
	for /F "tokens=*" %%A in ( CleanupRulesets\TempFolders.txt ) do ( 
	for /D %%f in ("%%A\*") do RD /S /Q "%%f"
	for %%f in ("%%A\*") do DEL /F /S /Q "%%f"
	if exist "%%A" RD "%%A" )
	exit /b

:TempFilesInaFolder &:: these lines leave the folders alone, but delete the files and folders in them
	for /D %%f in ("C:\temp\*") do RD /S /Q "%%f"   &:: delete folders
	for %%f in ("C:\temp\*") do DEL /F /S /Q "%%f"   &:: delete files

	for /D %%f in ("C:\Windows\Temp\*") do RD /S /Q "%%f"   &:: delete folders
	for %%f in ("C:\Windows\Temp\*") do DEL /F /S /Q "%%f"   &:: delete files

	for /D %%u in ("C:\Users\*") do for /D %%f In ("C:\Users\%%~nxu\AppData\Local\Temp\*") do RD /S /Q "%%f"  &:: delete folders
	for /D %%u in ("C:\Users\*") do for %%f In ("C:\Users\%%~nxu\AppData\Local\Temp\*") do DEL /F /S /Q "%%f" &:: delete files
	exit /b

:ObsoleteITFilesRemoval
	for /F "tokens=*" %%B in ( CleanupRulesets\ObsoleteITFiles.txt ) do if exist "%%B" del /f /q "%%B"
	exit /b

:GoogleGUMTemp
	for /D %%A in ( "C:\Program Files (x86)\GUM*.tmp" ) do ( 
		for /D %%f in ("%%A\*") do RD /S /Q "%%f"
		for %%f in ("%%A\*") do DEL /F /S /Q "%%f"
		if exist "%%A" RD "%%A" )
	exit /b

:DISMCleanup
	if %RunFlag%=="/Quick" exit /b
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	if "%version%" == "10.0" Call :win10
	if "%version%" == "6.3" exit /b
	if "%version%" == "6.2" exit /b
	if "%version%" == "6.1" Call :win7
	if "%version%" == "6.0" exit /b
	exit /b

	:win10
		"%SystemPath%\dism.exe" /online /cleanup-image /analyzecomponentstore /NoRestart | "%SystemPath%\find.exe" "Component Store Cleanup Recommended : No"
		if %errorlevel% == 0 exit /b
		set today=!date:/=-!
		set now=!time::=-!
		set millis=!now:*.=!
		set now=!now:.%millis%=!
		Echo Beginning DISM Cleanup > "C:\it folder\megascript progress report\!today!_!now! beginning DISM cleanup.txt"
		"%SystemPath%\dism.exe" /online /Cleanup-Image /StartComponentCleanup /resetbase
		set today=!date:/=-!
		set now=!time::=-!
		set millis=!now:*.=!
		set now=!now:.%millis%=!
		Echo DISM Cleanup complete > "C:\it folder\megascript progress report\!today!_!now! DISM cleanup complete.txt"
		exit /b

	:win7
		"%SystemPath%\dism.exe" /online /Cleanup-Image /SPSuperseded /HideSP /NoRestart 
		exit /b

:DiskCleanup &:: automated disk cleanup custom ruleset maker. Change the 2 to a 0 for any line you don't want to run
	if %RunFlag%=="/Quick" exit /b
	if %RunFlag%=="/Medium" exit /b
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Diagnostic Data Viewer database files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\DownloadsFolder" /v "StateFlags0001" /t REG_DWORD /d 0 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Language Pack" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions" /v "StateFlags0001" /t REG_DWORD /d 0 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	"%SystemPath%\reg.exe" add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" /v "StateFlags0001" /t REG_DWORD /d 2 /f
	start "disk cleanup" "%SystemPath%\cleanmgr.exe" /dc /sagerun:1 &:: runs the disk cleanup custom ruleset
	exit /b

:Defrag &:: I modified this from TronScript. It uses smartctl to check if the drive is an SSD, in a VM, or failing. If it matches any of the 3, it skips the defrag. If it doesn't match, it uses the windows defrag tool to analyze if the disk is fragmented, then if so, it runs Piriform's defraggler.
	if %RunFlag%=="/Quick" exit /b
	if %RunFlag%=="/Medium" exit /b
	pushd defrag
		for /f %%i in ('smartctl.exe --scan') do smartctl.exe %%i -a | "%SystemPath%\findstr.exe" /i "RAID VMware VBOX XENSRC PVDISK"
			if %errorlevel% == 0 popd&&exit /b
		for /f %%i in ('smartctl.exe --scan') do smartctl.exe %%i -a | "%SystemPath%\find.exe" /i "Read Device Identity Failed"
			if %errorlevel% == 0 popd&&exit /b
	"%SystemPath%\defrag.exe" C: /A | "%SystemPath%\find.exe" "You do not need to defragment this volume."
	if %errorlevel% == 0 popd&&exit /b
			set today=!date:/=-!
			set now=!time::=-!
			set millis=!now:*.=!
			set now=!now:.%millis%=!
			Echo Beginning Defrag > "C:\it folder\megascript progress report\!today!_!now! Beginning Defrag.txt"
			defraggler.exe %SystemDrive% /MinPercent 5)
			set today=!date:/=-!
			set now=!time::=-!
			set millis=!now:*.=!
			set now=!now:.%millis%=!
			Echo Defrag Complete > "C:\it folder\megascript progress report\!today!_!now! Defrag Complete.txt"
	popd
	exit /b

:eof
	endlocal
	popd
