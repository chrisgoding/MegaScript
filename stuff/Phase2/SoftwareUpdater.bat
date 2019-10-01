::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: softwareupdater.bat
:: This section checks if reader is up to date, and installs it if it is not.
:: This section checks if citrix is installed, and installs it if it is not.
:: This section checks if google earth is installed, and installs it if it is not.
:: This section checks if flash is up to date, and installs it if it is not.
:: This section checks if vault is up to date, and installs it if it is not.
:: This section checks if zscaler is up to date, and installs it if it is not, unless the machine contains paymentus, which is incompatible.
:: This section checks if java 6 is installed, and will upgrade the machine to java 7. if java is not installed at all, it will install java 7.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on
if not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"
if not exist "\\vboccfs02\IT_SSM\Logs\%computername%" mkdir "\\vboccfs02\IT_SSM\Logs\%computername%"

call :SetVariables
call :CleanTemp
call :AdobeReader
call :GoogleEarth
call :AbobeFlash
call :EnterpriseVault
call :Zscaler
goto eof

:SetVariables
	set readerversion=19.012.20040
	set flashversion=32.0.0.255
	set vaultversion=12.4.5488
	set zscalerversion=1.5.1.8
	exit /b

:CleanTemp
	for /D %%f in ("C:\temp\*") do RD /S /Q "%%f" &:: delete folders
	for %%f in ("C:\temp\*") do DEL /F /S /Q "%%f" &:: delete files
	exit /b

:AdobeReader &:: This section checks if reader is up to date, and installs it if it is not.
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat 2017" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat DC" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat XI Pro" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat X Pro" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat 9 Pro" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat XI Standard" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat X Standard" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat 9 Standard" >NUL
	if %errorlevel%==0 goto uninstallreader

	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat 2017" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat DC" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat XI Pro" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat X Pro" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat 9 Pro" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat XI Standard" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat X Standard" >NUL
	if %errorlevel%==0 goto uninstallreader
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Adobe Acrobat 9 Standard" >NUL
	if %errorlevel%==0 goto uninstallreader

	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%readerversion%" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%readerversion%" >NUL
	if %errorlevel%==0 exit /b
	goto upgradereader

	:upgradereader
		if not exist C:\Temp\Stuff\acroreader mkdir C:\Temp\Stuff\acroreader >nul
		"%SystemPath%\robocopy.exe" /MIR acroreader C:\Temp\Stuff\acroreader >nul 
		call c:\temp\stuff\acroreader\install.bat
		exit /b

	:uninstallreader
		"%SystemPath%\cscript.exe" acroreader\RM_Reader.vbs >nul

	exit /b

:GoogleEarth
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Google Earth" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Google Earth" >NUL
	if %errorlevel%==0 exit /b

	:excludepublicsafety
		echo %computername% | "%SystemPath%\find.exe" /i "BENCH"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "BLS"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "BRICE"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "EOC"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "EM"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "FIRE"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "FR"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "GAS"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "RS"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "SU"
		if %errorlevel%==0 exit /b
		echo %computername% | "%SystemPath%\find.exe" /i "TOUGH"
		if %errorlevel%==0 exit /b

	:upgradeGoogleEarth
		if not exist C:\Temp\Stuff\googleearth mkdir C:\Temp\Stuff\googleearth >nul
		"%SystemPath%\robocopy.exe" /MIR googleearth C:\Temp\Stuff\googleearth /E /XC /XN /XO >nul
		call c:\temp\stuff\googleearth\install.bat
		exit /b

:AbobeFlash
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%flashversion%" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%flashversion%" >NUL
	if %errorlevel%==0 exit /b
	goto upgradeflash

	:upgradeflash
		if not exist C:\Temp\Stuff\flash mkdir C:\Temp\Stuff\flash >nul
		"%SystemPath%\robocopy.exe" /MIR flash C:\Temp\Stuff\flash /E /XC /XN /XO >nul
		call c:\temp\stuff\flash\install.bat
		exit /b

:EnterpriseVault
	echo %computername% | "%SystemPath%\find.exe" /i "TOUGH"
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%vaultversion%" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%vaultversion%" >NUL
	if %errorlevel%==0 exit /b
	goto upgradevault

	:upgradevault
		if not exist C:\Temp\Stuff\vault mkdir C:\Temp\Stuff\vault >nul
		"%SystemPath%\robocopy.exe" /MIR vault C:\Temp\Stuff\vault /E /XC /XN /XO >nul
		call c:\temp\stuff\vault\install.bat
		exit /b

:Zscaler
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%zscalerversion%" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Paymentus" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Pulse" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%zscalerversion%" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Paymentus" >NUL
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Pulse" >NUL
	if %errorlevel%==0 exit /b
	goto upgradezscaler

	:upgradezscaler
		if not exist C:\Temp\Stuff\zscaler mkdir C:\Temp\Stuff\zscaler >nul
		"%SystemPath%\robocopy.exe" /MIR zscaler C:\Temp\Stuff\zscaler /E /XC /XN /XO >nul
		call c:\temp\stuff\zscaler\install.bat
		exit /b

:eof
	@pause
	endlocal
	popd
