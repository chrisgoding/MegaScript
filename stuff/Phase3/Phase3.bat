:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: windows 10 upgrader and health checker.bat
:: 
:: Extract windows 10 iso(s) into a folder named 1809/1903/whatever the build number is
:: Place this script one level up from the folder.
::
:: Note that the script must be called with an option flag, the 3 acceptable ones are
:: /Default
:: /no7210 - Does not perform Windows 7 to 10 in-place-upgrades
:: /ForceUpgrade - Skips the model whitelist check on the Windows 7 readiness check step
::
:: Cancels immediately on 32 bit machines
:: On windows 10, checks your build number
::	If 1809 or newer, check health
::	If older, upgrade
:: On Windows 7-8.1, check model
:: 	If on the whitelist, uninstall conflicting drivers and software
::	then upgrade and reboot
:: On Windows XP, cancel, and question why you have XP machines in your environment
::
:: Please rerun the megascript after an upgrade to decrapify and add .net 3.5, drivers, and software that was uninstalled.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

if not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"

Set TestingBuild=1903
Set ProductionBuild=1809
Set Windows10Key=<Your Windows 10 Key goes here>
Set InstallPath=\\<Server>\<MegaScriptShare>\stuff\Phase3

Call :BitnessCheck
	if %OS% == 32BIT goto eof
Call :WindowsVersion
	if "%version%" == "10.0" Call :Win10BuildCheck
	if "%version%" == "6.3" Call :7to10ReadinessCheck
	if "%version%" == "6.2" Call :7to10ReadinessCheck
	if "%version%" == "6.1" Call :7to10ReadinessCheck
	if "%version%" == "6.0" Call :7to10ReadinessCheck
	if "%version%" == "[Version.5" goto eof
Call :Upgrade
Call :CheckHealth
goto eof


:::::::::::::
::FUNCTIONS::
:::::::::::::

:GetTime
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	exit /b

:BitnessCheck
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL&&set OS=32BIT || set OS=64BIT
	exit /b	

:WindowsVersion &:: from https://stackoverflow.com/a/13212116
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	exit /b

:Win10BuildCheck &:: makes sure you're not running 1809 or higher already
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "%TestingBuild%" >NUL
	if %errorlevel%==0 set upgrade=uptodate&&exit /b
	echo %computername% | "%SystemPath%\find.exe" /i "DIT01500"
	if %errorlevel%==0 set upgrade=%TestingBuild%&&exit /b
	echo %computername% | "%SystemPath%\find.exe" /i "LIT01500"
	if %errorlevel%==0 set upgrade=%TestingBuild%&&exit /b
	echo %computername% | "%SystemPath%\find.exe" /i "MIT01500"
	if %errorlevel%==0 set upgrade=%TestingBuild%&&exit /b
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "%ProductionBuild%" >NUL
	if %errorlevel%==0 set upgrade=uptodate&&exit /b
	call :GetTime
	Echo attempting windows 10 in-place upgrade > "C:\it folder\megascript progress report\!today!_!now! attempting windows 10 in-place upgrade.txt"
	set upgrade=%ProductionBuild%&&exit /b

