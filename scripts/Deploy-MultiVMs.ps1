<#
.NOTES
Author: Shawn Masterson
Version: 1.2.2
Handling New-VM Async – LucD – @LucD22
Customization: @Despereaux222
.PARAMETER csvfile
Path to DeployVM.csv file with new VM info
.PARAMETER vCenter
vCenter Server FQDN or IP
.PARAMETER createcsv
Generates a blank csv file – DeployVM.csv
.EXAMPLE
.\DeployVM.ps1
Runs DeployVM
.EXAMPLE
.\DeployVM.ps1 -vcenter my.vcenter.address
Runs DeployVM specifying vCenter address
.EXAMPLE
.\DeployVM.ps1 -csvfile "E:\Scripts\Deploy\DeployVM.csv" -vcenter my.vcenter.address
Runs DeployVM specifying path to csv file, vCenter address
.EXAMPLE
.\DeployVM.ps1 -createcsv
Creates a new/blank DeployVM.csv file in same directory as script
REQUIREMENTS
PowerShell v3 or greater
vCenter (tested on 5.1/5.5)
PowerCLI 5.5 R2 or later
CSV File – VM info with the following headers
    Name, Boot, OSType, Template, CustSpec, Folder, ResourcePool, 
    CPU, CpuLimitMhz, RAM, MemLimitMB, 
    Disk1, Disk2, Disk3, Disk4, Datastore, DiskStorageFormat, 
    NetType, Network, DHCP, IPAddress, SubnetMask, Gateway, pDNS, sDNS, Notes
    Must be named DeployVM.csv
    Can be created with -createcsv switch
CSV Field Definitions
	Name – Name of new VM
	Boot – Determines whether or not to boot the VM – Must be 'true' or 'false'
	OSType – Must be 'Windows' or 'Linux'
	Template – Name of existing template to clone
	CustSpec – Name of existing OS Customiation Spec to use
	Folder – Folder in which to place VM in vCenter (optional)
	ResourcePool – VM placement – can be a reasource pool, host or a cluster
	CPU – Number of vCPU
    CpuLimitMhz - Limit CPU MHz
	RAM – Amount of RAM
    MemLimitMB - Limit RAM
    Disk1 - Extend size of present disk    (GB)(optional)
	Disk2 – Size of additional disk to add (GB)(optional)
	Disk3 – Size of additional disk to add (GB)(optional)
	Disk4 – Size of additional disk to add (GB)(optional)
	Datastore – Datastore placement – Can be a datastore or datastore cluster
	DiskStorageFormat – Disk storage format – Must be 'Thin', 'Thick' or 'EagerZeroedThick'
	NetType – vSwitch type – Must be 'vSS' or 'vDS'
	Network – Network/Port Group to connect NIC
	DHCP – Use DHCP – Must be 'true' or 'false'
	IPAddress – IP Address for NIC
	SubnetMask – Subnet Mask for NIC
	Gateway – Gateway for NIC
	pDNS – Primary DNS (Windows Only)
	sDNS – Secondary NIC (Windows Only)
	Notes – Description applied to the vCenter Notes field on VM
#>

#requires –Version 3

#——————————————————————–
# Parameters
param (
    [parameter(Mandatory=$false)]
    [string]$csvfile,
    [parameter(Mandatory=$false)]
    [string]$vcenter,
    [parameter(Mandatory=$false)]
    [switch]$auto,
    [parameter(Mandatory=$false)]
    [switch]$createcsv
    )
 
#——————————————————————–
# User Defined Variables 
 
#——————————————————————–
# Static Variables 

$scriptName = "DeployVM"
$scriptVer = "1.2.1"
$scriptDir = Split-Path –Path $MyInvocation.MyCommand.Definition –Parent
$starttime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
$logDir = $scriptDir + "\Logs\"
$logfile = $logDir + $scriptName + "_" + (Get-Date –uformat %I-%M-%S_%d-%m-%Y) + "_" + $env:username + ".txt"
$deployedDir = $scriptDir + "\Deployed\"
$deployedFile = $deployedDir + "DeployVM_" + (Get-Date –uformat %I-%M-%S_%d-%m-%Y) + "_" + $env:username  + ".csv"
$exportpath = $scriptDir + "\DeployVM.csv"
$headers = "" | Select-Object Name, Boot, OSType, Template, CustSpec, Folder, ResourcePool, CPU, CpuLimitMhz, RAM, MemLimitMB, Disk1, Disk2, Disk3, Disk4, Datastore, DiskStorageFormat, NetType, Network, DHCP, IPAddress, SubnetMask, Gateway, pDNS, sDNS, Notes
$taskTab = @{}
 
