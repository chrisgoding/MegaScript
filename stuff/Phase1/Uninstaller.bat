:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: uninstaller.bat
:: v1.4 - function'd it + replaced repetitive stuff with for loops and text files
:: v1.3 - added hp system default settings
:: v1.2 - added ask toolbar
:: v1.1 - added hp esu removal
::
:: ends dameware processes
:: uninstalls a whole buncha stuff, each line of the script documents what it uninstalls
:: determines if the machine is a virtual machine, and does not uninstall vmware tools if it is
:: makes sure that the full edition of dameware is not installed, and otherwise uninstalls dameware
:: removes "HP ESU for windows 7" from windows 10 computers
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

@echo on

call :TaskKillDameware
call :GUIDUninstaller
call :PathUninstaller
call :AnnoyingUninstalls
call :HPVelocity
call :VMWareTools
call :Dameware
call :HPesuwin7
goto eof
:::::::::::::
::FUNCTIONS::
:::::::::::::

:TaskKillDameware
	"%SystemPath%\tasklist.exe" /FI "imagename eq DWRCS.exe"|"%SystemPath%\find.exe" /I "DWRCS.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im DWRCS.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq DWRCST.exe"|"%SystemPath%\find.exe" /I "DWRCST.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im DWRCST.exe >nul
	exit /b

:GUIDUninstaller
	for /F "tokens=*" %%A in ( GUIDList.txt ) do ( 
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {%%A} /qn REBOOT=ReallySuppress
	)
	exit /b

:PathUninstaller
	for /F "tokens=*" %%B in ( UninstallPath.txt ) do ( 
	IF exist "%%B" ( start "" "%%B" )
	)
	exit /b

:AnnoyingUninstalls
	IF exist "C:\Program Files (x86)\HP\Digital Imaging\HPSSupply\hpzscr01.exe" ( start "" "C:\Program Files (x86)\HP\Digital Imaging\HPSSupply\hpzscr01.exe" -datfile hpqbud16.dat )
	IF exist "C:\Program Files (x86)\InstallShield Installation Information\{2EDE0C89-892C-4C3C-A922-C4DDE7C68EAE}\Setup.exe" ( start "" "C:\Program Files (x86)\InstallShield Installation Information\{2EDE0C89-892C-4C3C-A922-C4DDE7C68EAE}\Setup.exe" -remove -runfromtemp )
	IF exist "C:\Program Files (x86)\InstallShield Installation Information\{306DD894-F1FA-4548-89F2-43ABDEA45A12}\setup.exe" ( start "" "C:\Program Files (x86)\InstallShield Installation Information\{306DD894-F1FA-4548-89F2-43ABDEA45A12}\setup.exe" -runfromtemp -l0x0409 -removeonly )
	IF exist "C:\Program Files (x86)\InstallShield Installation Information\{4780AF24-213D-4187-86F2-0014A6D6077B}\setup.exe" ( start "" "C:\Program Files (x86)\InstallShield Installation Information\{4780AF24-213D-4187-86F2-0014A6D6077B}\setup.exe" -runfromtemp -l0x0409 -removeonly )
	IF exist "C:\Program Files (x86)\InstallShield Installation Information\{61EB474B-67A6-47F4-B1B7-386851BAB3D0}\setup.exe" ( start "" "C:\Program Files (x86)\InstallShield Installation Information\{61EB474B-67A6-47F4-B1B7-386851BAB3D0}\setup.exe" -runfromtemp -l0x0409 -removeonly )
	IF exist "C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe" ( start "" "C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe" -runfromtemp -l0x0409 -removeonly )
	IF exist "C:\Program Files\HP\Digital Imaging\HPSSupply\hpzscr01.exe" ( start "" "C:\Program Files\HP\Digital Imaging\HPSSupply\hpzscr01.exe" -datfile hpqbud16.dat )
	IF exist "C:\Program Files\HP\HP Touchpoint Analytics Client\TAInstaller.exe" ( start "" "C:\Program Files\HP\HP Touchpoint Analytics Client\TAInstaller.exe" --uninstall --ignore-deployers )
	IF exist "C:\Windows10Upgrade\Windows10UpgraderApp.exe" ( start "" "C:\Windows10Upgrade\Windows10UpgraderApp.exe" /ForceUninstall )
	exit /b

:HPVelocity
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\IPQ_NSIS" /s | "%SystemPath%\find.exe" "DisplayName" |  "%SystemPath%\find.exe" "Velocity" >NUL
		if %errorlevel%==1 goto deletevelocity
	:uninstallvelocity
		"C:\ProgramData\HP\MsiCache\HP Velocity\Setup.exe" /u /qn REBOOT=ReallySuppress
	:deletevelocity
		"%SystemPath%\net.exe" stop ipqservice
		"%SystemPath%\taskkill.exe" /f /im ipqtray.exe
		for /D %%f in ("C:\ProgramData\HP\MsiCache\HP Velocity\*") do RD /S /Q "%%f"   &:: delete folders
		for %%f in ("C:\ProgramData\HP\MsiCache\HP Velocity\*") do DEL /F /S /Q "%%f"   &:: delete files
		if exist "C:\ProgramData\HP\MsiCache\HP Velocity" RD "C:\ProgramData\HP\MsiCache\HP Velocity"
	exit /b

:VMWareTools &:: determines if the machine is a virtual machine, and does not uninstall vmware tools if it is. Doing this because someone forgot to remove VMware tools from the image back in the day.
	"%SystemPath%\systeminfo.exe" > C:\temp\stuff\sysinfo.txt 
	"%SystemPath%\findstr.exe" /e "System Model:              VMware Virtual Platform" C:\temp\stuff\sysinfo.txt
	if %errorlevel%==1 (goto uninstallvmwaretools) else ( exit /b )
		:uninstallvmwaretools 
			for /F "tokens=*" %%A in ( VMWareGUIDs.txt ) do ( 
			START "" /WAIT "%SystemPath%\msiexec.exe" /X {%%A} /qn REBOOT=ReallySuppress
			)
	del /f /s /q C:\temp\stuff\sysinfo.txt
	exit /b

:Dameware &:: makes sure that the full edition of dameware is not installed, and otherwise uninstalls dameware. Doing this because someone accidentally left dameware in the image back in the day.
	if exist temp.txt del temp.txt &:: deletes the temp file created by the vmcheck step
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" |  "%SystemPath%\find.exe" "DameWare Remote Support" >NUL
		if %errorlevel%==0 exit /b
			for /F "tokens=*" %%A in ( DameWareGUIDs.txt ) do ( 
			START "" /WAIT "%SystemPath%\msiexec.exe" /X {%%A} /qn REBOOT=ReallySuppress
			)
	for /F "tokens=*" %%A in ( DameWareFolders.txt ) do ( 
		for /D %%f in ("%%A\*") do RD /S /Q "%%f"
		for %%f in ("%%A\*") do DEL /F /S /Q "%%f"
		if exist "%%A" RD "%%A" )
	exit /b

:HPesuwin7 &:: removes "HP ESU for windows 7" from windows 10 computers
	:windowsversion &:: from https://stackoverflow.com/a/13212116
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	if "%version%" == "10.0" goto uninstallesu
	if "%version%" == "6.3" exit /b
	if "%version%" == "6.2" exit /b
	if "%version%" == "6.1" exit /b
	if "%version%" == "6.0" exit /b

	:uninstallesu
		for /F "tokens=*" %%A in ( HPESU.txt ) do ( 
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {%%A} /qn REBOOT=ReallySuppress
		)
	exit /b

:eof
popd 
endlocal
