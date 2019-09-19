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
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

set windows10key=<win10 product key goes here>
set officepro16key=<office16 pro product key goes here>
set officestandard16key=<office16 standard product key goes here>
set domain=<a domain to search for to ensure that certain steps only run on domain PC's>
set SMAHOST=<if you use kace sma, the hostname goes here to automate the installation of the kace agent>

if not exist "C:\Temp\Stuff" mkdir "C:\Temp\Stuff"

ForFiles /p "C:\IT Folder\Megascript Progress Report" /s /d -180 /c "cmd /c del @file" &:: removes log files older than 180 days, so that the log directory does not become infinite.

@echo on

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

call disabletrend.bat &:: unloads antivirus to prevent issues with installations. Also makes this whole thing run faster.
Echo Trend Unloaded

:excludepublicsafety &:: There are some PC's that we don't want to do some steps to.
	echo %computername% | "%SystemPath%\find.exe" /i "BENCH"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "BLS"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "BRICE"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "EOC"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "EM"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "FIRE"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "FR"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "GAS"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "RS"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "SU"
	if %errorlevel%==0 goto skipboccstuff
	echo %computername% | "%SystemPath%\find.exe" /i "TOUGH"
	if %errorlevel%==0 goto skipboccstuff

"%SystemPath%\Robocopy.exe" "IT Folder" "C:\IT Folder\Area 51" /MIR /XD "IT Folder\MegaScript Progress Report\" &:: Upgrades the IT Folder to the latest copy
xcopy AddRemoteApps.bat "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" /Y
xcopy "IT Tickets.url" C:\Users\Public\Desktop /y

Echo IT Folder Upgraded to Latest Copy

if exist "C:\users\administrator" copy "C:\IT Folder\Area 51\1. rename pc and join domain.bat" "C:\users\administrator\Desktop\1. rename pc and join domain.bat" /Y
if exist "C:\users\administrator" copy "C:\IT Folder\Area 51\2. Move PC into the correct OU.txt" "C:\users\administrator\Desktop\2. Move PC into the correct OU.txt" /Y
if exist "C:\users\administrator" copy "C:\IT Folder\Area 51\3.bat" "C:\users\administrator\Desktop\3.bat" /Y

if exist "C:\users\dtsit" copy "C:\IT Folder\Area 51\1. rename pc and join domain.bat" "C:\users\dtsit\Desktop\1. rename pc and join domain.bat" /Y
if exist "C:\users\dtsit" copy "C:\IT Folder\Area 51\2. Move PC into the correct OU.txt" "C:\users\dtsit\Desktop\2. Move PC into the correct OU.txt" /Y
if exist "C:\users\dtsit" copy "C:\IT Folder\Area 51\3.bat" "C:\users\dtsit\Desktop\3.bat" /Y

popd
pushd "%~dp0"

:desktopinfo
	:RemoveOldVersions &:: removes the old desktop info script
		if exist "C:\IT\Automation\DesktopInfoTray.exe" del /F /Q "C:\IT\Automation\DesktopInfoTray.exe"
		if exist "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCInfo.lnk" del /F /Q "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCInfo.lnk"
		if exist "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCinfoToggle.lnk" del /F /Q "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PCinfoToggle.lnk"
		if exist "C:\PCinfo\" del /F /Q "C:\PCinfo\*.*"
		if exist "C:\PCinfo\" rd "C:\PCInfo"
	:installnewdtinfo
		if exist "IT Folder\BGInfo\DesktopInfo.lnk" "%SystemPath%\xcopy.exe" /y "IT Folder\BGInfo\DesktopInfo.lnk" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\" >nul

copy laptopordesktop.ps1 C:\Temp\Stuff\laptopordesktop.ps1 /y
"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -ExecutionPolicy Bypass -File C:\Temp\Stuff\laptopordesktop.ps1
del /f C:\Temp\Stuff\laptopordesktop.ps1

:skipboccstuff

popd
pushd "%~dp0"

call BCU\BCU.bat &:: runs the BIOS config utility to appropriately set the wake on lan and lan / wlan switching settings
Echo BIOS Settings Corrected

popd
pushd "%~dp0"

