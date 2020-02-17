pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

Call :Cleanup
Call :TaskkillOutlook
Call :Bitnesscheck
if %OS%==32BIT ( call :installx86 ) else ( call :x64 )
goto eof

:::::::::::::
::FUNCTIONS::
:::::::::::::

:Cleanup
	del "*.log"
	cd "x86"
	del "*.log"
	cd "../"
	cd "x64"
	del "*.log"
	cd "../"
	exit /b

:TaskkillOutlook
	"%SystemPath%\tasklist.exe" /FI "imagename eq outlook.exe"|"%SystemPath%\find.exe" /I "outlook.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im outlook.exe >nul
	exit /b

:Bitnesscheck
	"%SystemPath%\Reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT
	exit /b

:Uninstall
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {E39FF2F6-AE40-4B2F-AC51-5F3EB4971E93} /qn REBOOT=ReallySuppress
	"%SystemPath%\cscript.exe" "RM_Veritas Enterprise Vault Outlook Add-in.vbs"
	exit /b

:InstallVaultx86
	Call :Uninstall
	cd "x86"
	"%SystemPath%\msiexec.exe" /i "Veritas Enterprise Vault Outlook Add-in (x86).msi" REINSTALLMODE="vemus" /qn /norestart /L*v "Veritas Enterprise Vault Outlook Add-in (x86).log"
	cd "../"
	exit /b

:InstallVaultx64
	Call :Uninstall
	cd "x64"
	"%SystemPath%\msiexec.exe" /i "Veritas Enterprise Vault Outlook Add-in (x64).msi" REINSTALLMODE="vemus" /qn /norestart /L*v "Veritas Enterprise Vault Outlook Add-in (x64).log"
	cd "../"
	exit /b

:EVClient_OL2010
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" Set-ExecutionPolicy -ExecutionPolicy Bypass
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -File "%~dp0WriteToHkcuFromsystem.ps1" -RegFile "%~dp0EVClient_OL2010.reg" -CurrentUser
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -File "%~dp0WriteToHkcuFromsystem.ps1" -RegFile "%~dp0EVClient_OL2010.reg" -ALLUsers
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" Set-ExecutionPolicy -ExecutionPolicy Restricted
	exit /b

:EVClient_OL2013
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" Set-ExecutionPolicy -ExecutionPolicy Bypass
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -File "%~dp0WriteToHkcuFromsystem.ps1" -RegFile "%~dp0EVClient_OL2013.reg" -CurrentUser
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -File "%~dp0WriteToHkcuFromsystem.ps1" -RegFile "%~dp0EVClient_OL2013.reg" -ALLUsers
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" Set-ExecutionPolicy -ExecutionPolicy Restricted
	exit /b

:EVClient_OL2016
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" Set-ExecutionPolicy -ExecutionPolicy Bypass
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -File "%~dp0WriteToHkcuFromsystem.ps1" -RegFile "%~dp0EVClient_OL2016.reg" -CurrentUser
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -File "%~dp0WriteToHkcuFromsystem.ps1" -RegFile "%~dp0EVClient_OL2016.reg" -ALLUsers
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" Set-ExecutionPolicy -ExecutionPolicy Restricted
	exit /b

:installx86

	:INST_WINx86_O2K10x86
		DIR "%ProgramFiles%\Microsoft Office\Office14\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx86_O2K13x86
		Call :InstallVaultx86
		Call :EVClient_OL2010

	:INST_WINx86_O2K13x86
		DIR "%ProgramFiles%\Microsoft Office\Office15\OUTLOOK.EXE|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx86_O2K16x86
		Call :InstallVaultx86
		Call :EVClient_OL2013

	:INST_WINx86_O2K16x86
		DIR "%ProgramFiles%\Microsoft Office\Office16\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto end
		Call :InstallVaultx86
		Call :EVClient_OL2016
	exit /b

:installx64

	:INST_WINx64_O2K10x86
		DIR "%ProgramFiles(x86)%\Microsoft Office\Office14\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx64_O2K13x86
		Call :InstallVaultx64
		Call :EVClient_OL2010

	:INST_WINx64_O2K13x86
		DIR "%ProgramFiles(x86)%\Microsoft Office\Office15\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx64_O2K16x86
		Call :InstallVaultx64
		Call :EVClient_OL2013

	:INST_WINx64_O2K16x86
		DIR "%ProgramFiles(x86)%\Microsoft Office\Office16\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx64_O2K10x64
		Call :InstallVaultx64
		Call :EVClient_OL2016

	:INST_WINx64_O2K10x64
		DIR "%ProgramFiles%\Microsoft Office\Office14\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx64_O2K13x64
		Call :InstallVaultx64
		Call :EVClient_OL2010

	:INST_WINx64_O2K13x64
		DIR "%ProgramFiles%\Microsoft Office\Office15\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto INST_WINx64_O2K16x64
		Call :InstallVaultx64
		Call :EVClient_OL2013

	:INST_WINx64_O2K16x64
		DIR "%ProgramFiles%\Microsoft Office\Office16\OUTLOOK.EXE"|"%SystemPath%\find.exe" /i "OUTLOOK.EXE"
		if %errorlevel% NEQ 0 goto end
		Call :InstallVaultx64
		Call :EVClient_OL2016

	exit /b

:eof
	endlocal
	popd
