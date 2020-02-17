setlocal enabledelayedexpansion
Call :IsKace
if %KACERUN%==True goto Elevated
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
:Elevated
set RunType="%~1"
Call :RenamePC
Call :SetVars
Call :RunType
Call :FindRepShare
Call :ShowProgress
Call :PerformScript
goto eof

:::::::::::::
::FUNCTIONS::
:::::::::::::

:IsKace
	echo %cd% | find "KACE"
	if %errorlevel%==0 ( set KACERUN=True ) else (set KACERUN=False )
	exit /b

:RenamePC
	if %KACERUN%==True exit /b
	echo %computername% | find "IT-"
	if %errorlevel% NEQ 0 exit /b
	@echo off
	cls
	echo You need to rename this PC.
	start "" "C:\Program Files (x86)\Microsoft Office\Office16\excel.exe" "\\vboccfs02\IT_PCSupport\Documentation and Instructions\Computer-Name-Spreadsheets\Master All Computer Names.xlsx"
	echo If this is a BoCC computer, the naming scheme is as follows:
	echo (Computer type)(Division code)(Building Code)N(3 digit number)
	echo Computer type is a single character. Desktops = D, Laptops = L, Tablets = M, Virtual machines = V
	echo Division code is a two character code, which you should be able to look up in the PC naming spreadsheet (which opened in the background)
	echo The Building Code is a 5 digit number, which you should be able to look up in the PC naming spreadsheet (which opened in the background)
	echo The 3 digit number at the end is whichever number is available for use. The spreadsheet can provide guidance for this, but you should also check active directory and kace inventory to make sure that the name you want to use is not taken.
	echo Taking a name that is already in use can cause the other computer with that name to be knocked off the domain. Please exercise caution.
	echo Taking a name that is already in use can cause the other computer with that name to be knocked off the domain. Please exercise caution.
	echo Taking a name that is already in use can cause the other computer with that name to be knocked off the domain. Please exercise caution.
	echo Please type the name you would like to assign, then press enter.
	set /p newpcname=
	ping %newpcname% -n 1 | findstr "Reply"
	if %errorlevel%==0 goto renamePC
	WMIC computersystem where caption="%computername%" rename %newpcname%
	timeout 3 >nul
	shutdown -f -r -t 0

:SetVars
ECHO %batchName% Arguments: P1=%1
	@echo on
	pushd "%~dp0"
	IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
	set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
	set NetworkLogDirectory=\\vboccfs02\IT_SSM\Logs
	set LocalLogDirectory="C:\IT Folder\Megascript Progress Report"
	if not exist %locallogdirectory% mkdir %LocalLogDirectory% >nul
	if not exist "%NetworkLogDirectory%\%computername%" mkdir "%NetworkLogDirectory%\%computername%" >nul
	exit /b

:FindRepShare
	ipconfig /all > "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
	for /f "tokens=1-2" %%i in ( repshares.txt ) do (
	find "%%i" "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
	if errorlevel 0 if not errorlevel 1 (set workingdirectory=%%j&&exit /b) else (set workingdirectory=%~dp0%)
	)
	echo Running script from %workingdirectory%
	exit /b

:RunType
	if %RunType% NEQ "" exit /b
	:FixFlag
		timeout 1 >nul
		Echo Type which run you want. Pico, Mini, Mega, or Ultra
		set /p RunType1=
		set Runtype="/%RunType1%"
		if %RunType%=="/Pico" echo Running PicoScript&&exit /b
		if %RunType%=="/Mini" echo Running MiniScript&&exit /b
		if %RunType%=="/Mega" echo Running MegaScript&&exit /b
		if %RunType%=="/Ultra" echo Running UltraScript&&exit /b
		echo input not recognized, please try again
		goto FixFlag

:ShowProgress
	if %KACERUN%==True exit /b
	explorer %LocalLogDirectory%
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
	exit /b

:PerformScript
	if %KACERUN%==True Call :ModeSelectKace
	if %KACERUN%==False Call :ModeSelectManual
	exit /b

:ModeSelectKace
	IF %RunType%=="/Pico" Call :RunPico
	IF %RunType%=="/Mini" Call :RunKaceMini
	IF %RunType%=="/Mega" Call :RunKaceMega
	IF %RunType%=="/Ultra" Call :RunKaceUltra
	exit /b

:ModeSelectManual
	IF %RunType%=="/Pico" Call :RunPico
	IF %RunType%=="/Mini" Call :RunManualMini
	IF %RunType%=="/Mega" Call :RunManualMega
	IF %RunType%=="/Ultra" Call :RunManualUltra
	exit /b

:RunPico
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! PicoScript initiated by %username%.txt"
	call :Phase0
	call :Phase1
	call :Phase5Quick
	call :Phase6Quick
	call :EndPico
	"%SystemPath%\shutdown.exe" -a
	exit /b

:RunKaceMini
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! MiniScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase5Quick
	call :Phase6Quick
	call :Phase7Kace
	call :Chrome
	exit /b

:RunManualMini
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! MiniScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase5Quick
	call :Phase6Quick
	call :Phase7Manual
	call :Chrome
	exit /b

:RunKaceMega
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! MegaScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3No7210
	call :Phase4Kace
	call :Phase5Long
	call :Phase6Ultra
	call :Phase7Kace
	call :Chrome
	exit /b

:RunManualMega
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! MegaScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3No7210
	call :Phase4Manual
	call :Phase5Long
	call :Phase6Medium
	call :Phase7Manual
	call :Chrome
	exit /b

