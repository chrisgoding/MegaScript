pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

del *.log

:closeprograms
	"%SystemPath%\tasklist.exe" /FI "imagename eq chrome.exe"|"%SystemPath%\find.exe" /I "chrome.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im chrome.exe >nul

:uninstalloldchrome
	"%SystemPath%\cscript.exe" "RM_Google_Update.vbs" 
	"%SystemPath%\cscript.exe" "RM_Chrome.vbs" 
	"%SystemPath%\tasklist.exe" /FI "imagename eq GoogleUpdate.exe"|"%SystemPath%\find.exe" /I "GoogleUpdate.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im GoogleUpdate.exe >nul

:bitnesscheck
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0"|"%SystemPath%\find.exe" /I "x86">NUL
	If %ERRORLEVEL% == 0 (Goto x86) ELSE (Goto x64)
 
	:x86
		"%SystemPath%\msiexec.exe" /i GoogleChromeStandaloneEnterprise.msi NOGOOGLEUPDATEPING=1 /l*v log.txt /qn /norestart
		goto end

	:x64
		"%SystemPath%\msiexec.exe" /i GoogleChromeStandaloneEnterprise64.msi NOGOOGLEUPDATEPING=1 /l*v log.txt /qn /norestart
		goto end

:end
	timeout 15 >nul
	"%SystemPath%\cscript.exe" "RM_Google_Update.vbs" 
	endlocal enabledelayedexpansion
	popd
	exit
