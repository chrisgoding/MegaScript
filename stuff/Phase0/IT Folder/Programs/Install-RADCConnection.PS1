##########################################################################################
## https://gallery.technet.microsoft.com/scriptcenter/313a95b3-a698-4bb0-9ed6-d89a47eacc72
## Shortened version of Install-RADCConnection.ps1 from technet.
## I edited it down to just the line that performs the install
##
## Email chrisgoding@polk-county.net with any concerns or suggestions
##########################################################################################

Start-Process -FilePath rundll32.exe -ArgumentList 'tsworkspace,WorkspaceSilentSetup',"C:\IT Folder\Area 51\Doubleclick this to add RDS apps.wcx" -NoNewWindow -Wait
