:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: OfficeUpgrader.bat
:: Detect Office 2016 and cancel if found
:: Detect Office 2010 Pro and uninstall, then reinstall with just msaccess
:: Uninstall Office 2010 Standard
:: Install Office 2016 Standard if not found
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

set officepro10key=<Your Pro 10 Key Goes Here>
set officestandard16key=<Your Standard 16 Key Goes Here>

:checkforofficepro16
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2016" >nul
	if %errorlevel%==0 goto eof
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2016" >nul
	if %errorlevel%==0 ( goto eof ) ELSE ( goto checkforoffice16 ) 

:checkforoffice16
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2016" >nul
	if %errorlevel%==0 goto eof
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2016" >nul
	if %errorlevel%==0 ( goto eof ) ELSE ( goto checkforofficepro10 )

:checkforofficepro10
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2010" >nul
	if %errorlevel%==0 goto uninstallofficepro2010
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Professional Plus 2010" >nul
	if %errorlevel%==0 ( goto uninstallofficepro2010 ) ELSE ( goto checkforofficestandard10 )

:checkforofficestandard10
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2010" >nul
	if %errorlevel%==0 goto uninstalloffice10
	"%SystemPath%\reg.exe" query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | "%SystemPath%\find.exe" "DisplayName" | "%SystemPath%\find.exe" "Microsoft Office Standard 2010" >nul
	if %errorlevel%==0 ( goto uninstalloffice10 ) ELSE ( goto installoffice16 )

:uninstallofficepro2010
	"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
	"%SystemPath%\tasklist.exe" /FI "imagename eq excel.exe"|"%SystemPath%\find.exe" /I "excel.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im excel.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq mspub.exe"|"%SystemPath%\find.exe" /I "mspub.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im mspub.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq msaccess.exe"|"%SystemPath%\find.exe" /I "msaccess.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im msaccess.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq onenote.exe"|"%SystemPath%\find.exe" /I "onenote.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im onenote.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq outlook.exe"|"%SystemPath%\find.exe" /I "outlook.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im outlook.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq powerpnt.exe"|"%SystemPath%\find.exe" /I "powerpnt.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im powerpnt.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq winword.exe"|"%SystemPath%\find.exe" /I "winword.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im winword.exe >nul
	"%SystemPath%\cscript.exe" //B OffScrub10.vbs /ALL /QUIET	
	start "OFFICE UNINSTALL" /wait "%SystemPath%\msiexec.exe" /X{2F9762E2-CA9B-40ED-8972-87BD111319AB} /qn REBOOT=ReallySuppress
	echo office 2010 uninstalled
	O2K10PRO\setup.exe /Config ProPlus.WW\config.xml /Adminfile Access2010.MSP
	"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg

	:setuploop
		"%SystemPath%\tasklist.exe" /FI "imagename eq setup.exe"|"%SystemPath%\find.exe" /I "setup.exe"
		if %errorlevel%==0 goto waitingonsetup
		goto activate10pro

		:waitingonsetup
		"%SystemPath%\timeout.exe" /t 15
		goto setuploop
	:activate10pro
	if exist "C:\Program Files (x86)\Microsoft Office\Office14\msaccess.exe" goto activateoffice10prox86
		:activateoffice10prox64
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office14\ospp.vbs" /inpkey:%officepro10key% &:: input office 2010 pro product key
			"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office14\ospp.vbs" /act
			start "" "C:\Program Files\Microsoft Office\Office14\msaccess.exe"
			goto installoffice16
		:activateoffice10prox86
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs" /inpkey:%officepro10key% &:: input office 2010 pro product key
			"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs" /act			
			start "" "C:\Program Files (x86)\Microsoft Office\Office14\msaccess.exe"
			goto installoffice16

:uninstalloffice10

:checkforfailedattempts
	if exist "C:\IT Folder\megascript progress report\*uninstalled office 2010.txt" ( del "C:\IT Folder\megascript progress report\*uninstalled office 2010.txt" /F /Q && goto abort )
	"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
	"%SystemPath%\tasklist.exe" /FI "imagename eq excel.exe"|"%SystemPath%\find.exe" /I "excel.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im excel.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq mspub.exe"|"%SystemPath%\find.exe" /I "mspub.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im mspub.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq msaccess.exe"|"%SystemPath%\find.exe" /I "msaccess.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im msaccess.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq onenote.exe"|"%SystemPath%\find.exe" /I "onenote.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im onenote.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq outlook.exe"|"%SystemPath%\find.exe" /I "outlook.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im outlook.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq powerpnt.exe"|"%SystemPath%\find.exe" /I "powerpnt.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im powerpnt.exe >nul
	"%SystemPath%\tasklist.exe" /FI "imagename eq winword.exe"|"%SystemPath%\find.exe" /I "winword.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im winword.exe >nul
	"%SystemPath%\cscript.exe" //B OffScrub10.vbs /ALL /QUIET	
	start "OFFICE UNINSTALL" /wait "%SystemPath%\msiexec.exe" /X{2F9762E2-CA9B-40ED-8972-87BD111319AB} /qn REBOOT=ReallySuppress

	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	Echo office 2010 uninstalled > "C:\it folder\megascript progress report\!today!_!now! uninstalled office 2010.txt"
	"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg
	goto checkdomain

:installoffice16
	"C:\windows\regedit.exe" /s Disable_Open-File_Security_Warning.reg
	O2K16STD\setup.exe /adminfile "silent install.MSP" 
	"C:\windows\regedit.exe" /s Enable_Open-File_Security_Warning.reg
	set today=!date:/=-!
	set now=!time::=-!
	set millis=!now:*.=!
	set now=!now:.%millis%=!
	Echo Installed Office 2016 > "C:\it folder\megascript progress report\!today!_!now! installed office 2016.txt"
	call Office2016shortcuts\office16desktopshortcuts.bat
	Echo Created Office desktop shortcuts
	if exist "C:\Program Files (x86)\Microsoft Office\Office16\outlook.exe" goto activateoffice16x86
	:activateoffice16x64
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key% &:: input office 2016 standard product key
		"%SystemPath%\cscript.exe" //B "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
		goto runkbot
	:activateoffice16x86
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /inpkey:%officestandard16key% &:: input office 2016 standard product key
		"%SystemPath%\cscript.exe" //B "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act
		goto runkbot
	:runkbot
	"%SystemPath%\tasklist.exe" /FI "imagename eq msaccess.exe"|"%SystemPath%\find.exe" /I "msaccess.exe"
	if %errorlevel%==0 "%SystemPath%\taskkill.exe" /f /im msaccess.exe >nul
	"%SystemPath%\reg.exe" Query "HKLM\Hardware\Description\System\CentralProcessor\0" | "%SystemPath%\find.exe" /i "x86" > NUL && set OS=32BIT || set OS=64BIT
	if %OS%==32BIT goto runkbot32
	if %OS%==64BIT goto runkbot64
	:runkbot32
		"C:\program files\quest\kace\runkbot" 4 0 >nul
		goto eof

	:runkbot64
		"C:\program files (x86)\quest\kace\runkbot" 4 0 >nul
		goto eof

:abort
	Echo previous failed attempts detected, aborting script

:eof
	endlocal
	popd
