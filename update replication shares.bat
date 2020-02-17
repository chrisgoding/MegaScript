pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

Call :ReplicateMegaScript
Call :CleanHPIADriverStore

Goto EOF

:::::::::::::
::FUNCTIONS::
:::::::::::::

:ReplicateMegaScript
	for /F "tokens=2" %%B in ( RepShares.txt ) do ( 
	if exist %%B ( echo Replicating...&& ROBOCOPY "\\vboccfs02.polk-county.net\IT_SSM" "%%B" /MIR /XD "\\vboccfs02.polk-county.net\IT_SSM\Logs" /XD "\\vboccfs02.polk-county.net\it_ssm\stuff\Phase7\HPIA\Drivers" XD "\\vboccfs02.polk-county.net\it_ssm\stuff\Phase7\Dell" /COPY:DT >nul ) else ( echo %%B unreachable )
	)
	exit /b

:CleanHPIADriverStore
	for /F "tokens=2" %%A in ( RepShares.txt ) do (
	if exist %%A ( 
	pushd %%A
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" /s /d -180 /c "cmd /c del @file"
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" -d -180 -c "cmd /c IF @isdir == TRUE rd /S /Q @path"
	popd
	) else ( echo %%A unreachable )
	)
	pushd \\vboccfs02.polk-county.net\it_ssm
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" /s /d -180 /c "cmd /c del @file"
	ForFiles /p "%CD%stuff\Phase7\HPIA\Drivers" -d -180 -c "cmd /c IF @isdir == TRUE rd /S /Q @path"
	exit /b

:EOF

@pause
popd
endlocal
