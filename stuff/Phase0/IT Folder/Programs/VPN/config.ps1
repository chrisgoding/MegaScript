# Copyright (c) 2013 Check Point Software Technologies Ltd.
# All rights reserved.

# Please see https://supportcontent.checkpoint.com/solutions?id=sk93638 for more information and extended usage help.

param (
	[string]$gateway,
	[string]$name = "$gateway",
	[switch]$force = $false,
	[switch]$remove = $false,
	[switch]$uninstall = $false,
	[switch]$sl = $false,
	[string]$xmlfile = "",
	[string]$debug = "2",
	[string]$port = "443",
	[string]$timeout = "30",
	[string]$cn = "",
	[string]$fingerprint = "",
	[string]$auth = "",
	[string]$regkey = "",
	[string]$p12file = "",
	[string]$sso = "false",
	[string]$lowcost = "true",
	[string[]]$routes
)

$appName = "B4D42709.CheckPointVPN"
if ($sl) {
	$appName = "B4D42709.CheckPointVPN-SL"
}
$added = $false

try {

	if (-not (
			($gateway -ne "") -or
			($gateway -eq "" -and $name -ne "" -and $remove) -or
			($gateway -eq "" -and -not $remove -and $uninstall))) {
		$script = $MyInvocation.MyCommand.Name
		Write-Host @"
Usage:

Add/refresh a connection:

$script -gateway GATEWAY [-remove] [-name NICKNAME] [-force] \
	[[-xmlfile XML-FILE] | \
	 [-debug LEVEL] [-timeout TIMEOUT] [-port PORT] \
	 [-fingerprint FINGERPRINT -cn CN] [-auth AUTH] \
	 [-regkey REGKEY] [-p12file P12FILE] [-sso true|false] \
	 [-lowcost true|false] [-routes ROUTE-LIST]]

Remove a connection:

$script -name NAME -remove

Please see https://supportcontent.checkpoint.com/solutions?id=sk93638 for more information and extended usage help.

"@
		exit 1
	}

	if ($uninstall) {
		if (-not $sl) {
			Write-Host "Cannot uninstall the inbox VPN plugin"
			exit 1
		}
		Write-Host "Uninstalling the package..."
		$package = Get-AppxPackage |
			foreach {if ($_.Name -eq "$appName") {$_.ToString()}}
		if ($package -ne $null) {
			Remove-AppxPackage -Package $package
		}
		exit
	}

	$appId = Get-AppxPackage |
		foreach {if ($_.Name -eq "$appName") {$_.PackageFamilyName}}
	if ($appId -eq $null) {
		throw "Could not retrieve $appName"
	}

	if ($remove) {
		Write-Host "Removing the connection..."
		if ((Get-VpnConnection |
				foreach {if ($_.Name -eq "$name") {$_.Name}}) -ne $null) {
			Write-Host "Trying to disconnect..."
			rasdial $name /DISCONNECT
			Remove-VpnConnection -ConnectionName $name -Force
		}
		if ($gateway -eq "") {
			exit
		}
	}

	Write-Host "Adding the connection..."

	if ($p12file -ne "") {
		$p12file = [convert]::ToBase64String((get-content $p12file -encoding byte))
	}
	
	$xml = New-Object System.Xml.XmlDocument
	if ($xmlfile -eq "") {
		$xml.LoadXml("<CheckPointVPN port='$port' name='$name' debug='$debug' timeout='$timeout' cn='$cn' fingerprint='$fingerprint' auth='$auth' regkey='$regkey' p12file='$p12file' sso='$sso' lowcost='$lowcost' />")
	}
	else {
		$xml.Load($xmlfile)
		$xml.DocumentElement.SetAttribute("name", $name)
	}
	Add-VpnConnection -Name $name -ServerAddress $gateway -SplitTunneling $True -PlugInApplicationID $appId -CustomConfiguration $xml
	$added = $true
	$guid = (Get-VpnConnection -Name $name).Guid
	if ($xmlfile -eq "") {
		$xml = New-Object System.Xml.XmlDocument
		$xml.LoadXml("<CheckPointVPN port='$port' name='$name' debug='$debug' timeout='$timeout' cn='$cn' fingerprint='$fingerprint' auth='$auth' regkey='$regkey' p12file='$p12file' sso='$sso' lowcost='$lowcost' guid='$guid' />")
	}
	else {
		$xml.DocumentElement.SetAttribute("guid", $guid)
	}
	Set-VpnConnection -Name $name -ThirdPartyVpn -CustomConfiguration $xml
	Write-Host (Get-VpnConnection -Name $name).CustomConfiguration.OuterXML

	foreach ($route in $routes) {
		Write-Host adding: $route
		Add-VpnConnectionRoute -ConnectionName $name -DestinationPrefix $route
	}

}
catch {

	$_ | fl * -Force
	if ($added) {
		Write-Host "Cleaning up..."
		Remove-VpnConnection -Name $name -Force
	}
	if (-not $force) {
		pause
	}
	exit 1

}