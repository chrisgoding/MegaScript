pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

set Zscaler.exe=Zscaler-windows-1.5.1.8-installer.exe
set TrendUnloadPassword=TrendBoCC

:checkforrunningtrend &:: if trend is already stopped, dont bother trying to disable trend
	"%SystemPath%\tasklist.exe" /FI "imagename eq TMBMSRV.exe"|"%SystemPath%\find.exe" /I "TMBMSRV.exe"
	if %errorlevel%==1 goto install
	goto bitnesscheck

:bitnesscheck &:: https://stackoverflow.com/a/24590583
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT
	if %OS%==32BIT goto disabletrend32
	if %OS%==64BIT goto disabletrend64

:disabletrend32
	type enter.txt | "C:\Program Files\Trend Micro\OfficeScan Client\PccNTMon.exe" -n %TrendUnloadPassword%
	goto loop1

:disabletrend64
	type enter.txt | "C:\Program Files (x86)\Trend Micro\OfficeScan Client\PccNTMon.exe" -n %TrendUnloadPassword%
	goto loop1

	:loop1
		"%SystemPath%\tasklist.exe" /FI "imagename eq TMBMSRV.exe"|"%SystemPath%\find.exe" /I "TMBMSRV.exe"
		if %errorlevel%==0 goto waitingontrend
		goto install

	:waitingontrend
		"%SystemPath%\timeout.exe" /t 15
		"%SystemPath%\tasklist.exe" /FI "imagename eq ntrtscan"|"%SystemPath%\find.exe" /I "ntrtscan"
		if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im ntrtscan >nul
		goto Loop1

:install
	pushd "%~dp0"
	%Zscaler.exe% --mode unattended

	:Loop2
		"%SystemPath%\tasklist.exe" /FI "imagename eq ZSATray.exe"|"%SystemPath%\find.exe" /I "ZSATray.exe"
		if %errorlevel%==1 goto PauseInstall
		goto megascriptdetect

		:megascriptdetect &:: checks for the presence of a folder that only exists if this script was called by the megascript. If megascript is running, we want to leave trend off because we're going to reboot anyway. If megascript is not running, trend will be reenabled if it is installed.
			IF exist "C:\Temp\Stuff\Zscaler" ( goto eof ) ELSE ( goto ContinueInstall )

	:PauseInstall
		"%SystemPath%\timeout.exe" /t 15
		goto Loop2

:ContinueInstall
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT
	if %OS%==32BIT goto enabletrend32
	if %OS%==64BIT goto enabletrend64

	:enabletrend32
		IF exist "C:\Program Files\Trend Micro\OfficeScan Client" ( start "Trend Micro Officescan Agent" "C:\Program Files\Trend Micro\OfficeScan Client\PccNTMon.exe" ) ELSE ( goto eof )

	:enabletrend64
		IF exist "C:\Program Files (x86)\Trend Micro\OfficeScan Client" ( start "Trend Micro Officescan Agent" "C:\Program Files (x86)\Trend Micro\OfficeScan Client\PccNTMon.exe" ) ELSE ( goto eof )

:eof
	endlocal
	popd
