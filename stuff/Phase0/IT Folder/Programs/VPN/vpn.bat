:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: VPN.BAT
:: Our users requested a double clickable desktop icon for the VPN connection.
:: I tried to make it as user friendly as I could.
:: TODO: use a "call function" workflow instead of a "goto" workflow, to make it 
:: easier to see what it's doing and more modular.
:: email chrisgoding@polk-county.net with suggestions/comments/concerns
:: 
:: deletes files created by previous run
:: dumps list of vpn connections to a text file
:: reads the text file to see if the %VPNName% connection was already created
:: if connection already exists, dial it. If it doesn't, create it.
:: adds new vpn connection, presses enter automatically when prompted
:: Initiates VPN connection
:: dumps output of ipconfig to ip.txt
:: checks for "%VPNName%" in ip.txt
:: if "%VPNName%" was found, show success message. If not, show troubleshooting steps.
:: maps user's shared drives.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

set VPNName=<what youd like to call your vpn connection>
set sdrive=<the path to your s drive>

:start
	echo off
	cls
	del "C:\IT Folder\Area 51\Programs\VPN\applist.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\ip.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\pingtest.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\pingtest2.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\vpnconnections.txt" /q >nul
	cls
	echo ###################################
	Echo Please wait, creating connection...
	echo ###################################

:checkphonebook
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -executionpolicy bypass -file checkvpn.ps1 &:: dumps list of vpn connections to a text file
	"%SystemPath%\findstr.exe" "%VPNName%" "C:\IT Folder\Area 51\Programs\VPN\vpnconnections.txt"  &:: reads the text file to see if the VPN connection was already created
	if %errorlevel%==0 (goto dialvpn) else (goto createvpnconnection) &:: if connection already exists, dial it. If it doesn't, create it.

:createvpnconnection
	type enter.txt | "%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -executionpolicy bypass -file config.ps1 -gateway vpn.polk-county.net -name "%VPNName%" -auth p >nul &:: adds new vpn connection, presses enter automatically when prompted

:dialvpn
	cls
	echo ##########################################################################################
	Echo Type your username and password into the appropriate fields. Leave the domain field blank.
	echo If you get errors, just close the little window and this window will guide you through 
	echo the troubleshooting steps.
	echo ##########################################################################################
	"%SystemPath%\rasphone.exe" -d "%VPNName%" &:: Initiates VPN connection

:connectionchecker &:: checks if the vpn connection was successful. If it wasn't, show troubleshooting steps.
	"%SystemPath%\timeout.exe" 5 >nul
	"%SystemPath%\ipconfig.exe" > "C:\IT Folder\Area 51\Programs\VPN\ip.txt" &:: dumps output of ipconfig to ip.txt
	"%SystemPath%\findstr.exe" "%VPNName%" "C:\IT Folder\Area 51\Programs\VPN\ip.txt" >nul &:: checks for "%VPNName%" in ip.txt
	if %errorlevel%==0 (goto connectionsuccess) else (goto troubleshooting) &:: if "%VPNName%" was found, show success message. If not, show troubleshooting steps.