#——————————————————————–
# Load Snap-ins
 
# Add VMware snap-in if required
If ((Get-PSSnapin –Name VMware.VimAutomation.Core –ErrorAction SilentlyContinue) -eq $null) {add-pssnapin VMware.VimAutomation.Core}
 
#——————————————————————–
# Functions
 
Function Out-Log {
    Param(
        [Parameter(Mandatory=$true)][string]$LineValue,
        [Parameter(Mandatory=$false)][string]$fcolor = "White"
    )
 
    Add-Content –Path $logfile –Value $LineValue
    Write-Host $LineValue –ForegroundColor $fcolor
}
 
Function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{
    Add-Type –AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}
 
#——————————————————————–
# Main Procedures
 
# Start Logging
Clear-Host
If (!(Test-Path $logDir)) {New-Item –ItemType directory –Path $logDir | Out-Null}
Out-Log "********************************************************************"
Out-Log "$scriptName`tVer:$scriptVer`t`t`t`tStart Time:`t$starttime"
Out-Log "********************************************************************`n"
 
# If requested, create DeployVM.csv and exit
If ($createcsv) {
    If (Test-Path $exportpath) {
        Out-Log "`n$exportpath Already Exists!`n" "Red"
        Exit
    } Else {
        Out-Log "`nCreating $exportpath`n" "Yellow"
        $headers | Export-Csv $exportpath –NoTypeInformation
		Out-Log "Done!`n"
        Exit
    }
}

# Ensure PowerCLI is at least version 5.5 R2 (Build 1649237)
If ((Get-PowerCLIVersion).Build -lt 1649237) {
    Out-Log "Error: DeployVM script requires PowerCLI version 5.5 R2 (Build 1649237) or later" "Red"
	Out-Log "PowerCLI Version Detected: $((Get-PowerCLIVersion).UserFriendlyVersion)" "Red"    
    Out-Log "Exiting…`n`n" "Red"
    Exit
}

# Test to ensure csv file is available
If ($csvfile -eq "" -or !(Test-Path $csvfile) -or !$csvfile.EndsWith("DeployVM.csv")) {
    Out-Log "Path to DeployVM.csv not specified…prompting`n" "Yellow"
    $csvfile = Read-OpenFileDialog "Locate DeployVM.csv" "C:\" "DeployVM.csv|DeployVM.csv"
}
 
If ($csvfile -eq "" -or !(Test-Path $csvfile) -or !$csvfile.EndsWith("DeployVM.csv")) {
    Out-Log "`nStill can't find it…I give up" "Red"
    Out-Log "Exiting…" "Red"
    Exit
}

Out-Log "Using $csvfile`n" "Yellow"
# Make copy of DeployVM.csv
If (!(Test-Path $deployedDir)) {New-Item –ItemType directory –Path $deployedDir | Out-Null}
Copy-Item $csvfile –Destination $deployedFile | Out-Null
 
# Import VMs from csv
$newVMs = Import-Csv $csvfile
$newVMs = $newVMs | Where {$_.Name -ne ""}
[INT]$totalVMs = @($newVMs).count
Out-Log "New VMs to create: $totalVMs" "Yellow"
 
# Check to ensure csv is populated
If ($totalVMs -lt 1) {
    Out-Log "`nError: No entries found in DeployVM.csv" "Red"
    Out-Log "Exiting…`n" "Red"
    Exit
}

# Show input and ask for confirmation, unless -auto was used
If (!$auto) {
    $newVMs | Out-GridView –Title "VMs to be Created"
    $continue = Read-Host "`nContinue (Y/N)?"
    If ($continue -notmatch "Y") {
        Out-Log "Exiting…" "Red"
        Exit
    }
}

# Connect to vCenter server
If ($vcenter -eq "") {$vcenter = Read-Host "`nEnter vCenter server FQDN or IP"}
 
