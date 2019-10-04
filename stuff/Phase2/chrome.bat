pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

set chromeversion=77.0.3865.90

::Chrome is separate from the rest of the software, and called at the end. Why?
::Because Chrome's 64 bit installer likes to cause msiexec to hang, which will basically end the script.
::It doesn't always do it, but it's often enough that I had to separate it.

:chrome
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%chromeversion%" >NUL
	if %errorlevel%==0 goto eof
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayVersion" | "%SystemPath%\find.exe" "%chromeversion%" >NUL
	if %errorlevel%==0 goto eof
	goto upgradechrome

	:upgradechrome
		if not exist C:\Temp\Stuff\chrome mkdir C:\Temp\Stuff\chrome >nul
		"%SystemPath%\robocopy.exe" /MIR chrome C:\Temp\Stuff\chrome >nul
		start "chrome update" c:\temp\stuff\chrome\install.bat
		"%SystemPath%\timeout.exe" 120 >nul
		goto eof

:eof
popd
endlocal


