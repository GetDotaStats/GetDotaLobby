forceCScriptExecution

dim boxresult
boxresult = MsgBox ("Are you sure you want to uninstall the Lobby Explorer?  This will delete any local settings you have.", vbYesNo, "Uninstall Lobby Explorer?")

Select Case boxresult
  Case vbNo
    wscript.quit(0)
End Select

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
  objFSO.DeleteFile(appDataLocation & "\version.txt")
  Wscript.echo "Deleted old version.txt"
End If

If (objFSO.FileExists(appDataLocation & "\lx.zip")) Then
  objFSO.DeleteFile(appDataLocation & "\lx.zip")
  Wscript.echo "Deleted lx.zip"
End If

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

Wscript.echo "UNINSTALLING LOBBY EXPLORER"
For each path In steampaths
	if path <> "" then
		if objFSO.FolderExists(path & "\steamapps\common\dota 2 beta\dota\resource\flash3") then
			found = True
			Wscript.echo "Uninstalling from path: " & path & "\steamapps\common\dota 2 beta\dota\resource\flash3"
			
      objFSO.DeleteFolder(path & "\steamapps\common\dota 2 beta\dota\resource\flash3")
		end if 
	end if
Next

if found then
	Wscript.echo "DONE UNINSTALLING "
else
	Wscript.echo "Unable to find dota directory.  Uninstallation failed."
end if 

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