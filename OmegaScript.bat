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
	::we had some interns trying to run the script on computers that hadnt been named yet, this is some handholding to get them to do things our way
	::"IT-" is the prefix applied to a PC during the imaging process in our environment
	echo %computername% | find "IT-"
	if %errorlevel% NEQ 0 exit /b
	@echo off
	cls
	echo You need to rename this PC.
	echo If this is a BoCC computer, the naming scheme is as follows:
	echo (Computer type)(Division code)(Building Code)N(3 digit number)
	echo Computer type is a single character. Desktops = D, Laptops = L, Tablets = M, Virtual machines = V
	echo Division code is a two character code, which you should be able to look up in the PC naming spreadsheet
	echo The Building Code is a 5 digit number, which you should be able to look up in the PC naming spreadsheet
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
	set NetworkLogDirectory=\\<yourserver>\MegaScript\Logs
	set LocalLogDirectory="C:\IT Folder\Megascript Progress Report"
	::the below are examples, change as needed
	set VLAN1Share=\\reppc1\megascript
	set VLAN1Gateway=10.0.0.1
	set VLAN2Share=\\reppc2\megascript
	set VLAN2Gateway=10.0.1.1
	set VLAN3Share=\\reppc3\megascript
	set VLAN3Gateway=10.0.2.1
	if not exist %locallogdirectory% mkdir %LocalLogDirectory% >nul
	if not exist "%NetworkLogDirectory%\%computername%" mkdir "%NetworkLogDirectory%\%computername%" >nul
	exit /b

:FindRepShare
	ipconfig /all > "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
	find "VLAN1Gateway%" "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
	if %errorlevel%==0 (set workingdirectory=%ITRepShare%&&exit /b) else (set workingdirectory=%~dp0%)
	find "%VLAN2Gateway%" "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
	if %errorlevel%==0 (set workingdirectory=%WRMRepShare%&&exit /b) else (set workingdirectory=%~dp0%)
	find "%VLAN3Gateway%" "C:\IT Folder\Megascript Progress Report\ipconfig.txt"
	if %errorlevel%==0 (set workingdirectory=%UTAdminRepShare%&&exit /b) else (set workingdirectory=%~dp0%)
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
	IF %RunType%=="/Mini" Call :RunMini
	IF %RunType%=="/Mega" Call :RunKaceMega
	IF %RunType%=="/Ultra" Call :RunKaceUltra
	exit /b

:ModeSelectManual
	IF %RunType%=="/Pico" Call :RunPico
	IF %RunType%=="/Mini" Call :RunMini
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

:RunMini
	call :GetTime
	echo %username% > %LocalLogDirectory%"\!today!_!now! MiniScript initiated by %username%.txt"
	call :BatteryCheck
	call :Phase0
	call :Phase1
	call :Phase2
	call :Phase5Quick
	call :Phase6Quick
	call :Phase7
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
	call :Phase7
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
	call :Phase7
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
	call :Phase7
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
	call :Phase7
	call :Chrome
	exit /b

:BatteryCheck
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
	call stuff\phase4\wsus\cmd\doupdate.cmd /instdotnet4 /instwmf /updatercerts /monitoron > %LocalLogDirectory%"\!today!_!now! phase 4.txt"
	call :EndPhase
	exit /b

:Phase4Manual
	call :StartPhase
	call stuff\phase4\wsus\cmd\doupdate.cmd /instdotnet4 /instwmf /updatetsc /updatercerts /updatecpp /monitoron > %LocalLogDirectory%"\!today!_!now! phase 4.txt"
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

:Phase7
	call :StartPhase
	call stuff\phase7\Phase7.bat > %LocalLogDirectory%"\!today!_!now! phase 7.txt"
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
	exit /b

:EndPhase
	echo %cd% | "%SystemPath%\find.exe" "C:\Windows\System32"
	if %errorlevel% NEQ 0 popd && goto EndPhase
	if exist "%NetworkLogDirectory%\%computername%" ( "%SystemPath%\robocopy.exe" %LocalLogDirectory% "%NetworkLogDirectory%\%computername%" /mir >nul )
	exit /b

:GetTime
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	exit /b

:eof
	call :GetTime
	Echo Done! > %LocalLogDirectory%"\!today!_!now! script run complete.txt"
	call :EndPhase
	endlocal
