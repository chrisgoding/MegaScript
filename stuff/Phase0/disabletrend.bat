::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Disabletrend.bat
:: verifies that symantec is not installed; we don't want to do anything related to trend on a symantec machine
:: makes sure trend is installed, and does not attempt to unload trend if it is not
:: install trend & reboot if no antivirus detected
:: if trend is already stopped, dont bother trying to disable trend
:: calls the command to unload trend. automatically presses enter when prompted
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion &:: Things to make batch files work right
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

set trendunloadpassword=<YourTrendUnloadPassword>
set trendinstallpath=\\<YourOfficeScanServer>\ofcscan\AutoPccP.exe

:Bitnesscheck
	"%SystemPath%\Reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT
		if %OS%==32BIT set bitness==32
		if %OS%==64BIT set bitness==64

:startscript
:symanteccheck &:: verifies that symantec is not installed; we don't want to do anything related to trend on a symantec machine
	if %bitness%==32 goto checkforsymantec32
	if %bitness%==64 goto checkforsymantec64
		:checkforsymantec32
			IF exist "C:\Program Files\Symantec\Symantec Endpoint Protection" ( goto eof ) ELSE ( goto checkforinstalledtrend )

		:checkforsymantec64
			IF exist "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection" ( goto eof ) ELSE ( goto checkforinstalledtrend )

:checkforinstalledtrend
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend" >NUL
	if %errorlevel%==0 goto checkforrunningtrend
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend" >NUL
	if %errorlevel%==0 goto checkforrunningtrend


:installtrend
	if not exist %trendinstallpath% goto eof
	%trendinstallpath%
:installloop
	timeout 600 >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq install.exe"|"%SystemPath%\find.exe" /I "install.exe"
	if %errorlevel% == 0 goto installloop
	"%SystemPath%\tasklist.exe" /FI "imagename eq pccnt.exe"|"%SystemPath%\find.exe" /I "pccnt.exe"
	if %errorlevel% == 0 shutdown /r /f /t 0
	goto startscript


:checkforrunningtrend &:: if trend is already stopped, dont bother trying to disable trend
	"%SystemPath%\tasklist.exe" /FI "imagename eq TMBMSRV.exe"|"%SystemPath%\find.exe" /I "TMBMSRV.exe"
	if %errorlevel% NEQ 0 goto eof
	

:unloadtrend
	if %bitness%==32 goto disabletrend32
	if %bitness%==64 goto disabletrend64
		:disabletrend32 &:: calls the command to unload trend. automatically presses enter when prompted
			type trash.txt | "C:\Program Files\Trend Micro\OfficeScan Client\PccNTMon.exe" -n %trendunloadpassword%
			goto waitfor15

		:disabletrend64
			type trash.txt | "C:\Program Files (x86)\Trend Micro\OfficeScan Client\PccNTMon.exe" -n %trendunloadpassword%
			goto waitfor15
:waitfor15
	timeout 15 >nul
	goto checkforrunningtrend
:eof
timeout 3 >nul
popd
endlocal
