#####################################################################################################
## computrace.ps1
## this is the silent installer that computrace recommends using on
## https://community.absolute.com/s/article/Deploy-the-Absolute-agent-via-Group-Policy-Startup-Script
#####################################################################################################

$ProcessName="rpcnet"
Get-Process $ProcessName -ErrorAction SilentlyContinue > $Nul

If (!($?)){
# Specify the path
$destDir = "C:\Windows\Temp\Absolute"

# If folder does not exists, create it
If (!(Test-Path $destDir)) {
New-Item -Path $destDir -ItemType Directory
}
else {
# // Directory already exists!
}
Copy-Item "Computrace.msi" -Destination "C:\Windows\Temp\Absolute"
msiexec /i C:\Windows\Temp\Absolute\Computrace.msi /qn /l* C:\Windows\Temp\Absolute\Agent.log
} else {
# // Absolute agent is running"
}