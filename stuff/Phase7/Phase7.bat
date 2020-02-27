:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Phase7.bat
:: v1.5
:: Kace doesn't seem to like running HPIA using the same lines I used for the manned run.
:: I wrote a separate function for Kace HPIA, and it kinda sucks, but works. Definitely WIP
:: I've also moved the self cleaning part of the HPIA function to "update replication shares.bat"
:: which you can find in the root of the megascript directory. The cleaning takes a while when you have 50 models,
:: so I didn't want every client to run it.
:: v1.4
:: added HPIA to the mix. SSM is still active, but once testing is complete, I'll have it switch over to all HPIA all the time.
:: I have it creating the download directory on whatever rep share you're running from, and it's self cleaning.
:: v1.3 
:: Updates dell/lenovo/microsoft now. Not to toot my own horn but i think the microsoft one is particularly clever
:: v1.2
:: Combined all the batch files into this one
:: added "exclude statics" section, to avoid removing a static IP off a 
:: machine by upgrading its drivers
::
:: HP/Lenovo/Dell/Surface driver updater
:: excludes VMware hosts
:: excludes machines with static IP's
:: ensures that the PC running the script is an HP. Cancels it otherwise.
:: performs driver updates
:: removes desktop shortcut sometimes created by SSM
:: removes broken startup entry created by 3D Driveguard
:: performs group policy update
:: stops print audit client because it can make reboots hang
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

pushd "%~dp0"
setlocal enabledelayedexpansion
@echo on
if not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"

if "%~1"=="/Kace" set kacerun=true
if "%~1" NEQ "/Kace" set kacerun=false
Call :setVars
Call :ExcludeTommy
Call :ExcludeVMWareHosts
Call :ExcludeStatics
Call :PerformUpdates
Call :PostUpdate
Goto EOF

:::::::::::::
::FUNCTIONS::
:::::::::::::
:setVars
	IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
	set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
	Set UpdateDrivers=True
	set TVUR=%CD%\TVUR\
	set thininstaller="%SYSTEMDRIVE%\Program Files (x86)\ThinInstaller\Thininstaller.exe"
	set log="C:\IT Folder\MegaScript Progress Report"
	set dcu="C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
	set catalog="%cd%\Dell\catalog.xml"
	for /f "usebackq tokens=2 delims==" %%A IN (`wmic csproduct get vendor /value`) DO SET VENDOR=%%A
	for /f "usebackq tokens=2 delims==" %%A IN (`wmic computersystem get model /value`) DO SET MODEL=%%A
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	if "%version%" == "10.0" ( FOR /F "tokens=3 USEBACKQ" %%F IN (`reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId`) DO (SET version=%%F) )
	if "%version%" == "6.3" set version=Windows 8.1
	if "%version%" == "6.2" set version=Windows 8
	if "%version%" == "6.1" set version=Windows 7
	if "%version%" == "6.0" set UpdateDrivers=false&&exit /b
	if "%version%" == "[Version.5" set UpdateDrivers=false&&exit /b
	exit /b

:ExcludeTommy &:: Tommy says that he'd prefer to manage driver updates himself
	echo %computername% | "%SystemPath%\find.exe" "DIT12499N002"
	if %errorlevel%==0 set UpdateDrivers=False
	exit /b

:ExcludeVMWareHosts &:: Updating network drivers can break VM's and force VMWare users to reinstall their software
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" |  "%SystemPath%\find.exe" "VMware" >NUL
	if %errorlevel%==0 set UpdateDrivers=False&&exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" |  "%SystemPath%\find.exe" "VMWare" >NUL
	if %errorlevel%==0 set UpdateDrivers=False&&exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" |  "%SystemPath%\find.exe" "VMware" >NUL
	if %errorlevel%==0 set UpdateDrivers=False&&exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" |  "%SystemPath%\find.exe" "VMWare" >NUL
	if %errorlevel%==0 set UpdateDrivers=False&&exit /b
	exit /b

:ExcludeStatics
	"%SystemPath%\ipconfig.exe" /all|"%SystemPath%\find.exe" /I "DHCP Enabled. . . . . . . . . . . : No"
	if %errorlevel% == 0 ( echo Static IP detected, driver update canceled > "C:\it folder\megascript progress report\Static IP detected.txt"&&set UpdateDrivers=False&&exit /b )
	exit /b

:PerformUpdates
	if "%MODEL%"=="HP Z4 G4 Workstation" exit /b &:: The aftermarket RAM we have in many of our Z4 G4's no longer works in BIOS version 2.41
	If %UpdateDrivers%==False exit /b
	FOR %%G IN ( "Hewlett-Packard" "HP" ) DO ( IF /I "%vendor%"=="%%~G" Call :HPUpdates )
	FOR %%H IN ( "Dell" "Dell Inc." ) DO ( IF /I "%vendor%"=="%%~H" Call :DellCommandUpdate )
	FOR %%I IN ( "Lenovo" "Lenovo Inc." ) DO ( IF /I "%vendor%"=="%%~I" Call :LenovoThinInstaller )
	FOR %%J IN ( "Microsoft Corporation" ) DO ( IF /I "%vendor%"=="%%~J" Call :SurfaceDrivers )
	exit /b

:HPUpdates
	"C:\windows\regedit.exe" /s HPIA\Disable_Open-File_Security_Warning.reg
	set softpaqpath=%CD%\HPIA\Drivers\%MODEL%\%version%
	if not exist "%softpaqpath%" mkdir "%softpaqpath%"
	if %kacerun%==true call :HPIAKACE
	if %kacerun% NEQ true call :HPIAKACE
	"C:\windows\regedit.exe" /s HPIA\Enable_Open-File_Security_Warning.reg
	exit /b