:troubleshooting
	cls
	echo #######################################
	echo Connection failed. Troubleshooting....
	ECHO #######################################
	"%SystemPath%\findstr.exe" "192." "C:\IT Folder\Area 51\Programs\VPN\ip.txt" >nul &:: checks for any kind of connection at all
	if %errorlevel%==0 goto troubleshootingnetworkconnected
	"%SystemPath%\findstr.exe" "10." "C:\IT Folder\Area 51\Programs\VPN\ip.txt" >nul &:: checks for any kind of connection at all
	if %errorlevel%==0 goto troubleshootingnetworkconnected

		:troubleshooting1 &:: display message to indicate there is no network connection at all found.
		echo ########################################################################
		Echo Ensure you are connected to wifi.
		echo Once you have the wifi connected, press any key to retry the connection.
		echo ########################################################################
		"%SystemPath%\timeout.exe" 60>nul
		@pause
		goto start

	:troubleshootingnetworkconnected
	echo Verified basic network connectivity.

	"%SystemPath%\ping.exe" 8.8.8.8 > pingtest2.txt
	"%SystemPath%\findstr.exe" "Reply" "C:\IT Folder\Area 51\Programs\VPN\pingtest2.txt" >nul &:: checks for connection to google's DNS servers, a reliable thing to ping
	if %errorlevel%==0 ( echo Verified internet connection... ) else ( echo Not connected to internet... ) 
	"%SystemPath%\findstr.exe" "100.64" "C:\IT Folder\Area 51\Programs\VPN\ip.txt" > nul&:: checks for zscaler app connection
	if %errorlevel%==0 (goto troubleshootingzscalerconnected) else (goto troubleshooting2)
		:troubleshooting2
		if exist "C:\Program Files (x86)\Zscaler\ZSATray\ZSATray.exe" ( "C:\Program Files (x86)\Zscaler\ZSATray\ZSATray.exe" -shortcut ) else ( goto nozscaler )
		
		echo ##########################################################################################
		Echo Ensure you are signed into ZScaler. Your ZScaler credentials are Username@polk-county.net, 
		echo where "username" is the account you use to sign into the computer. The password is the 
		echo one used to sign into your PC as well. Once you have signed in, press any key to retry 
		echo the connection.
		echo ##########################################################################################
		"%SystemPath%\timeout.exe" 60>nul
		@pause
		goto start

	:troubleshootingzscalerconnected
	echo Verified ZScaler app sign-in...
	"%SystemPath%\findstr.exe" "Name              : B4D42709.CheckPointVPN" "C:\IT Folder\Area 51\Programs\VPN\applist.txt" >nul &:: checks for check point app
	if %errorlevel%==0 (goto troubleshootingappinstalled) else (goto troubleshooting3)
	
	:troubleshooting3
	explorer.exe shell:appsFolder\Microsoft.WindowsStore_8wekyb3d8bbwe!App >nul
	echo ##############################################################################################
	Echo The Check Point VPN app may be out of date or not installed. If the store did not open
	echo directly at the Check Point app landing page, enter "Check Point Capsule" into the search bar.
	Echo Click the blue "install" button to install the app. If it asks you to sign into a Microsoft 
	echo account, just close it and try clicking install again. It should say pending or downloading.
	echo Next, in the upper right corner of the Microsoft Store, there is a "triple dot" menu button.
	echo Click that, then click "Downloads and updates." Next, click "Get updates." When it says 
	echo "You're good to go" close the store, then press any key to retry the connection.
	echo ##############################################################################################
	"%SystemPath%\timeout.exe" 60>nul
	@pause
	goto start


	:troubleshootingappinstalled
	echo Verified Check Point app installation...
	echo #########################################################################
	Echo Everything seems like it's configured properly, but it still didn't work.
	Echo Sometimes these things happen. If you press any key, I'll remove the
	echo VPN connection and the app and try to set it up again.
 	"%SystemPath%\timeout.exe" 60>nul
	@pause
	Echo Removing check point app and %VPNName% phonebook entries.
	Echo These will be recreated shortly as it reattempts the connection. Hang tight.
	echo #############################################################################
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -executionpolicy bypass -file uninstallcheckpointapp.ps1 >nul
	echo Uninstalled check point app...
	"%SystemPath%\timeout.exe" 1 >nul
	type enter.txt | "%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -executionpolicy bypass -file config.ps1 -name "%VPNName%" -remove >nul
	echo Removed %VPNName% connection...
	"%SystemPath%\timeout.exe" 1 >nul
	del /F /Q "C:\Users\%UserName%\AppData\Roaming\Microsoft\Network\Connections\Pbk\rasphone.pbk"
	echo Deleted phone entry...
	echo Rebuilding connection from scratch...
	"%SystemPath%\timeout.exe" 10 >nul
	goto start

:connectionsuccess
	cls
	echo #########################
	echo Connected successfully!
	echo mapping network drives...
	echo #########################
	if exist H:\ goto checksdrive
	for /F "tokens=*" %%A in ( HomeDriveServers.txt ) do ( 
	if exist %%A\%username% net use H: %%A\%username% /persistent:yes
	if exist H:\ echo H:/ Drive mapped && echo ######################### && goto checksdrive )
	:checksdrive 
		if exist S:\ goto eof
		if exist %sdrive% net use S: %sdrive% /persistent:yes
		goto eof

:nozscaler
	echo ##############################################################
	echo ZScaler app not installed. It is unlikely that the Check Point
	echo app will install properly without the zscaler app.
	echo The next step will check the functionality of the Check Point
	echo app, but if you are unable to install it, you may need to call
	echo IT to have the ZScaler app installed on your machine.
	echo ##############################################################
	"%SystemPath%\timeout.exe" 10 >nul
	goto troubleshootingzscalerconnected
	@pause

:eof
	del "C:\IT Folder\Area 51\Programs\VPN\applist.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\ip.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\pingtest.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\pingtest2.txt" /q >nul
	del "C:\IT Folder\Area 51\Programs\VPN\vpnconnections.txt" /q >nul
	popd
