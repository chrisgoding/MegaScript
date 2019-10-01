::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Phase0.bat
:: Sets a 3 hour shutdown in case anything in this script gets hung
:: Removes HP System Default Settings to resolve the 2 minute sleep issue
:: Backs up active power scheme
:: Prevents sleep during script run
:: Unloads antivirus to prevent issues with installations
:: Upgrades the IT Folder to the latest copy
:: Determines if your pc is a laptop or desktop. Creates S:\ Shortcut, installs computrace, and installs check point client if it's a laptop
:: Installs kace agent if it's missing
:: Inventories computer and launches any kace managed installs
:: Runs ccleaner with safe presets, then waits for ccleaner to finish
:: If windows 10, inputs windows 10 product key & activates windows 10
:: if office 2016 pro is installed, activate it.
:: if office 2016 standard is installed input office 2016 standard product key and activate it
:: Opens word in case you just upgraded from windows 7 to 10, to prevent the user from having to wait on the "configuring" screen
:: Removes stuck print jobs
:: Checks if WMI is broken and launches automated repair if it is
:: Runs the TLS upgrade on windows 7 clients
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion &:: Things to make batch files work right
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

@echo off
set trendunloadpassword=<TrendUnloadPasswordGoesHere>
set trendinstallpath=\\<YourOfficeScanServerGoesHere>\ofcscan\AutoPccP.exe
set windows10key=<win10 product key goes here>
set officepro16key=<office16 pro product key goes here>
set officestandard16key=<office16 standard product key goes here>
set domain=<a domain to search for to ensure that certain steps only run on domain PC's>
set SMAHOST=<if you use kace sma, the hostname goes here to automate the installation of the kace agent>
@echo on



if not exist "C:\Temp\Stuff" mkdir "C:\Temp\Stuff"
ForFiles /p "C:\IT Folder\Megascript Progress Report" /s /d -180 /c "cmd /c del @file" &:: removes log files older than 180 days, so that the log directory does not become infinite.

@echo on
call :OnDomain
call :ExcludePublicSafety
call :Bitnesscheck
call :SetLaptoporDesktop
call :WindowsVersion
call :PowerScheme
call :DisableTrend
call :FixBootSettings
call :AddITFiles
call :LaptopStuff
call :BIOSConfig
call :fixdirectory
call :RemoveOldKaceAgent
call :KaceAgentInstallAndInventory
call :CCleaner
call :Activate10
call :OfficeActivator
call :PrinterFixer
call :WMIFixer
call :SystemRestore
call :TLScheck
goto eof

:::::::::::::
::FUNCTIONS::
:::::::::::::
:OnDomain &:: checks if the PC is on the domain
	echo %userdomain% | "%SystemPath%\find.exe" "%domain%"
	if %errorlevel%==0 ( set OnDomain=True ) else (set OnDomain=False)
	exit /b

:WindowsVersion &:: from https://stackoverflow.com/a/13212116
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	exit /b

:Bitnesscheck
	"%SystemPath%\Reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT
	exit /b

:SetLaptoporDesktop
	wmic path Win32_Battery get BatteryStatus | "%SystemPath%\find.exe" "BatteryStatus"
	if %errorlevel%==0 ( set Laptop=True ) else ( set Laptop=False )
	exit /b

:ExcludePublicSafety &:: we don't want to run certain steps on certain PC's, so we set a flag here based on the PC name.
	echo %computername% | "%SystemPath%\find.exe" /i "BENCH"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "BLS"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "BRICE"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "EOC"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "EM"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "FIRE"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "FR"
	if %errorlevel%==0 ( set PublicSafety==True && exit /b ) else ( set PublicSafety==False )
	echo %computername% | "%SystemPath%\find.exe" /i "GAS"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "RS"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "SU"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	echo %computername% | "%SystemPath%\find.exe" /i "TOUGH"
	if %errorlevel%==0 ( set PublicSafety=True && exit /b ) else ( set PublicSafety=False )
	exit /b

