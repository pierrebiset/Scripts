<#
ChangeLog:
	- June 5, 2013 : Added -Alignment Parameter to "New-Partition" PS command (Un-Mountable XP Boot Volume Issue)
	- June 6, 2013 : Replaced "/force" with "/mbr" in bootsect.exe commnad.
    - Sept 12, 2013 : Added WinRE Partition functionality.
#>


Function fMain {
trap {"Error found: $_" | Out-File "x:\SearchAndApply.log"}

	Clear-Host
    #Checks if "Local Disk" found is over 100GB.
	$Disk = Get-Disk -Number 0 | Where-Object { $_.Size -gt 100000000000 }
	If ($Disk -eq $null) {Write-Output "100GB Local Disk is not found, exiting script..."; Exit}

    fCreateAnswerFiles

    If ((!(Test-Path("$env:temp\configHD.txt"))) -and (!(Test-Path("$env:temp\configHD2.txt")))) {
    Write-Output "Could not access Temp Drive..."; Exit}
    
    Write-Output "Re-Partitioning Disk..."
    Start-Process "x:\windows\system32\cmd.exe" @('/C diskpart.exe /s configHD.txt"') -Wait -WorkingDirectory $env:temp -WindowStyle Minimized | Out-Null

    Write-Output "Beginning to search for .WIM file..."
    #Finds the LATEST >1G .WIM File in the root of Logical Disks
	$oWimFiles = Get-WmiObject -Query "SELECT * From Win32_LogicalDisk WHERE NOT DriveType LIKE '2' AND Size > 0 AND NOT DriveType LIKE '4'" | `
		foreach { Get-ChildItem -Force -Path @($_.DeviceID + "\") } | `
		Where-Object { ($_.FullName -Like "*.wim") -and ($_.Length -ge 1000000000) } | `
		Sort-Object -Descending CreationTime

	If ($oWimFiles -eq $null) {Write-Output "No .WIM files found..."; Exit}

    Write-Output @("Valid image located > 1gb: " + $oWimFiles[0].FullName)

    Write-Output "Prep WinRE Partition before applying WIM to OSDISK."
    New-Item -ItemType Directory -Path "R:\Recovery\WindowsRE" | Out-Null
     Write-Output "Copying Image to Recovery Partition..."
    Copy-Item -Path $oWimFiles[0].FullName -Destination "R:\recovery\windowsre\install.wim" -Confirm:$false -Force | Out-Null

    #Provide Status on what .WIM file will be applied.
    Write-Output @("Image will now be applied to system partition (" + $oWimFiles[0].Name + ")")  
	Start-Process "x:\windows\system32\imagex.exe" @('/apply "R:\Recovery\WindowsRE\install.wim" 1 C:') -Wait -NoNewWindow

    Start-Process "x:\windows\system32\cmd.exe" @('/C bcdboot.exe C:\Windows') -Wait | Out-Null

    If (Test-Path("C:\Windows\System32\Recovery\winre.wim")) {
    Copy-Item -Path "C:\Windows\System32\Recovery\winre.wim" -Destination "R:\recovery\windowsre" -Confirm:$false -Force
    }else{
    Write-Output "Could not find WinRE.WIM file..."; Exit}

	Start-Process "x:\windows\system32\cmd.exe" @('/C C:\Windows\system32\ReAgentc.exe /setreimage /path "R:\Recovery\WindowsRE" /target "C:\Windows"') -Wait -LoadUserProfile -NoNewWindow
	Start-Process "x:\windows\system32\cmd.exe" @('/C C:\Windows\system32\ReAgentc.exe /setosimage /path "R:\Recovery\WindowsRE" /target "C:\Windows"') -Wait -LoadUserProfile -NoNewWindow

    Start-Process "x:\windows\system32\cmd.exe" @('/C diskpart.exe /s "' + $env:temp + '\configHD2.txt"') -Wait | Out-Null

    Write-Output "Completed with applying image and prepping Recovery Partition."
	
	Write-Output @("Boot sector is prepped... Shutting down in 5 seconds...")
	Sleep -Milliseconds 5000
	If (Test-Path("C:\Windows")) {
		#Start-Process "x:\windows\system32\wpeutil.exe" @('"shutdown"')
	} else {
		Write-Output @("ImageX did not apply image successfully.... Shutting down in 5 seconds...")
		"ImageX did not apply image successfully." | Out-File "x:\SearchAndApplyError.log"
		Exit
	}
}

Function fCreateAnswerFiles {
'select disk 0
clean
create partition primary size=500
select partition 1
active
format fs=ntfs label="System" quick
create partition primary size=25000
select partition 2
format fs=ntfs label="Recovery" quick
assign letter = R
create partition primary
select partition 3
format fs=ntfs label="OS" quick
assign letter = C
exit' | Out-File "$env:temp\configHD.txt" -Encoding ascii

'select disk 0
select volume 1
set ID=27
exit' | Out-File "$env:temp\configHD2.txt" -Encoding ascii
}


fMain