:removeoldkaceagent
START "" /WAIT "%SystemPath%\msiexec.exe" /X {04951A4E-C818-43A7-83A1-A9A74B430A27} /qn REBOOT=ReallySuppress
START "" /WAIT "%SystemPath%\msiexec.exe" /X {434FADEB-EB52-4BCD-BA92-81B9C70DD8D8} /qn REBOOT=ReallySuppress
START "" /WAIT "%SystemPath%\msiexec.exe" /X {4D51BA3B-C670-4DBC-9F9C-4B36DC9B8E9D} /qn REBOOT=ReallySuppress
START "" /WAIT "%SystemPath%\msiexec.exe" /X {BFEBBA3A-3473-447F-B516-289066AED819} /qn REBOOT=ReallySuppress
START "" /WAIT "%SystemPath%\msiexec.exe" /X {F66E9801-5F03-4ECD-A5BC-8678FAE8FBAA} /qn REBOOT=ReallySuppress


echo %userdomain% | "%SystemPath%\find.exe" "%domain%" &:: this verifies that the pc is already on the domain, and if it isn't, skip the kbot steps, otherwise the inventory can cause records of a reimaged computer to be erased.
if %errorlevel%==1 ( goto ccleaner )


if exist "C:\program files\quest\kace\runkbot.exe" ( goto runkbot32 ) 
if exist "C:\program files (x86)\quest\kace\runkbot.exe" ( goto runkbot64 ) ELSE ( start /wait "" "%SystemPath%\msiexec.exe" /i "C:\IT Folder\Area 51\programs\ampagent-9.0.167-x86.msi" HOST=%SMAHOST% /qn /norestart ) &:: installs kace agent if it's missing


:runkbot &:: inventories computer and launches any kace managed installs
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT

	if %OS%==32BIT goto runkbot32
	if %OS%==64BIT goto runkbot64

	:runkbot32
		"C:\program files\quest\kace\runkbot" 4 0 > nul
		Echo Ran Kace Inventory
		"C:\program files\quest\kace\runkbot" 6 0 > nul
		Echo Kace Managed Installs
		goto ccleaner

	:runkbot64
		"C:\program files (x86)\quest\kace\runkbot" 4 0 > nul
		Echo Ran Kace Inventory
		"C:\program files (x86)\quest\kace\runkbot" 6 0 > nul
		Echo Kace Managed Installs
		goto ccleaner

:ccleaner
	start "CCLEANER" runccleaner.bat &:: runs ccleaner with safe presets, then waits for ccleaner to finish
	Echo Running CCleaner
	"%SystemPath%\timeout.exe" 60 >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq ccleaner.exe"|"%SystemPath%\find.exe" /I "ccleaner.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im ccleaner.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq ccleaner64.exe"|"%SystemPath%\find.exe" /I "ccleaner64.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im ccleaner64.exe >nul

:checkdomain
	wmic computersystem get model | find "VirtualBox"
	if %errorlevel%==0 ( goto windowsversion )
	echo %userdomain% | "%SystemPath%\find.exe" "%domain%"
	if %errorlevel%==1 ( goto PrinterFixer )

:windowsversion &:: verifies which version of windows the script is run on. from https://stackoverflow.com/a/13212116 
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	if "%version%" == "10.0" goto activate10
	if "%version%" == "6.3" goto checkforofficepro16
	if "%version%" == "6.2" goto checkforofficepro16
	if "%version%" == "6.1" goto checkforofficepro16
	if "%version%" == "6.0" goto checkforofficepro16

:activate10
	"%SystemPath%\cscript.exe" /Nologo C:\windows\System32\slmgr.vbs /xpr |"%SystemPath%\find.exe" "The machine is permanently activated."
	if %errorlevel%==0 goto checkforofficepro16
	"%SystemPath%\cscript.exe" //B C:\windows\System32\slmgr.vbs -ipk %windows10key% &:: inputs windows 10 product key
	"%SystemPath%\cscript.exe" //B C:\windows\System32\slmgr.vbs /ato &:: activates windows 10
	timeout 5 >nul
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	"%SystemPath%\cscript.exe" /Nologo C:\windows\System32\slmgr.vbs /xpr |"%SystemPath%\find.exe" "The machine is permanently activated."
	if %errorlevel% NEQ 0 "%SystemPath%\cscript.exe" /Nologo C:\windows\System32\slmgr.vbs /xpr > "C:\it folder\megascript progress report\!today!_!now! Windows activation failed.txt"

