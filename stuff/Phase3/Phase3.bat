:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: windows 10 upgrader and health checker.bat
::
:: Changelog
:: 12/9/19
::		 - All the goto eof's are exit /b's; the whole script's been functionized
::		 - 1909 support! Create a file "C:\IT Folder\GIVEMEUPDATES.txt" to get it on the next run
::		 - I can't remember when I added it but it has an "every other run" feature to keep it from getting stuck in a loop of trying to run the in-place upgrade; that way on the next megascript run it'll skip it and be able to check for windows/driver updates
:: 10/14/19	 - Various missing parentheses fixed. 
::		 - redundant setlocal in the win7readinesscheck function removed.
::		 - added "setupgrade=abort&&" to every "goto eof" that occurs before the performupgrade function, in case
::			I get stupid about how functions in batch files work.
:: 
:: Extract windows 10 iso(s) into a folder named 1809/1903/whatever the build number is
:: Place this script one level up from the folder.
::
:: Note that the script must be called with an option flag, the 3 acceptable ones are
:: /Default - safest option for unattended use
:: /no7210 - Does not perform Windows 7 to 10 in-place-upgrades
:: /ForceUpgrade - Skips the model whitelist check on the Windows 7 readiness check step
:: It is not forgiving about screwing that up. Only the first flag is accepted, so don't mix and match.
::
:: Cancels immediately on 32 bit machines
:: On windows 10, checks your build number
::	If 1809 or newer, check health
::	If older, upgrade
:: On Windows 7-8.1, check model
:: 	If on the whitelist, uninstall conflicting drivers and software
::	then upgrade and reboot
:: On Windows XP, cancel
::
:: Please rerun the megascript after an upgrade to decrapify and add .net 3.5, drivers, and software that was uninstalled.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

if not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"

set upgrade=TBD
set TrendVersion=12.0.5383
set installflag=%1 &:: for some reason I had to change the %1 to this variable to make things work
Set BETABuild=1909
Set TestingBuild=1903
Set ProductionBuild=1809
Set Windows10Key=<your key goes here>
::Set InstallPath=\\<server>\MegaScript\stuff\Phase3

call :ExcludePublicSafety
Call :BitnessCheck
	if %OS% == 32BIT set upgrade=abort&&goto eof
Call :TrendVersionCheck
Call :WindowsVersion
	if "%version%" == "10.0" Call :Win10BuildCheck
	if "%version%" == "6.3" Call :7to10ReadinessCheck
	if "%version%" == "6.2" Call :7to10ReadinessCheck
	if "%version%" == "6.1" Call :7to10ReadinessCheck
	if "%version%" == "6.0" Call :7to10ReadinessCheck
	if "%version%" == "[Version.5" set upgrade=abort&&goto eof
Call :PerformUpgrade
Call :CheckHealth
goto eof


:::::::::::::
::FUNCTIONS::
:::::::::::::

:ExcludePublicSafety &:: we don't want to run certain steps on certain PC's, so we set a flag here based on the PC name.
	echo %computername% | "%SystemPath%\find.exe" /i "PUBLICSAFETY"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "BENCH"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "BLS"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "BRICE"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "EOC"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "EM"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "FIRE"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "FR"
	if %errorlevel%==0 ( set PublicSafety==True && exit /b ) else ( set PublicSafety==False )
	echo %computername% | "%SystemPath%\find.exe" /i "GAS"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "RS"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "SU"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "TOUGH"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	exit /b

:GetTime
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	exit /b

:BitnessCheck
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL&&set OS=32BIT || set OS=64BIT
	exit /b	

:TrendVersionCheck
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend" >NUL
	if %errorlevel% NEQ 0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayVersion" | find "%TrendVersion%"
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayVersion" | find "%TrendVersion%"
	if %errorlevel% NEQ 0 (echo Trend Needs to be uninstalled and reinstalled > "C:\it folder\megascript progress report\Trend is too out of date to install windows 10.txt" && set upgrade=abort )
	exit /b

:WindowsVersion &:: from https://stackoverflow.com/a/13212116
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	exit /b

