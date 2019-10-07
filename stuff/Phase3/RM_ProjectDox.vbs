'  Title:      Uninstall MSI
'   Date:      5/25/2010
'Updated:      10/23/2012
' Author:      Gregory Strike
'    URL:      http://www.gregorystrike.com/2010/05/24/vbscript-to-uninstall-old-citrix-clients/
'
'Purpose:      The following script will remove any MSI 
'
'License:      This script is free to use given the following restrictions are followed.
'              1. When used the Author and URL above must remain in place, unaltered.
'              2. Do not publish the contents of this script anywhere. Instead a link
'                 must be provided back to the URL listed above.
'
'Requirements: Administrative Privileges

const HKEY_LOCAL_MACHINE = &H80000002
  
strComputer = "."
  
Function UninstallApp(strDisplayName, strVersion, strID, strUninstall)
    Dim objShell
    Dim objFS
    WScript.Echo "Attempting to uninstall: " & strDisplayName & " v" & strVersion
  
    If strID = "" Then  'We don't know the GUID of the app
        'Look at the Uninstall string and determine what is the
        'executable and what are the command line arguments.
        Set objFS = CreateObject("Scripting.FileSystemObject")
  
        strExecutable = ""
  
        'Start from the beginning of the string and see if we can find the excutable in the string
        For X = 0 to Len(strUninstall)
            strExecutableTest = Left(strUninstall, X)
            strExecutableTest = Replace(strExecutableTest, """", "")
            'Test to see if the current string is a file.
            If objFS.FileExists(strExecutableTest) Then
                strExecutable = Trim(strExecutableTest)
                intExecLength = X
            End If
        Next
  
        If strExecutable = "" Then
            WScript.Echo "Bad string or the executable does not exist: " & strUninstall
            Exit Function
        Else
            strArguments = Right(strUninstall, Len(strUninstall) - intExecLength)
            'WScript.Echo "The executable is: " & strExecutable
            'WScript.Echo "The arguments are: " & strArguments
        End If
  
        Uninstall = """" & strExecutable & """ " & strArguments
  
        If InStr(Uninstall, "ISUNINST.EXE") > 0 Then
            Uninstall = Uninstall & " -a"
        End If
    Else 'We have the GUID
        Uninstall = """MSIEXEC.EXE"" /X " & strID & " /qn /norestart "
    End If
  
    WScript.Echo "...Executing: " & Uninstall
  
    Set objShell = WScript.CreateObject("WScript.Shell")
    objShell.Run Uninstall, 1 , 1
  
    Set objShell = Nothing
End Function
  
WScript.Echo ""
WScript.Echo Now() & " - Searching for MSI Application..."
  
Set ObjWMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
 
UninstallLoop("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
UninstallLoop("SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
  
Sub UninstallLoop(strKeyPath)
    ObjWMI.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys
     
    'If strKeyPath doesn't exist, exit the routine before throwing an error.
    If IsNull(arrSubKeys) Then Exit Sub
     
    WScript.Echo Now() & " - Searching " & strKeyPath
         
    For Each Product In arrSubKeys
        objWMI.GetStringValue HKEY_LOCAL_MACHINE, strKeyPath & "\" & Product, "DisplayName", strDisplayName
        objWMI.GetStringValue HKEY_LOCAL_MACHINE, strKeyPath & "\" & Product, "DisplayVersion", strVersion
        objWMI.GetStringValue HKEY_LOCAL_MACHINE, strKeyPath & "\" & Product, "UninstallString", strUninstall
      
        strName = UCase(strDisplayName)
      
        'Grab the GUID of the MSI if available.
        If Left(Product, 1) = "{" And Right(Product, 1) = "}" Then
            strID = Product
        Else
            strID = ""
        End If
      
        'Determine version of the Product
        If strVersion <> "" Then
            VersionArray = Split(strVersion, ".")
            If UBound(VersionArray) > 0 Then
                'Verify that only numbers are in the version string
                If IsNumeric(VersionArray(0)) And IsNumeric(VersionArray(1)) Then
                    Version = CDbl(VersionArray(0) & "." & VersionArray(1))
                Else
                    Version = ""
                End If
            End If
        Else
            Version = ""
        End If
      
        'Hub Alert has used serveral versions.  This
        'should capture most, if not all, of them.
 
     
        If InStr(1,UCase(strName),UCase("ProjectDox Components"),1) > 0 Then
            UninstallApp strDisplayName, strVersion, strID, strUninstall
        End If

    Next
End Sub
 
WScript.Echo Now() & " - Search Complete."
WScript.Echo ""