:PowerScheme &:: changes the power scheme to prevent the pc from falling asleep mid-script. In phase 7, we return the settings to what they were at the beginning.
	"%SystemPath%\powercfg.exe" -list | "%SystemPath%\find.exe" "HP Optimized"
	if %errorlevel%==0 goto uninstallhpoptimized
	goto exportpowerschemes

	:uninstallhpoptimized &:: If an "HP Optimized" power scheme exists, the PC will fall asleep agressively, so we uninstall the related program and return power settings to the defaults.
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {2AC26350-98EE-4D4C-9F56-54D58C371E13} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {3A61A282-4F08-4D43-920C-DC30ECE528E8} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {5F7AAD31-A357-4EC6-B636-41335FE501A0} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {9FA4819F-C0D6-4184-950A-5F3859EB1168} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {A257CDB0-8A07-4481-AD21-F4337C3D10AF} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {A66E1AC5-F4A9-4DB0-ACB0-90419A8F98D5} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {B5BEF5F8-BD76-4174-A47D-05A06EA62615} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {BCF8F914-F91D-4DC5-A9E3-655B444CBFFD} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {C4E9E8A4-EEC4-4F9E-B140-520A8B75F430} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {D90398D2-124A-44C8-9249-5E5E19911337} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {E570B9C2-9A83-4938-BBD5-0A8C068083C1} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {F4F3B985-9B21-4D67-B1B2-2829C5D392E8} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		START "" /WAIT "%SystemPath%\msiexec.exe" /X {FF94262A-A307-4D6A-AD8A-9D814A93E344} /qn REBOOT=ReallySuppress &:: HP System Default Settings
		"%SystemPath%\powercfg.exe" -restoredefaultschemes

	:exportpowerschemes
		if exist "C:\IT Folder\originalpowersettings.pow" goto settemporarypowerscheme &:: if a script was paused mid-run or did not finish, then the power schemes were already exported and we don't want to write over them.
		if exist "C:\IT Folder\originalpowersettings.txt" goto settemporarypowerscheme
		for /F "tokens=2 delims=:(" %%i in ('%SystemPath%\powercfg.exe -getactivescheme') do set GUID1=%%i &:: capture the GUID of the active scheme and make it a variable named GUID1
		for /F "tokens=2 delims=:(" %%i in ('%SystemPath%\powercfg.exe -getactivescheme') do echo %%i > "C:\IT Folder\originalpowersettings.txt" &:: also capture the GUID into a text file so we can use it later.
		"%SystemPath%\powercfg.exe" /export "C:\IT Folder\originalpowersettings.pow"%GUID1% &:: Use the variable to export the currently active power scheme into a .pow file for later import.

	:settemporarypowerscheme
		"%SystemPath%\powercfg.exe" /change monitor-timeout-ac 0
		"%SystemPath%\powercfg.exe" /change disk-timeout-ac 0
		"%SystemPath%\powercfg.exe" /change standby-timeout-ac 0
		"%SystemPath%\powercfg.exe" /change hibernate-timeout-ac 0

	:disablenetworkadaptersleep
		PowerShell.exe -ExecutionPolicy Bypass -File DisableNetworkAdapterPowerSave.ps1
	"%SystemPath%\shutdown.exe" -r -t 10800 -f && Echo 3 Hour Shutdown Scheduled
	exit /b

:DisableTrend
	:symanteccheck &:: verifies that symantec is not installed; we don't want to do anything related to trend on a symantec machine
		if %OS%==32BIT goto checkforsymantec32
		if %OS%==64BIT goto checkforsymantec64
			:checkforsymantec32
				IF exist "C:\Program Files\Symantec\Symantec Endpoint Protection" ( exit /b ) ELSE ( goto checkforinstalledtrend )

			:checkforsymantec64
				IF exist "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection" ( exit /b ) ELSE ( goto checkforinstalledtrend )

	:checkforinstalledtrend
		"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend" >NUL
		if %errorlevel%==0 goto checkforrunningtrend
		"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Trend" >NUL
		if %errorlevel%==0 goto checkforrunningtrend

	:installtrend
		if not exist %trendinstallpath% exit /b
		%trendinstallpath%
		:installloop
			timeout 600 >nul
			"%SystemPath%\tasklist.exe" /FI "imagename eq install.exe"|"%SystemPath%\find.exe" /I "install.exe"
			if %errorlevel% == 0 goto installloop
			"%SystemPath%\tasklist.exe" /FI "imagename eq pccnt.exe"|"%SystemPath%\find.exe" /I "pccnt.exe"
			if %errorlevel% == 0 shutdown /r /f /t 0
			goto DisableTrend

	:checkforrunningtrend &:: if trend is already stopped, dont bother trying to disable trend
		"%SystemPath%\tasklist.exe" /FI "imagename eq TMBMSRV.exe"|"%SystemPath%\find.exe" /I "TMBMSRV.exe"
		if %errorlevel% NEQ 0 exit /b
	:unloadtrend
		if %OS%==32BIT goto disabletrend32
		if %OS%==64BIT goto disabletrend64
			:disabletrend32 &:: calls the command to unload trend. automatically presses enter when prompted
				type enter.txt | "C:\Program Files\Trend Micro\OfficeScan Client\PccNTMon.exe" -n %trendunloadpassword%
				goto waitfor15

			:disabletrend64
				type enter.txt | "C:\Program Files (x86)\Trend Micro\OfficeScan Client\PccNTMon.exe" -n %trendunloadpassword%
				goto waitfor15
		:waitfor15
			timeout 15 >nul
			goto checkforrunningtrend
	exit /b