Try {
    Out-Log "`nConnecting to vCenter – $vcenter`n`n" "Yellow"
    Connect-VIServer $vcenter –EA Stop | Out-Null
} Catch {
    Out-Log "`r`n`r`nUnable to connect to $vcenter" "Red"
    Out-Log "Exiting…`r`n`r`n" "Red"
    Exit
}

# Start provisioning VMs
$v = 0
Out-Log "Deploying VMs:`n" "Yellow"
Foreach ($VM in $newVMs) {
    $Error.Clear()
	$vmName = $VM.Name
    $v++
	$vmStatus = "[{0} of {1}] {2}" -f $v, $totalVMs, $vmName
	Write-Progress –Activity "Deploying VMs" –Status $vmStatus –PercentComplete (100*($v/$totalVMs))

    # Create custom OS Customization spec
    If ($vm.DHCP -match "true") {
		$spec = Get-OSCustomizationSpec –Name $VM.CustSpec
        $tempSpec = $spec | New-OSCustomizationSpec –Name temp$vmName
        $tempSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
        –IpMode UseDhcp | Out-Null
	} Else {	
		If ($VM.OSType -eq "Windows") {
	        $spec = Get-OSCustomizationSpec –Name $VM.CustSpec
	        $tempSpec = $spec | New-OSCustomizationSpec –Name temp$vmName
	        $tempSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
	        –IpMode UseStaticIP –IpAddress $VM.IPAddress –SubnetMask $VM.SubnetMask `
	        –Dns $VM.pDNS,$VM.sDNS –DefaultGateway $VM.Gateway | Out-Null
	    } ElseIF ($VM.OSType -eq "Linux") {
	        $spec = Get-OSCustomizationSpec –Name $VM.CustSpec
	        $tempSpec = $spec | New-OSCustomizationSpec –Name temp$vmName
	        $tempSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
	        –IpMode UseStaticIP –IpAddress $VM.IPAddress –SubnetMask $VM.SubnetMask `
	        –DefaultGateway $VM.Gateway | Out-Null
	    }
	}
 
    # Create VM
    Out-Log "  + $vmName"
    $taskTab[(New-VM –Name $VM.Name –ResourcePool $VM.ResourcePool –Location $VM.Folder –Datastore $VM.Datastore –DiskStorageFormat $VM.DiskStorageFormat `
    –Notes $VM.Notes –Template $VM.Template –OSCustomizationSpec temp$vmName –RunAsync –EA SilentlyContinue).Id] = $VM.Name

    # Remove temp OS Custumization spec
    Remove-OSCustomizationSpec –OSCustomizationSpec temp$vmName –Confirm:$false

    # Log errors
    If ($Error.Count -ne 0) {
        If ($Error.Count -eq 1 -and $Error.Exception -match "'Location' expects a single value") {
            $vmLocation = $VM.Folder
            Out-Log "Unable to place $vmName in desired location, multiple $vmLocation folders exist, check root folder" "Red"
        }
        Else {
            Out-Log "`n$vmName failed to deploy!" "Red"
            Foreach ($err in $Error) {
                Out-Log "$err" "Red"
            }
            $failDeploy += @($vmName)
        }
    }
}

Out-Log "`nAll Deployment Tasks Created" "Yellow"
Out-Log "`nMonitoring Task Processing" "Yellow"
Sleep 5

