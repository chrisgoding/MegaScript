pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

del *.log

Call :ClosePrograms
Call :UninstallOldChrome
Call :PerformInstall
goto eof

:ClosePrograms
	"%SystemPath%\tasklist.exe" /FI "imagename eq chrome.exe"|"%SystemPath%\find.exe" /I "chrome.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im chrome.exe >nul
	exit /b

:UninstallOldChrome
	"%SystemPath%\cscript.exe" "RM_Google_Update.vbs" 
	"%SystemPath%\cscript.exe" "RM_Chrome.vbs" 
	"%SystemPath%\tasklist.exe" /FI "imagename eq GoogleUpdate.exe"|"%SystemPath%\find.exe" /I "GoogleUpdate.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im GoogleUpdate.exe >nul
	exit /b

:PerformInstall
	"%SystemPath%\Reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT
	If %OS%==32BIT ( Call :x86 ) else ( Call :x64 )
 	exit /b

	:x86
		"%SystemPath%\msiexec.exe" /i GoogleChromeStandaloneEnterprise.msi NOGOOGLEUPDATEPING=1 /l*v log.txt /qn /norestart
		exit /b

	:x64
		"%SystemPath%\msiexec.exe" /i GoogleChromeStandaloneEnterprise64.msi NOGOOGLEUPDATEPING=1 /l*v log.txt /qn /norestart
		exit /b

:eof
	timeout 15 >nul
	"%SystemPath%\cscript.exe" "RM_Google_Update.vbs" 
	endlocal
	popd
	exit
