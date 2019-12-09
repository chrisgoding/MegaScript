pushd "%~dp0"
setlocal
set localrepo=C:\Users\%username%\Downloads\wsusoffline11831\wsusoffline\client
set networkrepo=\\<server>\MegaScript\stuff\Phase4\wsus

ROBOCOPY %localrepo% %networkrepo% /MIR

popd
endlocal