:Win10BuildCheck &:: makes sure you're not running 1809 or higher already
	if %upgrade%==abort exit /b
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "%BETABuild%" >NUL
	if %errorlevel%==0 set upgrade=uptodate&&exit /b
	if exist "C:\IT Folder\GIVEMEUPDATES.txt" set upgrade=%BETABuild%&&exit /b
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
	if %PublicSafety%==True set upgrade=abort&&exit /b
	if %upgrade%==abort exit /b
	if %installflag% == /no7210 set upgrade=abort&&exit /b
	if exist "C:\IT Folder\megascript progress report\*attempting windows 7-10 upgrade.txt" ( del "C:\IT Folder\megascript progress report\*attempting windows 7-10 upgrade.txt" /F /Q&&set upgrade=abort&&exit /b )
	Call :CheckGal
	if %GAL%==False ( Call :CheckOffice )
	if %installflag% == /Default ( Call :ModelDetect )
	if %installflag% == /ForceUpgrade ( Call :UninstallConflicts )
	if %upgrade% NEQ abort ( Call :ReadyForUpgrade ) else (exit /b )
	exit /b 

	:CheckGAL &:: GAL computers don't have office installed, so this block skips the office check for GAL PC's
		echo %computername% | "%SystemPath%\find.exe" /i "DGL"
		if %errorlevel%==0 ( set GAL=True&&exit /b )
		echo %computername% | "%SystemPath%\find.exe" /i "LGL"
		if %errorlevel%==0 ( set GAL=True&&exit /b )
		echo %computername% | "%SystemPath%\find.exe" /i "MGL"
		if %errorlevel%==0 ( set GAL=True&&exit /b ) else ( set Gal=False&&exit /b )

	:CheckOffice
		IF exist "C:\program files\microsoft office\office16" ( exit /b ) 
		IF exist "C:\program files (x86)\microsoft office\office16" ( exit /b ) ELSE ( set upgrade=abort&&exit /b ) 
	
	:ModelDetect &:: Determines what model the PC is. If it matches the whitelist, continue, otherwise go to end of file.
		if %installflag% == /ForceUpgrade exit /b
		  
		    for /f "tokens=2 delims==" %%a in (
		        'wmic computersystem get model /value'
		    ) do for /f "delims=" %%b in ("%%~a") do for %%m in (
		        "HP ProBook 650 G2" "HP ProDesk 600 G1" "HP ProDesk 600 G1 DM" "HP ProDesk 600 G1 SFF" "HP ProDesk 600 G2 DM" "HP ProDesk 600 G2 SFF" "HP ProDesk 600 G3 DM" "HP ProDesk 600 G4 DM" "HP ProDesk 600 G4 DM (TAA)" "HP EliteBook 820 G3"
		    ) do if /i "%%~b"=="%%~m" (
		        set upgrade=%ProductionBuild%&&exit /b
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
		rem IF exist "C:\Program Files\Conexant\SA3\HP-NB-AIO\SETUP64.EXE" ( start /wait "" "C:\Program Files\Conexant\SA3\HP-NB-AIO\SETUP64.EXE" -U -ISA3 -SWTM="HDAudioAPI-D9A3021B-9BCE-458C-B667-9029C4EF4050,1801" ) &:: uninstalls Conexant Audio
		IF exist "C:\Program Files\CONEXANT\CNXT_AUDIO_HDA\UIU64a.exe" ( start /wait "" "C:\Program Files\CONEXANT\CNXT_AUDIO_HDA\UIU64a.exe" -U -G -Ichdrt.inf ) &:: uninstalls Conexant Audio
		IF exist "C:\Program Files\Conexant\FUNC_01&VEN_14F1&DEV_50F4&SUBSYS_103C807C\UIU64a.exe" ( start /wait "" "C:\Program Files\Conexant\FUNC_01&VEN_14F1&DEV_50F4&SUBSYS_103C807C\UIU64a.exe" -U -1 -IFUNC_01&VEN_14F1&DEV_50F4&SUBSYS_103C807C ) &:: uninstalls Conexant Audio
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {2C1172CA-16D8-AF5F-1A4C-B822D26EBD99} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {6119B3A6-3603-9695-0398-CDF2AF0A13F8} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {6F483F38-6162-7606-1D0B-054852C8E011} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {891B07A5-2A94-4BE4-7721-0949E9210BD7} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {A70B905D-2E57-66A0-3BFE-66B8E71E0C70} /qn REBOOT=ReallySuppress &:: AMD Catalyst Install Manager
		"%SystemPath%\cscript.exe" "RM_MinuteTraq.vbs"
		"%SystemPath%\cscript.exe" "RM_ProjectDox.vbs"
		set upgrade=%ProductionBuild%
		exit /b

	:ReadyForUpgrade
		for /D %%u in ("C:\Users\*") do copy "Windows 10 Quick Reference Guide.pdf" "%%u\Desktop\"
		del "C:\users\public\desktop\Windows 10 Quick Reference Guide.pdf" /f /s /q
		Call :GetTime
		Echo attempting windows 7-10 upgrade > "C:\it folder\megascript progress report\!today!_!now! attempting windows 7-10 upgrade.txt"
		echo %upgrade% will be installed && exit /b

:PerformUpgrade
	if exist "C:\IT Folder\megascript progress report\*upgraded windows to*.txt" ( del "C:\IT Folder\megascript progress report\*upgraded windows to*.txt" /F /Q&&set upgrade=abort )

	if %upgrade%==uptodate exit /b 
	if %upgrade%==abort exit /b
	
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
		start /wait %upgrade%\setup.exe /Auto upgrade /pkey %Windows10Key% /DynamicUpdate disable /compat ignorewarning /installfrom %cd%\%upgrade%\sources\install.wim

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
		timeout 60 >nul
		exit /b

:CheckHealth
	if "%version%" NEQ "10.0" exit /b
	:Timesaver &:: only checks health every third run; if there's already a "windows health is good" file, delete it and skip this step. Then next time, the file won't be there, and it'll scan.
		if exist "C:\IT Folder\megascript progress report\Windows health is good.txt" del /f /q "C:\IT Folder\megascript progress report\Windows health is good.txt"&&echo Skipping again... > "C:\IT Folder\megascript progress report\Windows health was good.txt"&&exit /b
		if exist "C:\IT Folder\megascript progress report\Windows health was good.txt" del /f /q "C:\IT Folder\megascript progress report\Windows health was good.txt"&&exit /b

	"%SystemPath%\DISM.exe" /Online /Cleanup-Image /CheckHealth | "%SystemPath%\find.exe" "No component store corruption detected."
	if %errorlevel%==1 goto badhealth

	"%SystemPath%\DISM.exe" /Online /Cleanup-Image /ScanHealth > "C:\it folder\megascript progress report\Scanning_windows_health.txt"
	"%SystemPath%\find.exe" "No component store corruption detected." "C:\it folder\megascript progress report\Scanning_windows_health.txt"
	if %errorlevel%==0 goto goodhealth

	:badhealth
		"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1909" >NUL
		if %errorlevel%==0 set windowsversion=1909&&goto restorehealth
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
	popd
	endlocal
