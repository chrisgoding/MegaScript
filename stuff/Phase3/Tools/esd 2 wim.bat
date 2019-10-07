pushd "%~dp0"

dism /Get-WimInfo /WimFile:install.esd

dism /export-image /SourceImageFile:install.esd /SourceIndex:6 /DestinationImageFile:install.wim /Compress:max /CheckIntegrity

popd
@pause