# When finsihed deploying, reconfigure new VMs
$totalTasks = $taskTab.Count
$runningTasks = $totalTasks
while($runningTasks -gt 0){
    $vmStatus = "[{0} of {1}] {2}" -f $runningTasks, $totalTasks, "Tasks Remaining"
	Write-Progress –Activity "Monitoring Task Processing" –Status $vmStatus –PercentComplete (100*($totalTasks–$runningTasks)/$totalTasks)
	Get-Task | % {
    If($taskTab.ContainsKey($_.Id) -and $_.State -eq "Success") {

      #Deployment completed
      $Error.Clear()
      $vmName = $taskTab[$_.Id]
      Out-Log "`n`nReconfiguring $vmName" "Yellow"
      $VM = Get-VM $vmName
      $VMconfig = $newVMs | Where {$_.Name -eq $vmName}
      
	  # Set CPU and RAM
      Out-Log "  + Setting vCPU and RAM" "Yellow"
      $VM | Set-VM –NumCpu $VMconfig.CPU –MemoryGB $VMconfig.RAM –Confirm:$false | Out-Null

      #Configure Limit CPU (MHz) & RAM (GB)
      $VM | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemLimitMB $VMconfig.MemLimitMB -CpuLimitMhz $Vmconfig.CpuLimitMhz | Out-Null
      
	  # Set port group on virtual adapter
      Out-Log "  + Setting Port Group" "Yellow"
      If ($VMconfig.NetType -match "vSS") {
		  $network = @{
			  'NetworkName' = $VMconfig.network
			  'Confirm' = $false
		  }
	  }
      Else {
		  $network = @{
			  'Portgroup' = $VMconfig.network
			  'Confirm' = $false
		  }
	  }	  
	  $VM | Get-NetworkAdapter | Set-NetworkAdapter @network | Out-Null

	  # Add additional disks if needed
      If ($VMConfig.Disk1 -gt 15) {
        Out-Log "  + Extending Disk 1" "Yellow"
        $VM | Get-HardDisk | Where-Object {$_.Name -eq "Hard Disk 1"} | Set-HardDisk -CapacityGB $VMConfig.Disk1 -Confirm:$false | Out-Null
      }
      If ($VMConfig.Disk2 -gt 1) {
        Out-Log "  + Adding Disk 2" "Yellow"
        $VM | New-HardDisk –CapacityGB $VMConfig.Disk2 –StorageFormat $VMConfig.DiskStorageFormat –Persistence persistent | Out-Null
      }
      If ($VMConfig.Disk3 -gt 1) {
        Out-Log "  + Adding Disk 3" "Yellow"
        $VM | New-HardDisk –CapacityGB $VMConfig.Disk3 –StorageFormat $VMConfig.DiskStorageFormat –Persistence persistent | Out-Null
      }
      If ($VMConfig.Disk4 -gt 1) {
        Out-Log "  + Adding Disk 4" "Yellow"
        $VM | New-HardDisk –CapacityGB $VMConfig.Disk4 –StorageFormat $VMConfig.DiskStorageFormat –Persistence persistent | Out-Null
      }
      
	  # Boot VM
	  If ($VMconfig.Boot -match "true") {
      	$VM | Start-VM –EA SilentlyContinue | Out-Null
        }
        $taskTab.Remove($_.Id)
        $runningTasks
      If ($Error.Count -ne 0) {
        Out-Log "=> $vmName completed with errors" "Red"
        Foreach ($err in $Error) {
            Out-Log "$Err" "Red"
        }
        $failReconfig += @($vmName)
      }
      Else {
        Out-Log "=> $vmName is Complete" "Green"
        $successVMs += @($vmName)
      }
    }
    elseif($taskTab.ContainsKey($_.Id) -and $_.State -eq "Error"){

      # Deployment failed
      $failed = $taskTab[$_.Id]
      Out-Log "`n$failed failed to deploy!`n" "Red"
      $taskTab.Remove($_.Id)
      #$runningTasks
      $failDeploy += @($failed)
    }
  }
}
 
#——————————————————————–
# Close Connections
 
#Disconnect-VIServer –Server $vcenter –Force –Confirm:$false
 
#——————————————————————–
# Outputs
 
Out-Log "`n**************************************************************************************"
Out-Log "Processing Complete" "Yellow"
 
If ($successVMs -ne $null) {
    Out-Log "`nThe following VMs were successfully created:" "Yellow"
    Foreach ($success in $successVMs) {Out-Log "$success" "Green"}
}
If ($failReconfig -ne $null) {
    Out-Log "`nThe following VMs failed to reconfigure properly:" "Yellow"
    Foreach ($reconfig in $failReconfig) {Out-Log "$reconfig" "Red"}
}
If ($failDeploy -ne $null) {
    Out-Log "`nThe following VMs failed to deploy:" "Yellow"
    Foreach ($deploy in $failDeploy) {Out-Log "$deploy" "Red"}
}
 
$finishtime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
Out-Log "`n`n"
Out-Log "**************************************************************************************"
Out-Log "$scriptName`t`t`t`t`tFinish Time:`t$finishtime"
Out-Log "**************************************************************************************"