:RunKaceUltra
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! UltraScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3KaceUltra
	call :Phase4Kace
	call :Phase5Long
	call :Phase6Ultra
	call :Phase7Kace
	call :Chrome
	exit /b

:RunManualUltra
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! UltraScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase2.5
	call :Phase3ManualUltra
	call :Phase4Manual
	call :Phase5Long
	call :Phase6Ultra
	call :Phase7Manual
	call :Chrome
	exit /b

:BatteryCheck
exit /b
	WMIC Path Win32_Battery Get BatteryStatus | find "1"
	if %errorlevel%==0 @echo off && cls && echo Running on battery power. Please plug in a power adapter when running the megascript. && timeout 30 >nul && goto eof
	exit /b

:Phase0
	call :StartPhase
	call stuff\phase0\phase0.bat > %LocalLogDirectory%"\!today!_!now! phase 0.txt"
	call :EndPhase
	exit /b

:Phase1
	call :StartPhase
	call stuff\phase1\uninstaller.bat > %LocalLogDirectory%"\!today!_!now! phase 1.txt"
	call :EndPhase
	exit /b

:Phase2
	call :StartPhase
	Echo "Access denied" errors are normal when flash is being updated and are safe to ignore.
	call stuff\phase2\softwareupdater.bat > %LocalLogDirectory%"\!today!_!now! phase 2.txt"
	call :EndPhase
	exit /b

:Phase2.5
	call :StartPhase
	call stuff\phase2.5\Install.bat > %LocalLogDirectory%"\!today!_!now! phase 2.5.txt"
	call :EndPhase
	exit /b

:Phase3No7210
	call :StartPhase
	call stuff\Phase3\phase3.bat /no7210 > %LocalLogDirectory%"\!today!_!now! phase 3.txt"
	call :EndPhase
	exit /b

:Phase3KaceUltra
	call :StartPhase
	call stuff\Phase3\phase3.bat /Default > %LocalLogDirectory%"\!today!_!now! phase 3.txt"
	call :EndPhase
	exit /b

:Phase3ManualUltra
	call :StartPhase
	call stuff\Phase3\phase3.bat /ForceUpgrade > %LocalLogDirectory%"\!today!_!now! phase 3.txt"
	call :EndPhase
	exit /b

:Phase4Kace
	call :StartPhase
	call stuff\phase4\wsus\cmd\doupdate.cmd /instwmf /updatercerts /monitoron > %LocalLogDirectory%"\!today!_!now! phase 4.txt"
	call :EndPhase
	exit /b

:Phase4Manual
	call :StartPhase
	call stuff\phase4\wsus\cmd\doupdate.cmd /instwmf /updatetsc /updatercerts /updatecpp /monitoron > %LocalLogDirectory%"\!today!_!now! phase 4.txt"
	call :EndPhase
	exit /b

:Phase5Quick
	call :StartPhase
	call stuff\phase5\Windows10Changes.bat /quick > %LocalLogDirectory%"\!today!_!now! phase 5.txt"
	call :EndPhase
	exit /b

:Phase5Long
	call :StartPhase
	call stuff\phase5\Windows10Changes.bat /full > %LocalLogDirectory%"\!today!_!now! phase 5.txt"
	call :EndPhase
	exit /b

:Phase6Quick
	call :StartPhase
	call stuff\phase6\cleanup.bat /Quick > %LocalLogDirectory%"\!today!_!now! phase 6.txt"
	call :EndPhase
	exit /b

:Phase6Medium
	call :StartPhase
	call stuff\phase6\cleanup.bat /Medium > %LocalLogDirectory%"\!today!_!now! phase 6.txt"
	call :EndPhase
	exit /b

:Phase6Ultra
	call :StartPhase
	call stuff\phase6\cleanup.bat /Full > %LocalLogDirectory%"\!today!_!now! phase 6.txt"
	call :EndPhase
	exit /b

:EndPico
	call :StartPhase
	pushd stuff\phase7
	call postssm.bat > %LocalLogDirectory%"\!today!_!now! phase 7.txt"
	call :EndPhase
	exit /b

:Phase7Kace
	call :StartPhase
	call stuff\phase7\Phase7.bat /Kace > %LocalLogDirectory%"\!today!_!now! phase 7.txt"
	call :EndPhase
	exit /b

:Phase7Manual
	call :StartPhase
	call stuff\phase7\Phase7.bat /Manual > %LocalLogDirectory%"\!today!_!now! phase 7.txt"
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
	if not exist %workingdirectory% set workingdirectory=%~dp0%
	pushd "%workingdirectory%"
	echo %cd% | find "C:\Windows\System32"
	if %errorlevel% == 0 goto StartPhase
	call :GetTime
	@echo off
	cls
	echo ############################################################################################
	echo This batch window does not contain any useful information. Minimize it and look at the logs.
	echo ############################################################################################
	@echo on
	exit /b

:EndPhase
	echo %cd% | "%SystemPath%\find.exe" "C:\Windows\System32"
	if %errorlevel% NEQ 0 popd && goto EndPhase
	if exist "%NetworkLogDirectory%\%computername%" ( "%SystemPath%\robocopy.exe" %LocalLogDirectory% "%NetworkLogDirectory%\%computername%" /mir >nul )
	exit /b

:GetTime
	@echo off
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	@echo on
	exit /b

:eof
	call :GetTime
	Echo Done! > %LocalLogDirectory%"\!today!_!now! script run complete.txt"
	call :EndPhase
	endlocal
