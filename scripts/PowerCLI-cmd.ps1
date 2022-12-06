###Check PSVersion
$PSVersionTable

###Install PowerCLI
Install-Module -Name VMware.PowerCLI -AllowClobber
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Import-Module VMware.VimAutomation.Core
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
###Install Import Excel
Install-Module -Name 'ImportExcel' -Scope CurrentUser
Get-Module -Name 'ImportExcel' -ListAvailable
#Config invalid cert
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
###Command
#Connect to vCenter
Connect-VIServer -server "vcenter.yourhost.local"
#Gather Information on ESXi Hosts
Get-VMHost
Get-VMHost | format-list -Property State,LicenseKey,Version
#Inspecting VMs
Get-VM
Get-VMHost -Name 10.10.16.12 | Get-VM
#Inspecting Virtual Switches
Get-VirtualSwitch | fl
#Finding VMs Attached to a Virtual Network
Get-VirtualPortGroup
#List all VMs match with DSwitch Name
Get-VM | Where-Object { ($PSItem | Get-NetworkAdapter | where {$_.networkname -match "VLAN_Internet_104"})}
#Getting OS version Information
Get-VM | 
      Sort-Object -Property Name |
      Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") |
      Select-Object -Property Name, @{N="Configured OS";E={$_.Config.GuestFullName}}, @{N="Running OS";E={$_.Guest.GuestFullName}}
#Creating CSV Reports
Get-VM | Sort-Object -Property Name | Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") |
Select -Property Name, @{N="Configured OS";E={$_.Config.GuestFullName}}, @{N="Running OS";E={$_.Guest.GuestFullName}} | 
Export-CSV C:\report.csv -NoTypeInformation
#Inspecting Virtual Hard Disks
Get-VM -Name Demo-PowerCLI | Get-HardDisk | Format-List
#Inspecting Virtual Network Adapters
Get-NetworkAdapter -VM Demo-PowerCLI

##Running PowerShell Scripts in VMs with Invoke-VMScript
Invoke-VMScript -VM Demo-PowerCLI -ScriptText "dir C:\"
##
$script = 'Get-Disk'
$guestCredential = Get-Credential
Invoke-VMScript -ScriptText $script -VM khoadd -GuestCredential $guestCredential  -ScriptType Powershell
#Get-View
Get-View -ViewType VirtualMachine -Filter @{"Name" = "Demo-PowerCLI"}
