:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: DRIVEMAPPER.BAT
:: We have a ton of servers that contain user's home drives. 
:: I used powershell to dump a list of those servers (something like this 
:: https://www.oxfordsbsguy.com/2013/04/16/powershell-get-aduser-to-retrieve-logon-scripts-and-home-directories/)
:: and then created a text file HomeDriveServers.txt with all the home drive paths, minus the usernames.
:: Now, if a user needs to remap their drives, because of a vpn screw up or whatever, 
:: they don't need to know the path, they can just double click this batch.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

pushd "%~dp0"
setlocal enabledelayedexpansion

set sdrive=<your s drive server>

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
