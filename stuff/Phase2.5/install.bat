::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: OfficeUpgrader.bat
:: Detect Office 2016 and cancel if found
:: Detect Office 2010 Pro and uninstall, then reinstall with just msaccess
:: Uninstall Office 2010 Standard
:: Install Office 2016 Standard if not found
::
:: Changelog
::	2/26/2020 - Total rewrite. I wrote this a long time ago and I know 
::		better techniques now than I used to. Much more modular and 
::		easier to understand, I hope.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

set officepro10key=<Your Pro 10 Key Goes Here>
set officestandard16key=<Your Standard 16 Key Goes Here>
set Domain=<your domain here>

Call :CheckDomain
	If %OnDomain%==False goto eof
Call :CheckPCBlacklist
	If %Blacklisted%==True goto eof
Call :CheckOffice
	if %Office16ProInstalled%==True goto eof
	if %Office16StandardInstalled%==True goto eof
	if %Office10ProInstalled%==True Call :UninstallOffice2010
	if %Office10ProInstalled%==True Call :InstallAccess2010
	if %Office10StandardInstalled%==True Call :UninstallOffice
Call :InstallOfficeStandard2016
goto eof

:::::::::::::
::FUNCTIONS::
:::::::::::::

:CheckDomain
:: I don't want to install office on PC's that aren't on our domain... With a few exceptions.
	echo %userdomain% | "%SystemPath%\find.exe" "%Domain%"
	if %errorlevel%==0 set OnDomain=True&&exit /b
	if exist C:\Kace\Engine set OnDomain=True&&exit /b
	wmic computersystem get model | find "VirtualBox"
	if %errorlevel%==0 set OnDomain=True&&exit /b
	set OnDomain=False&&exit /b

:CheckPCBlacklist
::Some PC's should never get office, even if they are on our domain. Edit the list by modifying BlacklistPCs.txt
	for /F "tokens=*" %%A in ( BlacklistPCs.txt ) do ( 
	echo %computername% | "%SystemPath%\find.exe" /i "%%A"
	if errorlevel 0 if not errorlevel 1 ( set Blacklisted=True && exit /b ) else ( set Blacklisted=False )
	)
	exit /b

:CheckOffice
	set OfficeVersionToLookFor="Microsoft Office Professional Plus 2016"
	Call :OfficeFinder
	if %Found%==True ( set Office16ProInstalled=True&&exit /b ) else ( set Office16ProInstalled=False )

	set OfficeVersionToLookFor="Microsoft Office Standard 2016"
	Call :OfficeFinder
	if %Found%==True ( set Office16StandardInstalled=True&&exit /b ) else ( set Office16StandardInstalled=False )

	set OfficeVersionToLookFor="Microsoft Office Professional Plus 2010"
	Call :OfficeFinder
	if %Found%==True ( set Office10ProInstalled=True ) else ( set Office10ProInstalled=False )

	set OfficeVersionToLookFor="Microsoft Office Standard 2010"
	Call :OfficeFinder
	if %Found%==True ( set Office10StandardInstalled=True ) else ( set Office10StandardInstalled=False )

	exit /b

:OfficeFinder
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" %OfficeVersionToLookFor% >nul
	if %errorlevel%==0 set Found=True&&exit /b
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" %OfficeVersionToLookFor% >nul
	if %errorlevel%==0 set Found=True&&exit /b
	set Found=False&&exit /b

:UninstallOffice2010
	"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
	for %%A in (excel,mspub,msaccess,onenote,outlook,powerpnt,winword) do (
		"%SystemPath%\tasklist.exe" /FI "imagename eq %%A.exe"|"%SystemPath%\find.exe" /I "%%A.exe"
		if errorlevel 0 if not errorlevel 1 "%SystemPath%\taskkill.exe" /f /im %%A.exe >nul )

	"%SystemPath%\cscript.exe" //B OffScrub10.vbs /ALL /QUIET	
	start "OFFICE UNINSTALL" /wait "%SystemPath%\msiexec.exe" /X{2F9762E2-CA9B-40ED-8972-87BD111319AB} /qn REBOOT=ReallySuppress
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	Echo office 2010 uninstalled > "C:\it folder\megascript progress report\!today!_!now! uninstalled office 2010.txt"
	"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg
	exit /b	

:InstallAccess2010
	"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
	start /wait "Installing Access 2010" O2K10PRO\setup.exe /Config ProPlus.WW\config.xml /Adminfile Access2010.MSP
	"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg 
	if exist "C:\Program Files (x86)\Microsoft Office\Office14\msaccess.exe" goto activateoffice10prox86
		:activateoffice10prox64
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office14\ospp.vbs" /inpkey:%officepro10key% &:: input office 2010 pro product key
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office14\ospp.vbs" /act
			start "" "C:\Program Files\Microsoft Office\Office14\msaccess.exe"
			exit /b
		:activateoffice10prox86
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs" /inpkey:%officepro10key% &:: input office 2010 pro product key
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs" /act			
			start "" "C:\Program Files (x86)\Microsoft Office\Office14\msaccess.exe"
			exit /b

:InstallOfficeStandard2016
	"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
	start /wait "Installing Office 2016 Standard" O2K16STD\setup.exe /adminfile "silent install.MSP" 
	"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	Echo Installed Office 2016 > "C:\it folder\megascript progress report\!today!_!now! installed office 2016.txt"
	call Office2016shortcuts\office16desktopshortcuts.bat
	if exist "C:\Program Files (x86)\Microsoft Office\Office16\outlook.exe" goto activateoffice16x86
	:activateoffice16x64
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key% &:: input office 2016 standard product key
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
		exit /b
	:activateoffice16x86
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key% &:: input office 2016 standard product key
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act
		exit /b

:eof
	endlocal
	popd
