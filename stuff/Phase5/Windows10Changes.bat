::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Changes.bat
:: makes sure that windows 10 changes are only applied to windows 10
:: Turns on a service to make the microsoft store work
:: changes desktop background to polk county logo
:: adds devices and printers link to start menu
:: sets default file associations
:: runs win10decrapifier https://community.spiceworks.com/scripts/show/4378-windows-10-decrapifier-1803-1809
:: enables .net 3.5
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
@echo on

IF not exist "C:\Temp\Stuff" mkdir "C:\Temp\Stuff"
IF not exist "C:\it folder\megascript progress report" mkdir "C:\it folder\megascript progress report"

set quick=true
Call :WindowsVersionCheck
	if "%version%" NEQ "10.0" goto eof
Call :EnableUAC
Call :RemoveFlashActiveX
Call :DOTNET35
Call :Win7PhotoViewer
Call :Services
Call :DesktopBackground
Call :DevicesandPrintersShortcut
Call :DefaultFileAssociations
if "%~1" == "" Call :Decrapifier
if %quick%==false goto eof

if %1==/quick ( Call :QuickDecrapifier ) else ( Call :Decrapifier)
goto eof

:::::::::::::
::FUNCTIONS::
:::::::::::::

:WindowsVersionCheck
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	exit /b

:EnableUAC
	"%SystemPath%\reg.exe" ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f
	exit /b

:RemoveFlashActiveX
	for /F "tokens=*" %%F in ( FlashPlayerActiveXRegEntries.txt ) do ( "%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" | "%SystemPath%\find.exe" "{%%F}"
			if errorlevel 0 if not errorlevel 1 ( echo Y | "%SystemPath%\reg.exe" delete "HKLM\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\{%%F} 
		))
	exit /b

:DOTNET35
	"%SystemPath%\dism.exe" /online /get-features /format:table | "%SystemPath%\find.exe" "NetFx3                                       | Enabled"
	if %errorlevel%==0 exit /b
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1909"
	if %errorlevel%==0 goto dism1909
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1903"
	if %errorlevel%==0 goto dism1903
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1809"
	if %errorlevel%==0 goto dism1809
	"%SystemPath%\reg.exe" Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId | "%SystemPath%\find.exe" "1803"
	if %errorlevel%==0 goto dism1803
	exit /b
		:dism1909
			"%SystemPath%\dism.exe" /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Source:1909sxs /LimitAccess &:: enables .net 3.5
			exit /b

		:dism1903
			"%SystemPath%\dism.exe" /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Source:1903sxs /LimitAccess &:: enables .net 3.5
			exit /b

		:dism1809
			"%SystemPath%\dism.exe" /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Source:1809sxs /LimitAccess &:: enables .net 3.5
			exit /b

		:dism1803
			"%SystemPath%\dism.exe" /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Source:1803sxs /LimitAccess &:: enables .net 3.5
			exit /b

:Win7PhotoViewer
	"C:\windows\regedit.exe" /s photoviewer.reg
	exit /b

:Services
	"%SystemPath%\sc.exe" config wlidsvc start= demand   &:: Turns on a service to make the microsoft store work
	exit /b

:DesktopBackground
	"%SystemPath%\takeown.exe" /f c:\windows\WEB\wallpaper\Windows\img0.jpg
	"%SystemPath%\takeown.exe" /f C:\Windows\Web\4K\Wallpaper\Windows\*.*
	"%SystemPath%\icacls.exe" c:\windows\WEB\wallpaper\Windows\img0.jpg /Grant System:(F)
	"%SystemPath%\icacls.exe" C:\Windows\Web\4K\Wallpaper\Windows\*.* /Grant System:(F)
	"%SystemPath%\icacls.exe" c:\windows\WEB\wallpaper\Windows\img0.jpg /Grant Administrators:(F)
	"%SystemPath%\icacls.exe" C:\Windows\Web\4K\Wallpaper\Windows\*.* /Grant Administrators:(F)
	del /q c:\windows\WEB\wallpaper\Windows\img0.jpg
	del /q C:\Windows\Web\4K\Wallpaper\Windows\*.*
	copy img0.jpg c:\windows\WEB\wallpaper\Windows
	copy img0.jpg C:\Windows\Web\4K\Wallpaper\Windows
	exit /b

:DevicesandPrintersShortcut
	"%SystemPath%\xcopy.exe" /y "Devices and Printers.lnk" "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\System Tools\"
	exit /b

:DefaultFileAssociations
	"%SystemPath%\dism.exe" /online /import-defaultappassociations:CustomFileAssoc2016.xml /NoRestart
	exit /b

:Decrapifier
	copy win10decrapifier.ps1 C:\Temp\Stuff\win10decrapifier.ps1 /y
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -ExecutionPolicy Bypass -File C:\Temp\Stuff\win10decrapifier.ps1
	del /f C:\Temp\Stuff\win10decrapifier.ps1
	set quick=false
	exit /b

:QuickDecrapifier
	copy win10decrapifier.ps1 C:\Temp\Stuff\win10decrapifier.ps1 /y
	"%SystemPath%\WindowsPowerShell\v1.0\PowerShell.exe" -ExecutionPolicy Bypass -File C:\Temp\Stuff\win10decrapifier.ps1 -settingsonly
	del /f C:\Temp\Stuff\win10decrapifier.ps1
	exit /b
		
:eof
	endlocal
	popd