:HPIAManual
	Echo Installing drivers...
	timeout 2 >nul
	start "Driver Updater" /wait "C:\IT Folder\Area 51\programs\HPIA\HPImageAssistant.exe" /Operation:Analyze /Action:Install /Silent /Category:BIOS,Drivers,Firmware /ReportFolder:%log% /SoftpaqDownloadFolder:"%softpaqpath%"
	exit /b

:HPIAKACE
	"%SystemPath%\Robocopy.exe" "%softpaqpath%" "C:\IT Folder\HPIA\Drivers" /MIR
	"%SystemPath%\SCHTASKS.exe" /Create /TN RunHPIA /tr "C:\IT Folder\Area 51\programs\HPIA.bat" /sc ONEVENT /EC Application /MO *[System/EventID=777] /RU "NT AUTHORITY\SYSTEM" /f
	"%SystemPath%\SCHTASKS.exe" /Run /TN "RunHPIA"
	:WaitingForHPIA
	timeout 30 >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq HPImageAssistant.exe"|"%SystemPath%\find.exe" /I "HPImageAssistant.exe"
	if %errorlevel% == 0 goto WaitingForHPIA
	"%SystemPath%\Robocopy.exe" "C:\IT Folder\HPIA\Drivers" "%softpaqpath%" /COPY:DT
	exit /b

:HPSSM
	::leaving this here as a backup, in case HPIA stops working, we can revert back to this easily. None of the branches lead here right now
	%cd%\SSM\SSM.exe %cd%\SSM /accept
	exit /b

:DellCommandUpdate
	if not exist %dcu% start "Dell updater" /wait DCU_Setup_3_1_0.exe /s
	timeout 5 >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq DCU-CLI.exe"|"%SystemPath%\find.exe" /I "DCU-CLI.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im DCU-CLI.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq Dellcommandupdate.exe"|"%SystemPath%\find.exe" /I "Dellcommandupdate.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im Dellcommandupdate.exe >nul
	Start "Dell Command update" /wait %dcu% /applyupdates 
::	if exist "%cd%\Dell\%MODEL%\Catalog.xml" ( %dcu% /catalog "%cd%\Dell\%MODEL%\Catalog.xml" /log %log% ) else ( %dcu% /log %log% ) &:: runs local catalog if it exists, runs internet catalog otherwise
	exit /b

:LenovoThinInstaller
	::insufficiently tested, use at own risk
	if not exist %thininstaller% ( "%TVUR%lenovothininstaller1.3.0007-2019-04-25.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART )
	start "lenovo update" /wait %thininstaller% /CM -search A -action INSTALL -repository "%TVUR%" -noicon -showprogress -includerebootpackages 1,3,4 -noreboot -log %log%
	exit /b

:SurfaceDrivers
	Call :FindModel
	Call :FindBuildNumber
	Call :PerformInstall
	exit /b

:FindModel
	wmic computersystem get model > "C:\IT Folder\MegaScript Progress Report\Model.txt"
	find "Surface Pro 7" "C:\IT Folder\MegaScript Progress Report\Model.txt"
	if %errorlevel%==0 set Model=SurfacePro7&&Exit /b
	find "Surface Pro 6" "C:\IT Folder\MegaScript Progress Report\Model.txt"
	if %errorlevel%==0 set Model=SurfacePro6&&Exit /b
	find "Surface Pro 4" "C:\IT Folder\MegaScript Progress Report\Model.txt"
	if %errorlevel%==0 set Model=SurfacePro4&&Exit /b
	find "Surface Pro 3" "C:\IT Folder\MegaScript Progress Report\Model.txt"
	if %errorlevel%==0 set Model=SurfacePro3&&Exit /b
	find "Surface Pro" "C:\IT Folder\MegaScript Progress Report\Model.txt"
	if %errorlevel%==0 set Model=SurfacePro&&Exit /b
	find "Surface 3" "C:\IT Folder\MegaScript Progress Report\Model.txt"
	if %errorlevel%==0 set Model=Surface3&&Exit /b

:FindBuildNumber
	FOR /F "tokens=3 USEBACKQ" %%F IN (`reg query "HKLM\Software\Microsoft\Windows NT\Currentversion" /v currentbuild`) DO (SET buildnumber=%%F)
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 18363 set buildnumber=18363
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 18362 set buildnumber=18362
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 17763 set buildnumber=17763
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 17134 set buildnumber=17134
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 16299 set buildnumber=16299
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 15063 set buildnumber=15063
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 14393 set buildnumber=14393
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	if %buildnumber% GEQ 10586 set buildnumber=10586
	if exist Microsoft\%Model%*%BuildNumber%*.msi exit /b
	exit /b

:PerformInstall
	for %%f in ( Microsoft\%Model%*%BuildNumber%*.msi ) do (
		if exist "C:\IT Folder\MegaScript Progress Report\%%~nf.txt" exit /b
		xcopy Microsoft\%%~nf.msi C:\Temp /y
		START "Surface Update" /WAIT "%SystemPath%\msiexec.exe" /i C:\Temp\%%~nf.msi /qn /l*v "C:\IT Folder\MegaScript Progress Report\SurfaceProDrivers.log"
		echo Updated Drivers > "C:\IT Folder\MegaScript Progress Report\%%~nf.txt" )
	del "C:\IT Folder\MegaScript Progress Report\Model.txt" /f /s /q
	exit /b

:PostUpdate
	call PostSSM.bat
	exit /b

:eof
	endlocal
	popd
