pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on
if not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"

	if exist "C:\Users\Public\Desktop\Synaptics FMA.lnk" del "C:\Users\Public\Desktop\Synaptics FMA.lnk" /F &:: removes desktop shortcut sometimes created by SSM
	"%SystemPath%\reg.exe" delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "AccelerometerSysTrayApplet" /f &:: removes broken startup entry created by 3D Driveguard
	echo N | "%SystemPath%\gpupdate.exe" /force /wait:0 &:: performs group policy update
	"%SystemPath%\sc.exe" query PA6ClientHelper | "%SystemPath%\find.exe" "RUNNING"
	if %errorlevel%==0 "%SystemPath%\net.exe" stop PA6ClientHelper
	"%SystemPath%\tasklist.exe" /FI "imagename eq pa6clint.exe" | "%SystemPath%\find.exe" /I "pa6clint.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im pa6clint.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq pa6clhlp64.exe" | "%SystemPath%\find.exe" /I "pa6clhlp64.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im pa6clhlp64.exe >nul
:runkbot &:: inventories computer and launches any kace managed installs
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT

	if %OS%==32BIT goto runkbot32
	if %OS%==64BIT goto runkbot64

	:runkbot32
		"C:\program files\quest\kace\runkbot" 4 0 >nul
		goto scriptend
	:runkbot64
		"C:\program files (x86)\quest\kace\runkbot" 4 0 >nul
		goto scriptend

:scriptend

:SetPowerScheme
	:importpowerschemes
		if not exist "C:\IT Folder\originalpowersettings.pow" goto powersettingsmissing 
		if not exist "C:\IT Folder\originalpowersettings.txt" goto powersettingsmissing
		for /F "tokens=2 delims=:(" %%i in ('%SystemPath%\powercfg.exe /import "C:\IT Folder\originalpowersettings.pow"') do set GUID2=%%i &:: import the power setting we exported in phase 1 and capture the new GUID generated into a new variable
		for /F "tokens=* delims=" %%i in ('type "C:\IT Folder\originalpowersettings.txt"') do set GUID3=%%i &:: create another variable with the name of the old power scheme
		%SystemPath%\powercfg.exe /setactive%GUID2% &:: set the imported scheme to active
		%SystemPath%\powercfg.exe /CHANGENAME%GUID2% "Original Power Settings"
		%SystemPath%\powercfg.exe /delete%GUID3% &:: delete the temporary scheme
		del /f /q "C:\IT Folder\originalpowersettings.pow" &:: delete the associated file
		del /f /q "C:\IT Folder\originalpowersettings.txt" &:: delete the associated file
		goto eof
	:powersettingsmissing
		%SystemPath%\powercfg.exe -restoredefaultschemes &:: if the power settings were not exported properly or someone has deleted them, restore the default power scheme.

:eof
	endlocal
	popd