:FixBootSettings
	"%SystemPath%\bcdedit.exe" | "%SystemPath%\find.exe" /i "allowedinmemorysettings"
	if %errorlevel%==0 "%SystemPath%\bcdedit.exe" /deletevalue allowedinmemorysettings
	"%SystemPath%\bcdedit.exe" | "%SystemPath%\find.exe" /i "truncatememory"
	if %errorlevel%==0 "%SystemPath%\bcdedit.exe" /deletevalue truncatememory
	exit /b

:AddITFiles
	if %PublicSafety%==True exit /b
	"%SystemPath%\Robocopy.exe" "IT Folder" "C:\IT Folder\Area 51" /MIR /XD "IT Folder\MegaScript Progress Report\" &:: Upgrades the IT Folder to the latest copy
	xcopy AddRemoteApps.bat "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" /Y
	xcopy "IT Tickets.url" C:\Users\Public\Desktop /y
	if exist "C:\users\administrator" copy "C:\IT Folder\Area 51\1. rename pc and join domain.bat" "C:\users\administrator\Desktop\1. rename pc and join domain.bat" /Y
	if exist "C:\users\administrator" copy "C:\IT Folder\Area 51\2. Move PC into the correct OU.txt" "C:\users\administrator\Desktop\2. Move PC into the correct OU.txt" /Y
	if exist "C:\users\administrator" copy "C:\IT Folder\Area 51\3.bat" "C:\users\administrator\Desktop\3.bat" /Y
	if exist "C:\users\dtsit" copy "C:\IT Folder\Area 51\1. rename pc and join domain.bat" "C:\users\dtsit\Desktop\1. rename pc and join domain.bat" /Y
	if exist "C:\users\dtsit" copy "C:\IT Folder\Area 51\2. Move PC into the correct OU.txt" "C:\users\dtsit\Desktop\2. Move PC into the correct OU.txt" /Y
	if exist "C:\users\dtsit" copy "C:\IT Folder\Area 51\3.bat" "C:\users\dtsit\Desktop\3.bat" /Y
	exit /b

:DesktopInfo
	if %PublicSafety%==True exit /b
	:RemoveOldVersions &:: removes the old desktop info script
		if exist "C:\IT\Automation\DesktopInfoTray.exe" del /F /Q "C:\IT\Automation\DesktopInfoTray.exe"
		if exist "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCInfo.lnk" del /F /Q "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCInfo.lnk"
		if exist "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCinfoToggle.lnk" del /F /Q "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCinfoToggle.lnk"
		if exist "C:\PCinfo\" del /F /Q "C:\PCinfo\*.*"
		if exist "C:\PCinfo\" rd "C:\PCInfo"
	:installnewdtinfo
		if exist "IT Folder\BGInfo\DesktopInfo.lnk" "%SystemPath%\xcopy.exe" /y "IT Folder\BGInfo\DesktopInfo.lnk" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\" >nul
	exit /b

