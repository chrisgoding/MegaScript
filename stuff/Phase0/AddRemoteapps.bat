:::::::::::::::::::::::::::::::::::::::::::::::::
:: ADDREMOTEAPPS.BAT
:: 
:: Checks if you have a remoteapps connection 
:: by looking for the Polk County (RADC) folder 
:: in the start menu.
:: If the folder is not found, runs a powershell
:: file that uses a .wcx file to automatically 
:: set up the Polk County remote apps.
::
:: email chrisgoding@polk-county.net with any
:: concerns or suggestions
:::::::::::::::::::::::::::::::::::::::::::::::::
echo %userdomain% | find "POLK"
if %errorlevel%==1 ( goto eof )
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Polk County (RADC)" goto eof
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\RemoteApp and Desktop Connections\Polk County" goto eof

PowerShell.exe -ExecutionPolicy Bypass -File "C:\IT Folder\Area 51\programs\Install-RADCConnection.PS1"
:eof
exit /b