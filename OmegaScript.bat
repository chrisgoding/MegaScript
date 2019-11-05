setlocal enabledelayedexpansion
echo %cd% | find "KACE"
if %errorlevel%==0 ( set KACERUN=True ) else (set KACERUN=False )

if %KACERUN%==True goto start
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

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:start
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

pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

set logdirectory=\\SERVER\MEGASCRIPTSHARE\Logs
set RepShare=\\A_Server_in_the_Remote_VLAN\megascript
set RemoteGateway=<the default gateway of the Remote VLAN>
if not exist "C:\IT Folder\Megascript Progress Report" mkdir "C:\IT Folder\Megascript Progress Report" >nul
if not exist "%logdirectory%\%computername%" mkdir "%logdirectory%\%computername%" >nul

ipconfig > "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
find "%RemoteGateway%" "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
if %errorlevel%==0 ( set workingdirectory=%ITRepShare% ) else ( set workingdirectory=%~dp0% )

IF "%~1" == "" goto FixFlag

if %KACERUN%==True goto ModeSelectKace
if %KACERUN%==False goto ModeSelectManual

:ModeSelectKace
	IF %1==/Pico goto RunPico
	IF %1==/Mini goto RunMini
	IF %1==/Mega goto RunKaceMega
	IF %1==/Ultra goto RunKaceUltra

:ModeSelectManual
	IF %1==/Pico goto RunPico
	IF %1==/Mini goto RunMini
	IF %1==/Mega goto RunManualMega
	IF %1==/Ultra goto RunManualUltra

:RunPico
	call :GetTime
	echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! PicoScript initiated by %username%.txt
	call :Phase0
	call :Phase1
	call :Phase5Quick
	call :Phase6Quick
	call :EndPico
	"%SystemPath%\shutdown.exe" -a
	goto eof

:RunMini
	call :GetTime
	echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! MiniScript initiated by %username%.txt
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase5Quick
	call :Phase6Quick
	call :Phase7
	call :Chrome
	goto eof

:RunKaceMega
	call :GetTime
	echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! MegaScript initiated by %username%.txt
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3No7210
	call :Phase4Kace
	call :Phase5Long
	call :Phase6Ultra
	call :Phase7
	call :Chrome
	goto eof

:RunManualMega
	call :GetTime
	echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! MegaScript initiated by %username%.txt
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3No7210
	call :Phase4Manual
	call :Phase5Long
	call :Phase6Medium
	call :Phase7
	call :Chrome
	goto eof

:RunKaceUltra
	call :GetTime
	echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! UltraScript initiated by %username%.txt
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3KaceUltra
	call :Phase4Kace
	call :Phase5Long
	call :Phase6Ultra
	call :Phase7
	call :Chrome
	goto eof

:RunManualUltra
	call :GetTime
	echo %username% > "C:\IT Folder\Megascript progress report\!today!_!now! UltraScript initiated by %username%.txt
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3ManualUltra
	call :Phase4Manual
	call :Phase5Long
	call :Phase6Ultra
	call :Phase7
	call :Chrome
	goto eof

:FixFlag
timeout 1 >nul
Echo Type which run you want. pico, mini, mega, or ultra
set /p Action=
if %Action%==pico echo Running PicoScript&&goto RunPico
if %Action%==mini echo Running MiniScript&&goto RunMini
if %Action%==mega echo Running MegaScript&&goto RunManualMega
if %Action%==ultra echo Running UltraScript&&goto RunManualUltra
echo input not recognized, please try again
goto FixFlag

:::::::::::::
::FUNCTIONS::
:::::::::::::

:BatteryCheck
	WMIC Path Win32_Battery Get BatteryStatus | find "1"
	if %errorlevel%==0 @echo off && cls && echo Running on battery power. Please plug in a power adapter when running the megascript. && timeout 30 >nul && goto eof
	exit /b

:Phase0
	call :StartPhase
	call stuff\phase0\phase0.bat > "C:\it folder\megascript progress report\!today!_!now! phase 0.txt"
	call :EndPhase
	exit /b

