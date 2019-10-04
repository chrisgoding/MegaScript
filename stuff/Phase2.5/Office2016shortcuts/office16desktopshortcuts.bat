:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Copies office shortcuts to the desktop on machines that have office 2016
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pushd "%~dp0"
setlocal enabledelayedexpansion
IF EXIST "%SystemRoot%\Sysnative\msiexec.exe" (set "SystemPath=%SystemRoot%\Sysnative") ELSE (set "SystemPath=%SystemRoot%\System32")
set "path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

"%SystemPath%\xcopy.exe" "Outlook 2016.lnk" "C:\Users\Public\Desktop" /y
"%SystemPath%\xcopy.exe" "Word 2016.lnk" "C:\Users\Public\Desktop" /y
"%SystemPath%\xcopy.exe" "Excel 2016.lnk" "C:\Users\Public\Desktop" /y

popd
endlocal
