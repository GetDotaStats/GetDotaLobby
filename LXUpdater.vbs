forceCScriptExecution

SetLocale(1033)

dim steampath
dim steampaths(20)
steampath = readfromRegistry("HKEY_CURRENT_USER\Software\Valve\Steam\SteamPath", "")

dim oShell, appDataLocation
Set oShell = CreateObject( "WScript.Shell" )
appDataLocation=oShell.ExpandEnvironmentStrings("%APPDATA%")

dim count
count = 0
steampaths(count) = steampath
count = count + 1

if steampath = "" then
	wscript.echo "Failed to find the steam directory.  If you're sure steam is installed, follow the manual installation."
  GoSleep(3)
	wscript.quit(1)
end if

'dim xHttp: Set xHttp = createobject("Microsoft.XMLHTTP")
dim xHttp: Set xHttp = createobject("MSXML2.ServerXMLHTTP.6.0")
dim bStrm: Set bStrm = createobject("Adodb.Stream")
'xHttp.Open "GET", "http://getdotastats.com/d2mods/api/lobby_version.txt", False
xHttp.Open "GET", "https://github.com/GetDotaStats/GetDotaLobby/raw/master/version.txt", False
xHttp.Send

dim latestVer, currentVer, latestVerStr, currentVerStr
latestVerStr = xHttp.responseText
latestVer = CDbl(xHttp.responseText)
currentVer = 0.00

dim verFile
Set objFSO = CreateObject("Scripting.FileSystemObject")
If (objFSO.FileExists(appDataLocation & "\version.txt")) Then
  Set verFile = objFSO.OpenTextFile(appDataLocation & "\version.txt",1)
  currentVerStr = verFile.ReadAll()
  If (InStr(currentVerStr, ".") > 0) Then
    currentVer = CDbl(currentVerStr)
  End If
  verFile.Close
  Set verFile = Nothing
End If

Wscript.echo "Latest Version: " & latestVer & " -- Current Version: " & currentVer

If (currentVer >= latestVer) Then
  Wscript.echo "Your Lobby Explorer is up to date.  No update will be performed"
  GoSleep(2)
  Wscript.quit(0)
End If

Wscript.echo "Your Lobby Explorer is not up to date.  Downloading new version.  Please wait."
Set xHttp = createobject("MSXML2.ServerXMLHTTP.6.0")
Set bStrm = createobject("Adodb.Stream")
'xHttp.Open "GET", "https://github.com/GetDotaStats/GetDotaLobby/raw/lobbybrowser/play_weekend_tourney.zip", False
xHttp.Open "GET", "https://github.com/GetDotaStats/GetDotaLobby/raw/master/play_weekend_tourney.zip", False
'xHttp.Open "GET", "https://s3.amazonaws.com/gdslx/play_weekend_tourney.zip", False
xHttp.Send

with bStrm
    .type = 1 '//binary
    .open
    .write xHttp.responseBody
    .savetofile appDataLocation & "\lx.zip", 2 '//overwrite
end with

Wscript.echo "Download complete.  Finding your steam directory paths."

Set objFile = objFSO.OpenTextFile(steampath & "\config\config.vdf", 1)

dim line
Set myRegExp = New RegExp
myRegExp.IgnoreCase = True
myRegExp.Global = True
myRegExp.Pattern = """BaseInstallFolder_.+""[^""]+""(.*)"""