:Phase1
	call :StartPhase
	call stuff\phase1\uninstaller.bat > "C:\it folder\megascript progress report\!today!_!now! phase 1.txt"
	call :EndPhase
	exit /b

:Phase2
	call :StartPhase
	Echo "Access denied" errors are normal when flash is being updated and are safe to ignore.
	call stuff\phase2\softwareupdater.bat > "C:\it folder\megascript progress report\!today!_!now! phase 2.txt"
	call :EndPhase
	exit /b

:Phase2.5
	call :StartPhase
	call stuff\phase2.5\Install.bat > "C:\it folder\megascript progress report\!today!_!now! phase 2.5.txt"
	call :EndPhase
	exit /b

:Phase3No7210
	call :StartPhase
	call stuff\Phase3\phase3.bat /no7210 > "C:\it folder\megascript progress report\!today!_!now! phase 3.txt"
	call :EndPhase
	exit /b

:Phase3KaceUltra
	call :StartPhase
	call stuff\Phase3\phase3.bat /Default > "C:\it folder\megascript progress report\!today!_!now! phase 3.txt"
	call :EndPhase
	exit /b

:Phase3ManualUltra
	call :StartPhase
	call stuff\Phase3\phase3.bat /ForceUpgrade > "C:\it folder\megascript progress report\!today!_!now! phase 3.txt"
	call :EndPhase
	exit /b

:Phase4Kace
	call :StartPhase
	call stuff\phase4\wsus\cmd\doupdate.cmd /instdotnet4 /instwmf /updatercerts /monitoron > "C:\it folder\megascript progress report\!today!_!now! phase 4.txt"
	call :EndPhase
	exit /b

:Phase4Manual
	call :StartPhase
	call stuff\phase4\wsus\cmd\doupdate.cmd /instdotnet4 /instwmf /updatetsc /updatercerts /updatecpp /monitoron > "C:\it folder\megascript progress report\!today!_!now! phase 4.txt"
	call :EndPhase
	exit /b

:Phase5Quick
	call :StartPhase
	call stuff\phase5\Windows10Changes.bat /quick > "C:\it folder\megascript progress report\!today!_!now! phase 5.txt"
	call :EndPhase
	exit /b

:Phase5Long
	call :StartPhase
	call stuff\phase5\Windows10Changes.bat /full > "C:\it folder\megascript progress report\!today!_!now! phase 5.txt"
	call :EndPhase
	exit /b

:Phase6Quick
	call :StartPhase
	call stuff\phase6\quickcleanup.bat > "C:\it folder\megascript progress report\!today!_!now! phase 6.txt"
	call :EndPhase
	exit /b

:Phase6Medium
	call :StartPhase
	call stuff\phase6\cleanup.bat > "C:\it folder\megascript progress report\!today!_!now! phase 6.txt"
	call :EndPhase
	exit /b

:Phase6Ultra
	call :StartPhase
	call stuff\phase6\ultracleanup.bat > "C:\it folder\megascript progress report\!today!_!now! phase 6.txt"
	call :EndPhase
	exit /b

:EndPico
	call :StartPhase
	pushd stuff\phase7
	call disablewifi.bat
	call postssm.bat > "C:\it folder\megascript progress report\!today!_!now! phase 7.txt"
	call :EndPhase
	exit /b

:Phase7
	call :StartPhase
	call stuff\phase7\ssm.bat > "C:\it folder\megascript progress report\!today!_!now! phase 7.txt"
	call :EndPhase
	exit /b

:Chrome
	call :StartPhase
	call stuff\phase2\chrome.bat
	"%SystemPath%\shutdown.exe" -a
	"%SystemPath%\shutdown.exe" -r -t 10 -f
	call :EndPhase
	exit /b

:StartPhase
	call :GetTime
	pushd %workingdirectory%
	exit /b

:EndPhase
	if exist "%logdirectory%\%computername%" ( "%SystemPath%\robocopy.exe" "C:\it folder\megascript progress report" "%logdirectory%\%computername%" /mir >nul )
	popd
	exit /b

:GetTime
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	exit /b

:eof
	call :GetTime!
	Echo Done! > "C:\it folder\megascript progress report\!today!_!now! script run complete.txt"
	call :EndPhase
	endlocal