:LaptopStuff
	if %Laptop%==False exit /b
	if %PublicSafety%==True exit /b
	"%SystemPath%\xcopy.exe" "Polk County Data (S).lnk" "C:\users\public\desktop" /Y &:: creates shortcut to S:\ drive on the desktop; useful for vpn users

	:computracecheck32 &:: checks if computrace is installed, calls upon computrace.ps1 if it is not
		if exist "C:\windows\system32\rpcnet.exe" ( goto checkpoint ) else ( goto computracecheck64 )

	:computracecheck64
		if exist "c:\windows\syswow64\rpcnet.exe" ( goto checkpoint ) else ( goto installcomputrace )

	:installcomputrace
		"%SystemPath%\xcopy.exe" computrace.msi "C:\Temp\Stuff"
		copy computrace.ps1 C:\Temp\Stuff\computrace.ps1 /y && "%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -ExecutionPolicy Bypass -File C:\Temp\Stuff\computrace.ps1 && del /f C:\Temp\Stuff\computrace.ps1
		Echo Computrace Installed

	:checkpoint
		if "%version%" == "10.0" goto checkpointinstall
		if "%version%" == "6.3" exit /b
		if "%version%" == "6.2" exit /b
		if "%version%" == "6.1" exit /b
		if "%version%" == "6.0" exit /b
		:checkpointinstall &:: on windows 10 laptops create desktop shortcut to the vpn connection
			"%SystemPath%\xcopy.exe" "Connect to VPN.lnk" "C:\users\public\desktop" /Y
			exit /b
:BIOSConfig
	BCU\BCU.bat &:: runs the BIOS config utility to appropriately set the wake on lan and lan / wlan switching settings

:FixDirectory &:: for some reason the BCU function does silly things to the working directory
	:popd
	echo %cd% | "%SystemPath%\find.exe" "BCU"
	if %errorlevel%==0 popd && goto popd
	echo %cd% | "%SystemPath%\find.exe" /i "Phase0"
	if %errorlevel%==1 pushd "%~dp0"
	exit /b

:RemoveOldKaceAgent
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {04951A4E-C818-43A7-83A1-A9A74B430A27} /qn REBOOT=ReallySuppress
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {434FADEB-EB52-4BCD-BA92-81B9C70DD8D8} /qn REBOOT=ReallySuppress
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {4D51BA3B-C670-4DBC-9F9C-4B36DC9B8E9D} /qn REBOOT=ReallySuppress
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {BFEBBA3A-3473-447F-B516-289066AED819} /qn REBOOT=ReallySuppress
	START "" /WAIT "%SystemPath%\msiexec.exe" /X {F66E9801-5F03-4ECD-A5BC-8678FAE8FBAA} /qn REBOOT=ReallySuppress
	exit /b

:KaceAgentInstallAndInventory
	if %OnDomain%==False exit /b
	if exist "C:\program files\quest\kace\runkbot.exe" ( goto runkbot32 ) 
	if exist "C:\program files (x86)\quest\kace\runkbot.exe" ( goto runkbot64 ) ELSE ( start /wait "" "%SystemPath%\msiexec.exe" /i "C:\IT Folder\Area 51\programs\ampagent-9.0.167-x86.msi" HOST=%SMAHOST% /qn /norestart ) &:: installs kace agent if it's missing
	if %OS%==32BIT goto runkbot32
	if %OS%==64BIT goto runkbot64
	:runkbot32
		"C:\program files\quest\kace\runkbot" 4 0 > nul
		"C:\program files\quest\kace\runkbot" 6 0 > nul
		exit /b

	:runkbot64
		"C:\program files (x86)\quest\kace\runkbot" 4 0 > nul
		"C:\program files (x86)\quest\kace\runkbot" 6 0 > nul
		exit /b

:CCleaner
	start "CCLEANER" runccleaner.bat &:: runs ccleaner with safe presets, then waits 60 seconds and closes ccleaner
	"%SystemPath%\timeout.exe" 60 >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq ccleaner.exe"|"%SystemPath%\find.exe" /I "ccleaner.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im ccleaner.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq ccleaner64.exe"|"%SystemPath%\find.exe" /I "ccleaner64.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im ccleaner64.exe >nul
	exit /b