i = 0
Do Until objFile.AtEndOfStream
	line = objFile.ReadLine
	if InStr(line, """BaseInstallFolder_") <> 0 then
		Set mc = myRegExp.Execute(line)
		if mc.Count = 0 then
			wscript.echo "Couldn't find steam base install path in config.vdf"
		else
			
			Set match = mc.Item(0)
			
			steampaths(count) = match.SubMatches.Item(0)
			count = count + 1
		end if 
	end if
i = i + 1
Loop
objFile.Close

dim found
found = False

Wscript.echo "INSTALLING LOBBY EXPLORER"
For each path In steampaths
	if path <> "" then
		if objFSO.FolderExists(path & "\steamapps\common\dota 2 beta\") then
			found = True
			Wscript.echo "Installing in path: " & path & "\steamapps\common\dota 2 beta\resource\flash3"
			
			Dim objShell
			Set objShell = WScript.CreateObject ("WScript.shell")
      objShell.run "cmd /c mkdir """ & path & "\steamapps\common\dota 2 beta\dota\resource\flash3""", 7, true
			'objShell.run "xcopy resource """ & path & "\steamapps\common\dota 2 beta\dota\resource""" & " /Y /E ", 7, true
			Set objShell = Nothing
      
      UnzipFiles objFSO.GetAbsolutePathName(path & "\steamapps\common\dota 2 beta\dota\resource\flash3"), objFSO.GetAbsolutePathName(appDataLocation & "\lx.zip")
		end if 
	end if
Next

if found then
	Wscript.echo "DONE INSTALLING"
else
	Wscript.echo "Unable to find dota directory.  Installation failed."
  GoSleep(3)
  wscript.quit(0)
end if 

' Write out the version.txt since the update suceeded
Set verFile = objFSO.OpenTextFile(appDataLocation & "\version.txt",2,true)
verFile.WriteLine(latestVerStr)
verFile.Close
Set verFile = Nothing

GoSleep(2)

wscript.quit(0)


Function GoSleep(seconds) 

wsv = WScript.Version 

if wsv >= "5.1" then 
WScript.Sleep(seconds * 1000) 
else 

startTime = Time() ' gets the current time 
endTime = TimeValue(startTime) + TimeValue(elapsed) ' calculates when time is up 

While endTime > Time() 

DoEvents 
Wend 
end if 
End Function 

Sub forceCScriptExecution
    Dim Arg, Str
    If Not LCase( Right( WScript.FullName, 12 ) ) = "\cscript.exe" Then
        For Each Arg In WScript.Arguments
            If InStr( Arg, " " ) Then Arg = """" & Arg & """"
            Str = Str & " " & Arg
        Next
        CreateObject( "WScript.Shell" ).Run _
            "cmd /C cscript //nologo """ & _
            WScript.ScriptFullName & _
            """ " & Str & " && pause"
        'CreateObject( "WScript.Shell" ).Run "cmd /C pause"
        WScript.Quit
    End If
End Sub

function readFromRegistry (strRegistryKey, strDefault )
    Dim WSHShell, value

    On Error Resume Next
    Set WSHShell = CreateObject("WScript.Shell")
    value = WSHShell.RegRead( strRegistryKey )

    if err.number <> 0 then
        readFromRegistry= strDefault
    else
        readFromRegistry=value
    end if

    set WSHShell = nothing
end function

    '========================
    'Sub: UnzipFiles
    'Language: vbscript
    'Usage: UnzipFiles("C:\dir", "extract.zip")
    'Definition: UnzipFiles([Directory where zip is located & where files will be extracted], [zip file name])
    '========================
    Sub UnzipFiles(folder, file)
        Dim sa, filesInzip, zfile, fso, i : i = 1
        Set sa = CreateObject("Shell.Application")
        Set fso = CreateObject("Scripting.FileSystemObject")
        'WScript.echo folder
        'WScript.echo file
        Set filesInzip=sa.NameSpace(file).Items()
        For Each zfile In filesInzip
            If Not fso.FileExists(folder & zfile) Then
                sa.NameSpace(folder).CopyHere zfile, 20
                i = i + 1
            End If
            If i = 99 Then
            zCleanup file, i
            i = 1
            End If
        Next
        If i > 1 Then 
            zCleanup file, i
        End If
        'fso.DeleteFile(folder&file)
    End Sub

    '========================
    'Sub: zCleanup
    'Language: vbscript
    'Usage: zCleanup("filename.zip", 4)
    'Definition: zCleanup([Filename of Zip previously extracted], [Number of files within zip container])
    '========================
    Sub zCleanUp(file, count)   
        'Clean up
        Dim i, fso
        Set fso = CreateObject("Scripting.FileSystemObject")
        For i = 1 To count
           If fso.FolderExists(fso.GetSpecialFolder(2) & "\Temporary Directory " & i & " for " & file) = True Then
           text = fso.DeleteFolder(fso.GetSpecialFolder(2) & "\Temporary Directory " & i & " for " & file, True)
           Else
              Exit For
           End If
        Next
    End Sub