:: What it does:
:: dump bios contents to biosdump.txt
:: Set each line in bcusettings.txt as variable %%A,
:: read the part in the first set of quotes and make it variable %%B,
:: then perform a find operation for %%B in BIOSDUMP.txt, 
:: if found, perform biosconfigutility.exe /setvalue:%%A.
::
:: FOR EXAMPLE.
:: Line 1 of BIOENFORCERSettings.txt is "Audio Alerts During Boot","Enable". 
:: We echo this into a text file temp.txt
:: we read temp.txt for everything before the , (note the delims=, tokens=1)
:: The result is "Audio Alerts During Boot". Now we search for "Audio Alerts During Boot" in BIOSDUMP.txt
:: if we find it, perform biosconfigutility.exe /setvalue:"Audio Alerts During Boot","Enable"

pushd "%~dp0"
setlocal enabledelayedexpansion

Call :verifyHP
if exist "C:\it folder\megascript progress report\BIOSENFORCER.txt" goto eof
Call :ENFORCEBIOS > "C:\it folder\megascript progress report\BIOSENFORCER.txt
goto EOF

:::::::::::::
::FUNCTIONS::
:::::::::::::


:verifyHP &:: ensures that the PC running the script is an HP. Cancels it otherwise.
	for /f "usebackq tokens=2 delims==" %%A IN (`wmic csproduct get vendor /value`) DO SET VENDOR=%%A

	FOR %%G IN ("Hewlett-Packard"
            "HP"
            ) DO (
            IF /I "%vendor%"=="%%~G" GOTO MATCHHP
	    )

		:NOMATCH
			set HP=False

		:MATCHHP
			set HP=True && Echo Configuring BIOS. Please be patient...
	exit /b

:ENFORCEBIOS
	if %HP%==False exit /b
	@echo off
	if not exist C:\temp mkdir C:\Temp
	BiosConfigUtility.exe /get:"C:\Temp\BIOSDUMP.txt"
	for /F "tokens=*" %%A in ( BIOSENFORCERSettings.txt ) do (
		echo %%A > C:\Temp\BIOSENFORCERTEMP.txt
		for /F "delims=, tokens=1" %%B in ( C:\Temp\BIOSENFORCERTEMP.txt ) do (
			find %%B C:\Temp\BIOSDUMP.txt > nul
			if errorlevel 0 if not errorlevel 1 biosconfigutility.exe /setvalue:%%A
		)
	)
	del C:\Temp\BIOSENFORCERTEMP.txt /f /s /q
	del C:\Temp\BIOSDUMP.txt /f /s /q
	exit /b



:eof

FOR /F "tokens=* USEBACKQ" %%F IN (`wmic computersystem get model /value ^| find "Model"`) DO (SET var=%%F)

if %HP%==True ( BiosConfigUtility.exe /get:"C:\it folder\megascript progress report\%var%.txt" )

popd
ENDLOCAL