:checkforofficepro16
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2016" >nul
	if %errorlevel%==0 goto activateofficepro16
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2016" >nul
	if %errorlevel%==0 ( goto activateofficepro16 ) ELSE ( goto checkforoffice16 )

:activateofficepro16
	if exist "C:\Program Files (x86)\Microsoft Office\Office16\msaccess.exe" goto activateofficepro16x86
	:activateofficepro16x64
		"%SystemPath%\cscript.exe" "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
		if %errorlevel%==0 goto PrinterFixer
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /inpkey:%officepro16key%
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
		goto printerfixer
	:activateofficepro16x86
		"%SystemPath%\cscript.exe" "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
		if %errorlevel%==0 goto PrinterFixer
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /inpkey:%officepro16key%
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act
		goto printerfixer

:checkforoffice16
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2016" >nul
	if %errorlevel%==0 goto activateoffice16
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2016" >nul
	if %errorlevel%==0 ( goto activateoffice16 ) ELSE ( goto printerfixer )

:activateoffice16
	if exist "C:\Program Files (x86)\Microsoft Office\Office16\outlook.exe" goto activateoffice16x86
	:activateoffice16x64
		"%SystemPath%\cscript.exe" "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
		if %errorlevel%==0 goto PrinterFixer
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key%
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
		goto printerfixer
	:activateoffice16x86
		"%SystemPath%\cscript.exe" "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /dstatus |"%SystemPath%\find.exe" "LICENSE STATUS:  ---LICENSED---"
		if %errorlevel%==0 goto PrinterFixer
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key%
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act
		goto printerfixer

:PrinterFixer &:: removes stuck print jobs
	"%SystemPath%\net.exe" stop spooler /y
	"%SystemPath%\takeown.exe" /f C:\Windows\System32\spool\PRINTERS\*.*
	"%SystemPath%\icacls.exe" C:\Windows\System32\spool\PRINTERS\*.* /Grant Administrators:(F)
	"%SystemPath%\timeout.exe" 1
	del /q C:\Windows\System32\spool\PRINTERS\*.*
	"%SystemPath%\net.exe" start spooler

:WMIfixer &:: Shamelessly stolen from TronScript and adapted to work here. Quickly checks if WMI is broken, and if it is, does its best to fix it.
SETLOCAL ENABLEDELAYEDEXPANSION
	<NUL wmic timezone >NUL
	if /i not !ERRORLEVEL!==0 (
		echo WMI appears to be broken. Calling WMI repair sub-script.
		echo This will take time, please be patient...
		call repair_wmi.bat
)

:systemrestore
	wmic /namespace:\\root\default Path SystemRestore Call enable “C:\” &:: enable system restore
	Wmic /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "%DATE%", 100, 1
	"%SystemPath%\vssadmin.exe" Resize ShadowStorage /For=C: /On=C: /MaxSize=5%%

:windowsversioncheck &:: makes sure that this script only runs on windows 7
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
		if "%version%" == "10.0" goto eof
		if "%version%" == "6.3" goto eof
		if "%version%" == "6.2" goto eof
		if "%version%" == "6.1" goto TLScheck
		if "%version%" == "6.0" goto eof

:TLScheck &:: looking for the registry values, if matched either, go to end of script
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | "%SystemPath%\find.exe" "DefaultSecureProtocols" | "%SystemPath%\find.exe" "a00"
		if %errorlevel%==0 goto eof
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | "%SystemPath%\find.exe" "DefaultSecureProtocols" | "%SystemPath%\find.exe" "a00"
		if %errorlevel%==0 goto eof

:installTLS &:: runs microsoft easy fix
	START "" /WAIT "%SystemPath%\msiexec.exe" /i "MicrosoftEasyFix51044.msi" /quiet
	"%SystemPath%\timeout.exe" 5>nul
	goto TLScheck &:: return to regcheck to verify settings applied

:eof
	IF exist "C:\IT Folder\windowsupgrade.txt" ( start "" "C:\Program Files (x86)\Microsoft Office\Office16\winword.exe" ) &:: opens word in case you just upgraded from windows 7 to 10
	if exist "C:\IT Folder\windowsupgrade.txt" del /F /Q "C:\IT Folder\windowsupgrade.txt"
	popd
