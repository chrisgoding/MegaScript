::::::::::::::::::::::::::::::::::::::::::::
:: Elevate.cmd - Version 4
:: Automatically check & get admin rights
:: see "https://stackoverflow.com/a/12264592/1016343" for description
::::::::::::::::::::::::::::::::::::::::::::
 @echo off
 CLS
 ECHO.
 ECHO =============================
 ECHO Running Admin shell
 ECHO =============================

:init
 setlocal DisableDelayedExpansion
 set cmdInvoke=1
 set winSysFolder=System32
 set "batchPath=%~0"
 for %%k in (%0) do set batchName=%%~nk
 set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
 setlocal EnableDelayedExpansion

:checkPrivileges
  NET FILE 1>NUL 2>NUL
  if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
  if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
  ECHO.
  ECHO **************************************
  ECHO Invoking UAC for Privilege Escalation
  ECHO **************************************

  ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
  ECHO args = "ELEV " >> "%vbsGetPrivileges%"
  ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
  ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
  ECHO Next >> "%vbsGetPrivileges%"

  if '%cmdInvoke%'=='1' goto InvokeCmd 

  ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
  goto ExecElevation

:InvokeCmd
  ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
  ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
 "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
 exit /B

:gotPrivileges
 setlocal & cd /d %~dp0
 if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

 ::::::::::::::::::::::::::::
 ::START
 ::::::::::::::::::::::::::::

:::::::::::::::::
:: MEGASCRIPT.BAT
:::::::::::::::::

pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

set logdirectory=\\yourservername\MegaScript\Logs

:onbattery
WMIC Path Win32_Battery Get BatteryStatus | find "1"
if %errorlevel%==0 @echo off && cls && echo Running on battery power. Please plug in a power adapter when running the megascript. && timeout 30 >nul && goto eof

:startscript
	if not exist "C:\IT Folder\Megascript Progress Report" mkdir "C:\IT Folder\Megascript Progress Report" >nul
	if not exist "%logdirectory%\%computername%" mkdir "%logdirectory%\%computername%" >nul

set today=!date:/=-!
set now=!time::=-!
set millis=!now:*.=!
set now=!now:.%millis%=!
echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! MegaScript initiated by %username%.txt

@echo off
cls
echo.
echo _______________________________________________________________________________
echo To see script progress, please pay attention to 
echo C:\IT Folder\Megascript Progress Report and sort the contents by date modified.
echo.
echo Most errors in this are safe to ignore, but if you're concerned, take a 
echo screenshot and email it to chrisgoding@polk-county.net, along with your PC 
echo name, so that I can find the log file.
echo _______________________________________________________________________________
@echo on

%SystemRoot%\explorer.exe "c:\IT Folder\MegaScript Progress Report"

:phase0
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	Echo Starting Phase 0
	call stuff\phase0\phase0.bat > "C:\it folder\megascript progress report\!today!_!now! phase 0.txt"
	Echo Phase 0 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:uninstallstuff
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 1 - Bad Software Remover
	call stuff\phase1\uninstaller.bat > "C:\it folder\megascript progress report\!today!_!now! phase 1.txt" &:: Removing bad software
	Echo Phase 1 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:updatesoftware
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 2 - Software Updater
	Echo "Access denied" errors are normal when flash is being updated and are safe to ignore.
	call stuff\phase2\softwareupdater.bat > "C:\it folder\megascript progress report\!today!_!now! phase 2.txt"
	Echo Phase 2 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:updateoffice
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 2.5 Office Upgrader
	call stuff\phase2.5\Install.bat > "C:\it folder\megascript progress report\!today!_!now! phase 2.5.txt"
	Echo Phase 2.5 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:inplaceupgrade &:: checks if you are running windows 10, then if you are, checks if you are running 1803 or 1809. if older builds are found, initiates in-place upgrade.
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 3 - Windows Upgrade
	call stuff\Phase3\phase3no7210.bat > "C:\it folder\megascript progress report\!today!_!now! phase 3.txt"
	Echo Phase 3 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:windowsupdate
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 4 - Windows Updates
	call stuff\phase4\wsus\cmd\doupdate.cmd /instdotnet4 /instwmf /updatetsc /updatercerts /updatecpp /monitoron > "C:\it folder\megascript progress report\!today!_!now! phase 4.txt"
	Echo Phase 4 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:win10changes &:: checks if windows 10 is installed, and runs the decrapifier if it is.
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 5 - Win 10 Changes
	call stuff\phase5\changes.bat > "C:\it folder\megascript progress report\!today!_!now! phase 5.txt"
	Echo Phase 5 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:cleanup &:: runs a rather thorough cleanup. this step could take a long time
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 6 - Cleanup
	call stuff\phase6\cleanup.bat > "C:\it folder\megascript progress report\!today!_!now! phase 6.txt"
	Echo Phase 6 Complete
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd

:driverupdate &:: calls HP's System Software Manager to upgrade device drivers, software, and firmware
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	pushd "%~dp0"
	Echo Starting Phase 7 - Driver Update
	call stuff\phase7\ssm.bat > "C:\it folder\megascript progress report\!today!_!now! phase 7.txt"
	Echo Phase 7 Complete
	goto eof

:eof
	popd
	pushd %~dp0"
	call stuff\phase2\chrome.bat
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	Echo Done! > "C:\it folder\megascript progress report\!today!_!now! script run complete.txt"
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	"%SystemPath%\shutdown.exe" -a
	"%SystemPath%\shutdown.exe" -r -t 120 -f
	endlocal
	popd
