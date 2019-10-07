:: search microsoft update catalog with
:: YYYY-MM Servicing Stack Update for Windows 10 Version YYMM
:: YYYY-MM Cumulative Update for Windows 10 Version YYMM
:: YYYY-MM Cumulative Update for .NET Framework 3.5, 4.7.2 and 4.8 for Windows 10 Version YYMM for x64
:: YYYY-MM Security Update for Adobe Flash Player for Windows 10 Version YYMM
:: place those updates in the same directory as the wim file, in this case "C:\IT Folder\Sources"
:: find index with:
:: Dism /Get-ImageInfo /imagefile:"C:\IT Folder\Sources\install.wim"

pushd "%~dp0"
setlocal

:setvariables
	set networkshare=\\vboccfs02.polk-county.net\it_ssm\stuff\Phase3\1809\sources
	set localshare=C:\IT Folder\Sources

:copywim
	if not exist "%localshare%\install.wim" xcopy "%networkshare%\install.wim" "%localshare%" /Y

:removeoldmount
	Dism /Unmount-image /MountDir:C:\Mount /Discard
	dism /cleanup-wim

:mount
	if not exist C:\Mount mkdir C:\Mount
	dism /mount-wim /wimfile:"%localshare%\install.wim" /mountdir:C:\Mount /index:1

:update
	for %%f in (*.msu) do (
	echo %%~nf
	dism /image:C:\Mount /add-package /packagepath:"%localshare%\%%~nf.msu" /PreventPending
	)

:cleanup
	Dism /Image:C:\Mount /Cleanup-Image /StartComponentCleanup /ResetBase

:unmount
	Dism /unmount-wim /mountdir:C:\Mount /commit
	dism /Export-image /SourceImageFile:install.wim /SourceIndex:1 /DestinationImageFile:install-new.wim /DestinationName:"Windows 10 Pro" /compress:max
	del install.wim /f /q
	ren install-new.wim install.wim
	del "%networkshare%\install.wim.old" /f /q
	ren "%networkshare%\install.wim" "%networkshare%\install.wim.old"
	xcopy "%localshare%\install.wim" "%networkshare%" /Y
	endlocal
	@pause
