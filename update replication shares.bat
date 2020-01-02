pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

Call :CleanHPIADriverStore
Call :ReplicateMegaScript
Goto EOF

:::::::::::::
::FUNCTIONS::
:::::::::::::

:CleanHPIADriverStore
	for /F "tokens=*" %%A in ( RepShares.txt ) do ( 
	pushd %%A
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" /s /d -180 /c "cmd /c del @file"
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" -d -180 -c "cmd /c IF @isdir == TRUE rd /S /Q @path"
	popd
	)
	pushd \\<YOUR SERVER>\<YOUR SHARE>
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" /s /d -180 /c "cmd /c del @file"
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" -d -180 -c "cmd /c IF @isdir == TRUE rd /S /Q @path"
	pause
	exit /b


:ReplicateMegaScript
	for /F "tokens=*" %%B in ( RepShares.txt ) do ( 
	if exist %%B ( echo Replicating...&& ROBOCOPY "\\<YOUR SERVER>\<YOUR SHARE>" "%%B" /MIR /XD "\\<YOUR SERVER>\<YOUR SHARE>\Logs" /XD "\\<YOUR SERVER>\<YOUR SHARE>\stuff\Phase7\HPIA\Drivers" XD "\\<YOUR SERVER>\<YOUR SHARE>\stuff\Phase7\Dell" /COPY:DT >nul ) else ( echo Share unreachable )
	)
@pause
	exit /b

:EOF

@pause
popd
endlocal
