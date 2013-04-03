'==========================================================================
' NAME: SecuritasFirstRun.vbs
' AUTHOR: Brian Gonzalez, Panasonic
' DATE  : 9/24/2012
' PURPOSE: Post Image Script for H2Mk1 For Securitas
'==========================================================================
On Error Resume Next
'Setup Objects
Const cForReading = 1, cForWriting = 2, cForAppending = 8
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = WScript.CreateObject("WScript.Shell")
Set oNetwork = createobject("Wscript.Network")
Set oWMI = GetObject("winmgmts:")

'Setup Vars and Constants
sScriptFolder = oFSO.GetParentFolderName(Wscript.ScriptFullName) 'No trailing backslash
sGobiResourcesPath = sScriptFolder & "\GlobalCSA"
sLogFilePath = sScriptFolder & "\SecuritasFirstRun.log"

'Get Short Names for easy use in Cmd.exe
sScriptFolder = fGetShortName( sScriptFolder )
sWSNamePath = fGetShortName( sScriptFolder & "\wsname.exe" )
sIEConfigPath = fGetShortName( sScriptFolder & "\IE9-Setup-Full.msi" )
sVerizonCMPath = fGetShortName( sScriptFolder & "\VZAM Enterprise 7.7.7 (2762d).msi\VZAM Enterprise 7.7.7 (2762d).msi" )
sEricsonWWANDriverPath = fGetShortName( sScriptFolder & "\F5521gw(Ericsson)WWANDriver_v1.02l12_53A_53D_W732_ss9615" )
sTouchscreenPath = fGetShortName( sScriptFolder & "\DualTouchDriver_v7.0.3-7_H2A_H2B_W732_ss9602" )
	
sGOBI2KFPNP = "VID_04DA&PID_250F" 'GOBI 2000 PNP ID
sGOBI2KEPNP = "VID_04DA&PID_250E" 'GOBI 2000 PNP ID
sERICSONPNP = "VID_0BDB&PID_190D" 'Ericson Modem

'Main Execution section of script
'==========================================================================
'Open Logfile object...
Set oLogFile = oFSO.OpenTextFile(sLogFilePath, cForWriting, True)
fLogHelper "SecuritasFirstRun script has begun on " & Date, ""
fLogHelper "sCarrierChoice is set to: " & sCarrierChoice, ""

'Change Compname to "SEC-" and the system's serial number...
If oFSO.FileExists(sWSNamePath) Then
	fLogHelper "Renaming Computer using wsname", "begin"
	For Each oBios In oWMI.InstancesOf("Win32_BIOS")
		sNewName = oBios.SerialNumber
	Next
	sNewName = "SEC-" & Trim( Left(sNewName, 10) )
	fLogHelper "Executing " & sCmd & "...", ""
	sCmd = sWSNamePath & " /N:" & sNewName
	sRet = oShell.Run(sCmd, 0, True)
	fLogHelper "Renamed Computer using wsname to """ & sNewName & """ complete", sRet
Else
	fLogHelper "WSName executable not found..", ""
End If

'Reinstall the Dual Touchscreen driver
If oFSO.FolderExists(sTouchscreenPath) Then
	fLogHelper "Reinstalling Dual Touchscreen driver.", "begin"
	oShell.CurrentDirectory = sTouchscreenPath
	sCmd = "cmd.exe /c pinstall.bat"
	sRet = oShell.Run(sCmd, 0, True)
	fLogHelper "Dual Touchscreen driver install complete", sRet
Else
	fLogHelper "Dual Touchscreen driver folder not found.", ""
End If

'Inject Securitas IE Configuration Settings...
If oFSO.FileExists(sIEConfigPath) Then
	sCmd = "msiexec.exe /i " & sIEConfigPath & " /passive /log C:\SOFTWARE\IE9Config.log"
	fLogHelper "Executing " & sCmd & "...", ""
	sReturn = oShell.Run(sCmd, 0, 0)
	If sReturn Then
		fLogHelper "Executing " & sCmd & " failed.", "begin"
	End If
	fLogHelper "Completed executing " & sCmd & "...", sReturn
End If

'Delay script to let IE Configuration complete...
Wscript.Sleep 15000

'Configure Power Plan...
'Add powercfg -import

'Disabling Windows update...
oShell.Run "sc stop wuauserv"
fLogHelper "Stopping the windows Update service.", "begin"
oShell.Run "sc config wuauserv start= disabled"
fLogHelper "Disabling windows Update service.", err.Number

'Disabling Adobe Reader update
oShell.Run "sc stop AdobeARMservice"
fLogHelper "Stopping the Adobe Reader Update service.", "begin"
oShell.Run "sc config AdobeARMservice start= disabled"
fLogHelper "Disabling Adobe Reader Update service.", err.Number

'Detect and install appropiate WWAN Drivers
If fPNPMatch(strGOBI2KFPNP) Or fPNPMatch(strGOBI2KEPNP) Then
	fLogHelper "Gobi 2000 modem found setting up", "begin"
	If oFSO.FolderExists(sGobiResourcesPath) Then
		If Not oFSO.FolderExists("C:\Program Files\Qualcomm\DriverPackage") Then
			sCmd = sGobiResourcesPath & "\Gobi2kPackage\setup.exe -s -f2""c:\windows\temp\gobi2000.log"""
			fLogHelper "Executing: " & sCmd, "begin"
			sReturn = oShell.Run(sCmd, 0, True)
			If sReturn Then
				fLogHelper "Installing base gobi2000 components failed is complete, see c:\windows\temp\gobi2000.褑廝䱊컳炡말׭쿰װre info.", sReturn
			End If
			fLogHelper "gobi2000 Base components install is complete", sReturn
		Else
			fLogHelper "gobi2000 Base components already installed.", ""
		End If

		'Ensure Verizon firmware is applied
		sCmd = sGobiResourcesPath & "\CSAPack\SetFirm2.exe -switch:vzw"
		fLogHelper "Executing: " & sCmd, "beg                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              