:Activate10
	if "%version%" NEQ "10.0" exit /b
	"%SystemPath%\cscript.exe" /Nologo C:\windows\System32\slmgr.vbs /xpr |"%SystemPath%\find.exe" "The machine is permanently activated."
	if %errorlevel%==0 exit /b
	"%SystemPath%\cscript.exe" //B C:\windows\System32\slmgr.vbs -ipk %windows10key% &:: inputs windows 10 product key
	"%SystemPath%\cscript.exe" //B C:\windows\System32\slmgr.vbs /ato &:: activates windows 10
	timeout 5 >nul
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	"%SystemPath%\cscript.exe" /Nologo C:\windows\System32\slmgr.vbs /xpr |"%SystemPath%\find.exe" "The machine is permanently activated."
	if %errorlevel% NEQ 0 "%SystemPath%\cscript.exe" /Nologo C:\windows\System32\slmgr.vbs /xpr > "C:\it folder\megascript progress report\!today!_!now! Windows activation failed.txt"
	exit /b

:OfficeActivator
	:checkforofficepro16
		"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2016" >nul
		if %errorlevel%==0 goto activateofficepro16
		"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2016" >nul
		if %errorlevel%==0 ( goto activateofficepro16 ) ELSE ( goto checkforoffice16 )

	:activateofficepro16
		if exist "C:\Program Files (x86)\Microsoft Office\Office16\msaccess.exe" goto activateofficepro16x86
		:activateofficepro16x64
			"%SystemPath%\cscript.exe" "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
			if %errorlevel%==0 exit /b
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /inpkey:%officepro16key%
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
			exit /b
		:activateofficepro16x86
			"%SystemPath%\cscript.exe" "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
			if %errorlevel%==0 exit /b
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /inpkey:%officepro16key%
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act
			exit /b

	:checkforoffice16
		"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2016" >nul
		if %errorlevel%==0 goto activateoffice16
		"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2016" >nul
		if %errorlevel%==0 ( goto activateoffice16 ) ELSE ( exit /b )

	:activateoffice16
		if exist "C:\Program Files (x86)\Microsoft Office\Office16\outlook.exe" goto activateoffice16x86
		:activateoffice16x64
			"%SystemPath%\cscript.exe" "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
			if %errorlevel%==0 exit /b
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key%
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
			exit /b
		:activateoffice16x86
			"%SystemPath%\cscript.exe" "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
			if %errorlevel%==0 exit /b
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key%
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act
			exit /b

:PrinterFixer &:: removes stuck print jobs
	"%SystemPath%\net.exe" stop spooler /y
	"%SystemPath%\takeown.exe" /f C:\Windows\System32\spool\PRINTERS\*.*
	"%SystemPath%\icacls.exe" C:\Windows\System32\spool\PRINTERS\*.* /Grant Administrators:(F)
	"%SystemPath%\timeout.exe" 1
	del /q C:\Windows\System32\spool\PRINTERS\*.*
	"%SystemPath%\net.exe" start spooler
	exit /b
	
:WMIFixer &:: Shamelessly stolen from TronScript and adapted to work here. Quickly checks if WMI is broken, and if it is, does its best to fix it.
SETLOCAL ENABLEDELAYEDEXPANSION
	<NUL wmic timezone >NUL
	if /i not !ERRORLEVEL!==0 (
		echo WMI appears to be broken. Calling WMI repair sub-script.
		echo This will take time, please be patient...
		call repair_wmi.bat
)
exit /b

:SystemRestore
	wmic /namespace:\\root\default Path SystemRestore Call enable “C:\”
	Wmic /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "%DATE%", 100, 1
	"%SystemPath%\vssadmin.exe" Resize ShadowStorage /For=C: /On=C: /MaxSize=5%%
	exit /b

:TLScheck
	if "%version%" NEQ "6.1" exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | "%SystemPath%\find.exe" "DefaultSecureProtocols" | "%SystemPath%\find.exe" "a00"
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | "%SystemPath%\find.exe" "DefaultSecureProtocols" | "%SystemPath%\find.exe" "a00"
	if %errorlevel%==0 exit /b
	START "" /WAIT "%SystemPath%\msiexec.exe" /i "MicrosoftEasyFix51044.msi" /quiet
	"%SystemPath%\timeout.exe" 5>nul
	goto TLScheck &:: return to regcheck to verify settings applied

:eof
	IF exist "C:\IT Folder\windowsupgrade.txt" ( start "" "C:\Program Files (x86)\Microsoft Office\Office16\winword.exe" ) &:: opens word in case you just upgraded from windows 7 to 10
	if exist "C:\IT Folder\windowsupgrade.txt" del /F /Q "C:\IT Folder\windowsupgrade.txt"
	popd