:7to10ReadinessCheck
		if %1==/no7210 set upgrade=abort&&exit /b
	:CheckOffice
		IF exist "C:\program files\microsoft office\office14\outlook.exe" ( set upgrade=abort&&exit /b ) 
		IF exist "C:\program files (x86)\microsoft office\office14\outlook.exe" ( set upgrade=abort&&exit /b )  

	:ModelDetect &:: Determines what model the PC is. If it matches the whitelist, continue, otherwise go to end of file.
		if %1==/ForceUpgrade goto UninstallConflicts
	    setlocal enableextensions disabledelayedexpansion

	    for /f "tokens=2 delims==" %%a in (
	        'wmic computersystem get model /value'
	    ) do for /f "delims=" %%b in ("%%~a") do for %%m in (
	        "HP ProDesk 600 G1 DM" "HP ProDesk 600 G2 DM" "HP ProDesk 600 G3 DM" "HP ProDesk 600 G4 DM" "HP ProDesk 600 G4 DM (TAA)" "HP EliteBook 820 G3"
	    ) do if /i "%%~b"=="%%~m" (
	        set "model=%%~m"
	        goto UninstallConflicts
	    )

   		 echo Model is not whitelisted for unattended installation of windows 10 > "C:\it folder\megascript progress report\Windows 10 upgrade canceled due to model.txt"&&set upgrade=abort&&exit /b

	:UninstallConflicts &:: removes software and drivers that will cause the windows 7 to 10 upgrade to fail
		Echo this text file is important, don't delete it > "C:\it folder\windowsupgrade.txt" &:: creates a file in the IT Folder to make Word launch the next time you run the megascript, to avoid the admin prompt that you will otherwise get
		IF exist "C:\Program Files (x86)\Intel\Intel(R) Processor Graphics\Uninstall\igxpin.exe" ( start /wait "" "C:\Program Files (x86)\Intel\Intel(R) Processor Graphics\Uninstall\igxpin.exe" -uninstall -s ) &:: uninstalls intel graphics drivers
		IF exist "C:\Program Files (x86)\InstallShield Installation Information\{E3A5A8AB-58F6-45FF-AFCB-C9AE18C05001}\Setup.exe" ( start /wait "" "C:\Program Files (x86)\InstallShield Installation Information\{E3A5A8AB-58F6-45FF-AFCB-C9AE18C05001}\Setup.exe" -remove -removeonly ) &:: uninstalls IDT Audio
		IF exist "C:\Program Files\AMD\CIM\Bin64\RadeonInstaller.exe" ( start /wait "" "C:\Program Files\AMD\CIM\Bin64\RadeonInstaller.exe" /EXPRESS_UNINSTALL /IGNORE_UPGRADE /ON_REBOOT_MESSAGE:NO ) &:: uninstalls AMD Software
		IF exist "C:\Program Files\AMD\CIM\Bin64\InstallManagerApp.exe" ( start /wait "" "C:\Program Files\AMD\CIM\Bin64\InstallManagerApp.exe" /UNINSTALL /IGNORE_UPGRADE /ON_REBOOT_MESSAGE:NO ) &:: uninstalls AMD Software
		IF exist "C:\Program Files\AMD\WU-CCC2\ccc2_install\WULaunchApp.exe" ( start /wait "" "C:\Program Files\AMD\WU-CCC2\ccc2_install\WULaunchApp.exe" -uninstall ) &:: uninstalls AMD Software
		IF exist "C:\Program Files\InstallShield Installation Information\{E3A5A8AB-58F6-45FF-AFCB-C9AE18C05001}\Setup.exe" ( start /wait "" "C:\Program Files\InstallShield Installation Information\{E3A5A8AB-58F6-45FF-AFCB-C9AE18C05001}\Setup.exe" -remove -removeonly ) &:: uninstalls IDT Audio
		IF exist "C:\Program Files (x86)\InstallShield Installation Information\{E3A5A8AB-58F6-45FF-AFCB-C9AE18C05001}\Setup.exe" ( start /wait "" "C:\Program Files (x86)\InstallShield Installation Information\{E3A5A8AB-58F6-45FF-AFCB-C9AE18C05001}\Setup.exe" -remove -removeonly ) &:: uninstalls IDT Audio
		IF exist "C:\Program Files\Conexant\SA3\HP-NB-AIO\SETUP64.EXE" ( start /wait "" "C:\Program Files\Conexant\SA3\HP-NB-AIO\SETUP64.EXE" -U -ISA3 -SWTM="HDAudioAPI-D9A3021B-9BCE-458C-B667-9029C4EF4050,1801" ) &:: uninstalls Conexant Audio
		IF exist "C:\Program Files\CONEXANT\CNXT_AUDIO_HDA\UIU64a.exe" ( start /wait "" "C:\Program Files\CONEXANT\CNXT_AUDIO_HDA\UIU64a.exe" -U -G -Ichdrt.inf ) &:: uninstalls Conexant Audio
		IF exist "C:\Program Files\Conexant\FUNC_01&VEN_14F1&DEV_50F4&SUBSYS_103C807C\UIU64a.exe" ( start /wait "" "C:\Program Files\Conexant\FUNC_01&VEN_14F1&DEV_50F4&SUBSYS_103C807C\UIU64a.exe" -U -1 -IFUNC_01&VEN_14F1&DEV_50F4&SUBSYS_103C807C ) &:: uninstalls Conexant Audio
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {2C1172CA-16D8-AF5F-1A4C-B822D26EBD99} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {6119B3A6-3603-9695-0398-CDF2AF0A13F8} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {6F483F38-6162-7606-1D0B-054852C8E011} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {891B07A5-2A94-4BE4-7721-0949E9210BD7} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {A70B905D-2E57-66A0-3BFE-66B8E71E0C70} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		"%SystemPath%\cscript.exe" "RM_MinuteTraq.vbs"
		"%SystemPath%\cscript.exe" "RM_ProjectDox.vbs"
		Call :GetTime
		Echo attempting windows 7-10 upgrade > "C:\it folder\megascript progress report\!today!_!now! attempting windows 7-10 upgrade.txt"
		set upgrade=%ProductionBuild%&&exit /b

