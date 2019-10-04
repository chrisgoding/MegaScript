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
echo %userdomain% | find "<CHANGE THIS TO YOUR USERDOMAIN>"
if %errorlevel%==1 ( goto eof )
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\<Change this to the name of the folder that appears in your windows 10 start menu after installing your .wcx file>" goto eof
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\RemoteApp and Desktop Connections\<Change this to the name of the folder that appears in you windows 7 start menu after installing your .wcx file>" goto eof

PowerShell.exe -ExecutionPolicy Bypass -File "C:\IT Folder\Area 51\programs\Install-RADCConnection.PS1"
:eof
exit /b
