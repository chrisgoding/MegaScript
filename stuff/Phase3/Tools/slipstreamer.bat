:: search microsoft update catalog with
:: YYYY-MM Servicing Stack Update for Windows 10 Version YYMM
:: YYYY-MM Cumulative Update for Windows 10 Version YYMM
:: YYYY-MM Cumulative Update for .NET Framework 3.5, 4.7.2 and 4.8 for Windows 10 Version YYMM for x64
:: YYYY-MM Security Update for Adobe Flash Player for Windows 10 Version YYMM
:: place those updates into the appropriate update directory, ie C:\IT Folder\1809updates
:: find index of a wim file with:
:: Dism /Get-ImageInfo /imagefile:"C:\IT Folder\Sources\install.wim"

pushd "%~dp0"
setlocal

:Update1809
	set networkshare=\\<yourserver>\MegaScript\stuff\Phase3\1809\sources
	set localshare=C:\IT Folder\
	set updatelocation=C:\IT Folder\1809updates
	Call :UpgradeWIM

:Update1903
	set networkshare=\\<yourserver>\MegaScript\stuff\Phase3\1903\sources
	set localshare=C:\IT Folder\
	set updatelocation=C:\IT Folder\1903updates
	Call :UpgradeWIM

:Update1909
	set networkshare=\\<yourserver>\MegaScript\stuff\Phase3\1909\sources
	set localshare=C:\IT Folder\
	set updatelocation=C:\IT Folder\1909updates
	Call :UpgradeWIM

Goto EOF

:::::::::::::
::FUNCTIONS::
:::::::::::::

:UpgradeWIM
	Call :CopyWIM
	Call :RemoveOldMount
	Call :Mount
	Call :Update
	Call :Cleanup
	Call :Unmount
	exit /b

:CopyWIM
	xcopy "%networkshare%\install.wim" "%localshare%" /Y
	exit /b

:RemoveOldMount
	Dism /Unmount-image /MountDir:C:\Mount /Discard
	dism /cleanup-wim
	exit /b

:Mount
	if not exist C:\Mount mkdir C:\Mount
	dism /mount-wim /wimfile:"%localshare%\install.wim" /mountdir:C:\Mount /index:1
	exit /b

:Update
	for %%f in ( "%updatelocation%\*.msu" ) do (
	echo %%~nf
	dism /image:C:\Mount /add-package /packagepath:"%updatelocation%\%%~nf.msu" /PreventPending
	)
	exit /b

:Cleanup
	Dism /Image:C:\Mount /Cleanup-Image /StartComponentCleanup /ResetBase
	exit /b

:Unmount
	Dism /unmount-wim /mountdir:C:\Mount /commit
	dism /Export-image /SourceImageFile:install.wim /SourceIndex:1 /DestinationImageFile:install-new.wim /DestinationName:"Windows 10 Pro" /compress:max
	del install.wim /f /q
	ren install-new.wim install.wim
	del "%networkshare%\install.wim.old" /f /q
	xcopy "%localshare%\install.wim" "%networkshare%" /Y
	exit /b

:EOF
@pause
popd
endlocal