:Upgrade
	if %upgrade%==uptodate exit /b 
	if %upgrade%==abort exit /b
	:CheckForFailedAttempt &:: skips upgrade attempt if upgrade failed last time, in order to let drivers be installed before the next try
		if exist "C:\IT Folder\megascript progress report\*upgraded windows to %upgrade%.txt" ( del "C:\IT Folder\megascript progress report\*upgraded windows to %upgrade%.txt" /F /Q&&exit /b )

	:RemovePreviousAttempts
		for /D %%f in ("C:\Windows10Upgrade\*") do RD /S /Q "%%f"
		for %%f in ("C:\Windows10Upgrade\*") do DEL /F /S /Q "%%f"
		if exist C:\Windows10Upgrade RD C:\Windows10Upgrade

		for /D %%f in ("C:\win10upgrade\*") do RD /S /Q "%%f"
		for %%f in ("C:\win10upgrade\*") do DEL /F /S /Q "%%f"
		if exist C:\win10upgrade RD C:\win10upgrade

		for /D %%f in ("C:\windows.old\*") do RD /S /Q "%%f"
		for %%f in ("C:\windows.old\*") do DEL /F /S /Q "%%f"
		if exist C:\windows.old RD C:\windows.old

	:RescheduleShutdown
		"%SystemPath%\shutdown.exe" -a
		"%SystemPath%\shutdown.exe" -f -r -t 10800

	:PerformUpgrade
		"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
		start /wait %upgrade%\setup.exe /Auto upgrade /pkey %Windows10Key% /DynamicUpdate disable /compat ignorewarning /installfrom %InstallPath%\%upgrade%\sources\install.wim

		Call :GetTime
		Echo Upgraded Windows > "C:\it folder\megascript progress report\!today!_!now! upgraded windows to %windowsversion%.txt"

		"%SystemPath%\sc.exe" query PA6ClientHelper | "%SystemPath%\find.exe" "RUNNING"
		if %errorlevel%==0 "%SystemPath%\net.exe" stop PA6ClientHelper

		"%SystemPath%\tasklist.exe" /FI "imagename eq pa6clint.exe"|"%SystemPath%\find.exe" /I "pa6clint.exe"
		if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im pa6clint.exe >nul

		"%SystemPath%\tasklist.exe" /FI "imagename eq pa6clhlp64.exe"|"%SystemPath%\find.exe" /I "pa6clhlp64.exe"
		if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im pa6clhlp64.exe >nul

		timeout 5 >nul
		"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg
		"%SystemPath%\shutdown.exe" -a
		"%SystemPath%\shutdown.exe" -r -f -t 0
		exit /b

:CheckHealth
	if "%version%" NEQ "10.0" exit /b
	:Timesaver &:: only checks health every third run; if there's already a "windows health is good" file, delete it and skip this step. Then next time, the file won't be there, and it'll scan.
		if exist "C:\IT Folder\megascript progress report\Windows health is good.txt" del /f /q "C:\IT Folder\megascript progress report\Windows health is good.txt"&&echo Skipping again... > "C:\IT Folder\megascript progress report\Windows health was good.txt" exit /b
		if exist "C:\IT Folder\megascript progress report\Windows health was good.txt" del /f /q "C:\IT Folder\megascript progress report\Windows health was good.txt"&&exit /b

	"%SystemPath%\DISM.exe" /Online /Cleanup-Image /CheckHealth | "%SystemPath%\find.exe" "No component store corruption detected."
	if %errorlevel%==1 goto badhealth

	"%SystemPath%\DISM.exe" /Online /Cleanup-Image /ScanHealth > "C:\it folder\megascript progress report\Scanning_windows_health.txt"
	"%SystemPath%\find.exe" "No component store corruption detected." "C:\it folder\megascript progress report\Scanning_windows_health.txt"
	if %errorlevel%==0 goto goodhealth

	:badhealth
		"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1903" >NUL
		if %errorlevel%==0 set windowsversion=1903&&goto restorehealth
		"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1809" >NUL
		if %errorlevel%==0 set windowsversion=1809&&goto restorehealth
		goto eof

		:restorehealth
			"%SystemPath%\DISM.exe" /Online /Cleanup-Image /RestoreHealth /Source:%windowsversion%\sources\install.wim > "C:\it folder\megascript progress report\Restoring_windows_health.txt"
			timeout 5 >nul
			exit /b

	:goodhealth
		echo No errors found during DISM ScanHealth operation. > "C:\it folder\megascript progress report\Windows health is good.txt"
		exit /b

:eof
	if exist "C:\it folder\megascript progress report\Restoring_windows_health.txt" findstr "DISM failed" "C:\it folder\megascript progress report\Restoring_windows_health.txt"
	if %errorlevel%==0 findstr "DISM failed" "C:\it folder\megascript progress report\Restoring_windows_health.txt" > "C:\it folder\megascript progress report\COULD NOT REPAIR WINDOWS HEALTH.txt"&&del "C:\it folder\megascript progress report\Restoring_windows_health.txt"

	popd
	endlocal
