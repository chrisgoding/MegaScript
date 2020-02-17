pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

call :ClosePrograms
call :RemoveAdobeFlashPlayer
call :CleanTemp
call :InstallFlash
goto eof

:::::::::::::
::Functions::
:::::::::::::

:ClosePrograms
	"%SystemPath%\tasklist.exe" /FI "imagename eq iexplore.exe"|"%SystemPath%\find.exe" /I "iexplore.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im iexplore.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq chrome.exe"|"%SystemPath%\find.exe" /I "chrome.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im chrome.exe >nul
	exit /b

:RemoveAdobeFlashPlayer
	"uninstall_flash_player.exe" -uninstall -force
	exit /b

:CleanTemp 
	for /D %%f in ("%SystemRoot%\System32\Macromed\Flash\*") do RD /S /Q "%%f"
	for %%f in (%SystemRoot%\System32\Macromed\Flash\*") do DEL /F /S /Q "%%f"

	for /D %%f in ("%SystemRoot%\SysWOW64\Macromed\Flash\*") do RD /S /Q "%%f"
	for %%f in ("%SystemRoot%\SysWOW64\Macromed\Flash\*") do DEL /F /S /Q "%%f"

	for /D %%u in ("C:\Users\*") do for /D %%f In ("C:\Users\%%~nxu\AppData\Roaming\Adobe\Flash Player\*") do RD /S /Q "%%f"
	for /D %%u in ("C:\Users\*") do for %%f In ("C:\Users\%%~nxu\AppData\Roaming\Adobe\Flash Player\*") do DEL /F /S /Q "%%f"

	for /D %%u in ("C:\Users\*") do for /D %%f In ("C:\Users\%%~nxu\AppData\Roaming\Macromedia\Flash Player\*") do RD /S /Q "%%f"
	for /D %%u in ("C:\Users\*") do for %%f In ("C:\Users\%%~nxu\AppData\Roaming\Macromedia\Flash Player\*") do DEL /F /S /Q "%%f"
	exit /b

:InstallFlash
	"%SystemPath%\msiexec.exe" /i install_flash_player_32_plugin.msi REINSTALLMODE=vemus /L*v INST_flash_player_32_plugin_32bit.log /qn /norestart
	"%SystemPath%\msiexec.exe" /i install_flash_player_32_ppapi.msi REINSTALLMODE=vemus /L*v INST_flash_player_32_ppapi_32bit.log /qn /norestart
	"%SystemPath%\xcopy.exe" "mms.cfg" "%Systempath%\Macromed\Flash\" /Y
	exit /b

:eof
	endlocal
	popd
