pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

del *.log /F /Q

:closeprograms &:: closes software that may interfere with the installation
	"%SystemPath%\tasklist.exe" /FI "imagename eq outlook.exe"|"%SystemPath%\find.exe" /I "outlook.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im outlook.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq chrome.exe"|"%SystemPath%\find.exe" /I "chrome.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im chrome.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq iexplore.exe"|"%SystemPath%\find.exe" /I "iexplore.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im iexplore.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq excel.exe"|"%SystemPath%\find.exe" /I "excel.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im excel.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq AcroRd32.exe"|"%SystemPath%\find.exe" /I "AcroRd32.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im AcroRd32.exe >nul

:removereader
	"%SystemPath%\cscript.exe" "RM_Reader.vbs"
	timeout 5 >nul
:installreader
	setup.exe -s

:end
	endlocal
	popd
