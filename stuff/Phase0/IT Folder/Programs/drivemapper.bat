pushd "%~dp0"
setlocal enabledelayedexpansion

set sdrive=<path to your s drive>

call :MapHDrive
call :MapSDrive
goto eof

:MapHDrive
	if exist H:\ exit /b
	for /F "tokens=*" %%A in ( HomeDriveServers.txt ) do ( 
	if exist %%A\%username% net use H: %%A\%username% /persistent:yes
	if exist H:\ exit /b )

:MapSDrive 
	if exist S:\ exit /b
	if exist %sdrive% net use S: %sdrive% /persistent:yes
	exit /b

:eof
endlocal
popd
