:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: windows 10 upgrader and health checker.bat
::
:: Changelog
:: 2/25/19
::		 - well, the real reason it wasn't working was much dumber. I forgot that when you do a start /wait, the 
::			next set of quotes is the title of the thing that is started. The file path was quoted. rookie 
::			mistake. 
::		 - Now that I don't have any windows 7 PC's in my environment, I've removed the windows 7 upgrade stuff,
::			so that it's slightly less daunting to look at. The old batch file lives in the Tools subdirectory 
::			if it's ever needed in the future.
:: 2/6/20
::		 - love to forget to update my changelogs. Accidentally had two separate PerformUpgrades sections, so 
::			that probably caused the weird "sometimes it works, sometimes it doesn't" nonsense. However, while 
::			troubleshooting it, I added two nice features: 
::		 - robocopy mirroring the install files to the C:\IT Folder, so that a second attempt doesn't use as much
::			bandwidth
::		 - detection of windows log files created during a failed install, to help with troubleshooting problems
:: 12/9/19
::		 - All the goto eof's are exit /b's; the whole script's been functionized
::		 - 1909 support! Create a file "C:\IT Folder\GIVEMEUPDATES.txt" to get it on the next run
::		 - I can't remember when I added it but it has an "every other run" feature to keep it from getting stuck 
::			in a loop of trying to run the in-place upgrade; that way on the next megascript run it'll skip it 
::			and be able to check for windows/driver updates
:: 10/14/19	 - Various missing parentheses fixed. 
::		 - redundant setlocal in the win7readinesscheck function removed.
::		 - added "setupgrade=abort&&" to every "goto eof" that occurs before the performupgrade function, in case
::			I get stupid about how functions in batch files work.
:: 
:: Extract windows 10 iso(s) into a folder named 1809/1903/whatever the build number is
:: Place this script one level up from the folder.
::
:: Cancels immediately on 32 bit machines
:: On windows 10, checks your build number
::	If 1909 or newer, cancel
::	If older, upgrade
:: On Windows XP-8.1, cancel
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
Set BETABuild=1909
Set TestingBuild=1909
Set ProductionBuild=1909
Set Windows10Key=<your windows 10 key here>

Call :CheckForFailures
call :ExcludePublicSafety
Call :BitnessCheck
	if %OS% == 32BIT set upgrade=abort&&goto eof
Call :TrendVersionCheck
Call :WindowsVersion
	if "%version%" == "10.0" Call :Win10BuildCheck
	if "%version%" == "6.3" goto eof
	if "%version%" == "6.2" goto eof
	if "%version%" == "6.1" goto eof
	if "%version%" == "6.0" goto eof
	if "%version%" == "[Version.5" goto eof
Call :PerformUpgrade
::Call :CheckHealth
goto eof


:::::::::::::
::FUNCTIONS::
:::::::::::::

:CheckForFailures
	for /F "tokens=*" %%A in ( tools\loglocation1.txt ) do ( if exist "%%A" echo upgrade failed during installation before the computer restarted for the second time > "C:\IT Folder\megascript progress report\Win 10 upgrade failed at phase 1.txt" 
	if exist %%A xcopy %%A "C:\IT Folder\megascript progress report" /f 
	if exist %%A del %%A /f /s )
	for /F "tokens=*" %%A in ( tools\loglocation3.txt ) do ( if exist "%%A" echo upgrade failed, desktop restored > "C:\IT Folder\megascript progress report\Win 10 upgrade failed-desktop restored.txt" 
	if exist %%A xcopy %%A "C:\IT Folder\megascript progress report" /f 
	if exist %%A del %%A /f /s )
	for /F "tokens=*" %%A in ( tools\loglocation4.txt ) do ( if exist "%%A" echo upgrade failed, installation rollback is initiated > "C:\IT Folder\megascript progress report\Win 10 upgrade failed-installation rollback initiated.txt"
	if exist %%A xcopy %%A "C:\IT Folder\megascript progress report" /f 
	if exist %%A del %%A /f /s )
	exit /b

:ExcludePublicSafety &:: we don't want to run certain steps on certain PC's, so we set a flag here based on the PC name.
	for /F "tokens=*" %%A in ( PublicSafetyPCs.txt ) do ( 
	echo %computername% | "%SystemPath%\find.exe" /i "%%A"
	if errorlevel 0 if not errorlevel 1 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	)
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
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend"
	if %errorlevel% NEQ 0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend Micro Apex One Security Agent"
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%TrendVersion%"
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayVersion" | find "%TrendVersion%"
	if %errorlevel% NEQ 0 (echo Trend Needs to be uninstalled and reinstalled > "C:\it folder\megascript progress report\Trend is too out of date to install windows 10.txt" && set upgrade=abort )
	exit /b

:WindowsVersion &:: from https://stackoverflow.com/a/13212116
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	exit /b

:Win10BuildCheck &:: makes sure you're not running 1909 or higher already
	if %upgrade%==abort exit /b

	FOR /F "tokens=3 USEBACKQ" %%F IN (`reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId`) DO (SET version=%%F)
	if %version%==%BETABuild% set upgrade=uptodate&&exit /b
	if exist "C:\IT Folder\GIVEMEUPDATES.txt" set upgrade=%BETABuild%&&exit /b

	if %version%==%TestingBuild% set upgrade=uptodate&&exit /b

	for %%A in (DIT01500,LIT01500,MIT01500) do (
		echo %computername% | "%SystemPath%\find.exe" /i "%%A"
		if errorlevel 0 if not errorlevel 1 set upgrade=%TestingBuild%&&exit /b )

	if %version%==%ProductionBuild% set upgrade=uptodate&&exit /b
	set upgrade=%ProductionBuild%&&exit /b

:PerformUpgrade
	if exist "C:\IT Folder\megascript progress report\*upgraded windows to*.txt" ( del "C:\IT Folder\megascript progress report\*upgraded windows to*.txt" /F /Q&&set upgrade=abort )
	if exist "C:\IT Folder\megascript progress report\*attempting windows 10 in-place upgrade*.txt" ( del "C:\IT Folder\megascript progress report\*attempting windows 10 in-place upgrade*.txt" /F /Q&&set upgrade=abort )
	if exist "C:\IT Folder\megascript progress report\*attempting windows 10 in-place upgrade*.txt" ( del "C:\IT Folder\megascript progress report\*attempting windows 10 in-place upgrade*.txt" /F /Q&&set upgrade=abort )

	if %upgrade%==uptodate exit /b 
	if %upgrade%==abort exit /b

	:rsatfinder
		dism /online /get-capabilityinfo /capabilityname:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 | find "State : Installed"
		if %errorlevel%==0 echo "Give me back my RSAT!" > "C:\IT Folder\I want RSAT.txt"
	call :GetTime
	Echo attempting windows 10 in-place upgrade > "C:\it folder\megascript progress report\!today!_!now! attempting windows 10 in-place upgrade.txt"	
	if not exist "C:\IT folder\%upgrade%" mkdir "C:\IT folder\%upgrade%"
	robocopy %upgrade% "C:\IT folder\%upgrade%" /MIR

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

	:Installing10
		"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
		timeout 2 >nul
		start "Windows 10 In-Place Upgrade" /wait "C:\IT folder\%upgrade%\setup.exe" /Auto upgrade /pkey %Windows10Key% /DynamicUpdate disable /compat ignorewarning /quiet

		:waitingforsetup
			timeout 120 >nul
			"%SystemPath%\tasklist.exe" |"%SystemPath%\find.exe" /I "setup"
			if %errorlevel% == 0 goto waitingforsetup

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

:eof
	popd
	endlocal
