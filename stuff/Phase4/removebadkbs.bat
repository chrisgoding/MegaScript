pushd "%~dp0"
for /F "tokens=*" %%A in ( badkbs.txt ) do if exist %%A* del /f /q %%A*
@pause
