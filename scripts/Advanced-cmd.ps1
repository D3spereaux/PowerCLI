# Add PowerCLI Core snapin
If (!(Get-PSSnapin -name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
    Add-PSSnapin VMware.VimAutomation.Core}
 
# Add PowerCLI vCD snapin
If (!(Get-PSSnapin -name VMware.VimAutomation.Cloud -ErrorAction SilentlyContinue)) {
    Add-PSSnapin VMware.VimAutomation.Cloud}
 
# Add PowerCLI VDS snapin
If (!(Get-PSSnapin -name VMware.VimAutomation.VDS -ErrorAction SilentlyContinue)) {
    Add-PSSnapin VMware.VimAutomation.VDS}
 
# Connect to vCenter
Connect-VIServer vcenternameorip
# Disconnect from vCenter
Disconnect-VIServer vcenternameorip -Confirm:$False
 
# Connect to vCD
Connect-CIServer my.vcd.url
# Disconnect from vCD
Disconnect-CIServer my.vcd.url -Confirm:$False
 
# Connected VI Servers
$DefaultVIServers
# Number of Connected VI Servers
$DefaultVIServers.Count
 
# PowerCli Version
Get-PowerCLIVersion
 
# PowerCLI Configuration
Get-PowerCLIConfiguration
 
# VMHosts
# Change ESXi root password (or any other local user)
$VMHosts = Get-VMHost
ForEach ($VMHost in $VMHosts)
{
    $HostName = $VMHost.Name
    Connect-VIServer $HostName -User root -password P@ssw0rd
    Set-VMHostAccount -UserAccount root -password N3wPassword
    Disconnect-VIServer -Server $HostName -Confirm:$False
}
 
#Check Lockdown mode status
Get-VMHost | Select Name, @{Name=&quot;LockdownModeEnabled&quot;;Expression={($_).Extensiondata.Config.adminDisabled}} | ft -auto
 
#Disable Lockdown mode
Get-VMHost | %{($_ | get-view).ExitLockdownMode()}
 
#Enable Lockdown mode
Get-VMHost | %{($_ | get-view).EnterLockdownMode()}
 
# Start ESXi SSH Service
Get-VMHost | Foreach {Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq &quot;TSM-SSH&quot;} )}
 
# Stop ESXi SSH Service
Get-VMHost | Foreach {Stop-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq &quot;TSM-SSH&quot;} ) -Confirm:$false}
 
# View SSH Service state
Get-VMHost | Get-VMHostService | Where { $_.Key -eq &quot;TSM-SSH&quot; } | Select VMHost, Label, Policy, Running | ft -auto
 
#Enable SSH Server firewall exception
Get-VMHost | Get-VMHostFirewallException | Where {$_.Name -eq &quot;SSH Server&quot;} | Set-VMHostFirewallException -Enabled:$true
 
# Sets remote syslog server
Get-VMHost | Set-VMHostSysLogServer -SysLogServer &quot;udp://yoursysogserver:514&quot;
 
# Set Hostd logging level to info (default is verbose)
Get-VMHost | Get-AdvancedSetting -Name Config.HostAgent.log.level | Set-AdvancedSetting -Value &quot;info&quot; -Confirm:$false
 
# Set Vpxa logging level to info (default is verbose)(must be connected to VC)
Get-VMHost | Get-AdvancedSetting -Name Vpx.Vpxa.config.log.level | Set-AdvancedSetting -Value &quot;info&quot; -Confirm:$false
 
# Reset syslog service
$esxcli = Get-EsxCli -VMHost servername
$esxcli.system.syslog.reload()
 
# Sets ESXi syslog server firewall exception
Get-VMHost | Get-VMHostFirewallException |?{$_.Name -eq 'syslog'} | Set-VMHostFirewallException -Enabled:$true
 
# Backup ESXi Host Config
Get-VMHost MyESXiHost | Get-VMHostFirmware -BackupConfiguration -DestinationPath “F:\”
 
# Restore ESXi Host Config
Get-VMHost MyESXiHost | Set-VMHost -State Maintenance | Set-VMHostFirmware -Restore -SourcePath “F:\”
 
# Reset ESXi Host to defaults
Get-VMHost MyESXiHost | Set-VMHostFirmware -ResetToDefaults
 
# Gather Log Bundle from Host
Get-VMHost MyESXiHost | Get-Log -Bundle -DestinationPath “F:\”
 
# Gather Individual Logs
Get-VMHost MyESXiHost | Get-Log hostd | Select -ExpandProperty Entries | Out-File “F:\hostd.log”
Get-VMHost MyESXiHost | Get-Log vpxa | Select -ExpandProperty Entries | Out-File “F:\vpxa.log”
 
# Get the time on all ESXi hosts
Get-VMHost | Select Name,@{Name=&quot;Time&quot;;Expression={(get-view $_.ExtensionData.configManager.DateTimeSystem).QueryDateTime()}}
 
# Set the time on all ESXi hosts to the PowerCLI host's time
Get-VMHost | %{(Get-View $_.ExtensionData.configManager.DateTimeSystem).UpdateDateTime((Get-Date -format u)) }
 
# Rescan HBA Adapters
Foreach ($esx in Get-VMhost -Location ClusterName | sort Name) { $esx | Get-VMHostStorage -RescanAllHBA -rescanVMFS -refresh }
 
# Retrieve ntp servers
Get-VMHost | Select Name, @{N=&quot;NTPServer&quot;;E={$_ | Get-VMHostNtpServer}}, @{N=&quot;ServiceRunning&quot;;E={(Get-VmHostService -VMHost $_ | Where-Object {$_.key -eq &quot;ntpd&quot;}).Running}}
 
# Replace ntp servers on hosts
$oldntpservers = &quot;192.168.0.1&quot;,&quot;192.168.0.2&quot;
$newntpservers = &quot;192.168.0.20&quot;,&quot;192.168.0.21&quot;
Foreach($vmhost in Get-VMHost){
    #stop ntpd service
    $vmhost|Get-VMHostService |?{$_.key -eq &quot;ntpd&quot;}|Stop-VMHostService -Confirm:$false
    #remove ntpservers
    $vmhost|Remove-VMHostNtpServer -NtpServer $oldntpservers -Confirm:$false
    #add new ntpservers
    $vmhost|Add-VmHostNtpServer -NtpServer $newntpservers
    #start ntpd service
    $vmhost|Get-VMHostService |?{$_.key -eq &quot;ntpd&quot;}|Start-VMHostService
}
 
# Configure ntp service to start and stop with host
Get-VMHost | Get-VMHostService | ?{$_.key -eq &quot;ntpd&quot;} | Set-VMHostService -Policy &quot;on&quot; -confirm:$false
 
# Change DNS servers, domain name and search suffix
Get-VMHost | Get-VMHostNetwork | Set-VMHostNetwork -DnsAddress [DNS1 IP address],[DNS2 IP address] -Domain [Domain name] -SearchDomain [Search domain name]
 
# Enter Maintenance Mode
Get-VMHost | Set-VMHost -State Maintenance
 
#Add hosts to domain
Get-VMHost | Get-VMHostAuthentication | Set-VMHostAuthentication -Domain domain -User domainuser -Password password -JoinDomain -Confirm:$false
 
#Remove hosts from domain
Get-VMHost | Get-VMHostAuthentication | Set-VMHostAuthentication -LeaveDomain -Confirm:$false
 
#Check host domain status
Get-VMHost | Get-VMHostAuthentication | Select VMHost, DomainMembershipStatus, Domain | ft -auto
 
# Disconnect and Remove from VC
Get-VMHost | Set-VMHost-State Disconnected -Confirm:$false | Remove-VMHost -Confirm:$false
 
# Add into VC
Add-VMHost -Name $VMHost -Location $Location -Credential $cred -Force -Confirm:$false
 
# Join a cluster by moving an ESX host from one location to the cluster.
Move-Inventory -Item (Get-VMHost -Name esxHost) -Destination (Get-Cluster -Name clusterName)
 
 
 
# VM Stuff
# Get VM Information, Cluster, Host, Datastore
Get-VM | Select Name, @{N=”Cluster”;E={Get-Cluster -VM $_}},@{N=”ESX Host”;E={Get-VMHost -VM $_}},@{N=”Datastore”;E={Get-Datastore -VM $_}}
 
# Grab powered on Windows VMs in a particular folder
Get-Folder &quot;projects&quot; | Get-VM | Where-Object {$_.Guest.OSFullName -like &quot;*Windows*&quot; -and $_.PowerState -eq &quot;PoweredOn&quot;} | Sort Name
 
# Get VMs with CPU Reservations:
Get-VM | Get-VMResourceConfiguration | Where {$_.CpuReservationMhz -ne 0} | Select VM,CpuReservationMhz
 
# Get VMs with Memory Reservations:
Get-VM | Get-VMResourceConfiguration | Where {$_.MemReservationMB -ne 0} | Select VM,MemReservationMB
 
# Reset Memory resource limit to Unlimited
Get-VM | Get-VMResourceConfiguration | Where-Object {$_.MemLimitMB -ne &quot;-1&quot;} | Set-VMResourceConfiguration -MemLimitMB $null
 
# Reset CPU resource limit to Unlimited
Get-VM | Get-VMResourceConfiguration | Where-Object {$_.CpuLimitMhz -ne &quot;-1&quot;} | Set-VMResourceConfiguration -CPULimitMhz $null
 
# Reset both Memory and CPU resource limits to Unlimited (slow)
Get-VM | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemLimitMB $null -CpuLimitMhz $null
 
# Get Running VMs without VMware Tools Installed:
Get-View -ViewType “VirtualMachine” -Property Guest,name  -filter @{“Guest.ToolsStatus”=”toolsNotInstalled”;”Guest.GuestState”=”running”} | Select Name
 
# VMs Created Recently:
Get-VIEvent -maxsamples 10000 | Where {$_.Gettype().Name -eq “VmCreatedEvent”} | Select createdTime, UserName, FullFormattedMessage
 
# VMs Removed Recently:
Get-VIEvent -maxsamples 10000 | Where {$_.Gettype().Name -eq “VmRemovedEvent”} | Select createdTime, UserName, FullFormattedMessage
 
# List the last 10 VMs created, cloned or imported
Get-VIEvent -maxsamples 10000 |where {$_.Gettype().Name-eq &quot;VmCreatedEvent&quot; -or $_.Gettype().Name-eq &quot;VmBeingClonedEvent&quot; -or $_.Gettype().Name-eq &quot;VmBeingDeployedEvent&quot;} |Sort CreatedTime -Descending |Select CreatedTime, UserName,FullformattedMessage -First 10
 
# List last 5 VMs removed
Get-VIEvent -maxsamples 10000 | where {$_.Gettype().Name -eq &quot;VmRemovedEvent&quot;} | Sort CreatedTime -Descending | Select CreatedTime, UserName, FullformattedMessage -First 19
 
# List of the VM’s created over the last 14 days
Get-VIEvent -maxsamples 10000 -Start (Get-Date).AddDays(-14) | where {$_.Gettype().Name-eq &quot;VmCreatedEvent&quot; -or $_.Gettype().Name-eq &quot;VmBeingClonedEvent&quot; -or $_.Gettype().Name-eq &quot;VmBeingDeployedEvent&quot;} |Sort CreatedTime -Descending |Select CreatedTime, UserName,FullformattedMessage
 
# List of the VMs removed over the last 14 days
Get-VIEvent -maxsamples 10000 -Start (Get-Date).AddDays(-14) |where {$_.Gettype().Name-eq &quot;VmRemovedEvent&quot;} |Sort CreatedTime -Descending |Select CreatedTime, UserName,FullformattedMessage
 
# VMs with more than 2 vCPUs:
Get-VM | Where {$_.NumCPU -gt 2} | Select Name, NumCPU
 
# Check for invalid of inaccessible VMs:
Get-View -ViewType VirtualMachine | Where {-not $_.Config.Template} | Where{$_.Runtime.ConnectionState -eq “invalid” -or $_.Runtime.ConnectionState -eq “inaccessible”} | Select Name
 
# vMotion VM
Move-VM vm_name -Destination (Get-VMHost esxi_hostname)
 
# Storage vMotion VM
Get-VM vm_name | Move-VM -Datastore (Get-Datastore datastore_name)
 
# Create multiple new VMs from a template
$destCluster = Get-Cluster -Name Cluster01
$destDatastore = Get-DatastoreCluster -Name Cluster_Datastore
$destFolder = foldername
$sourceTemplate = Get-Template -Name W2K12_STD
1..6 | Foreach {New-VM -Name test0$_ -ResourcePool $destCluster -Location $destFolder -Template $sourceTemplate -Datastore $destDatastore -RunAsync}
 
 
 
# Storage
# Bulk storage moves
Get-VM -Datastore &lt;SourceDatastore1&gt; | Move-VM -Datastore &lt;TargetDatastore&gt; -runasync
 
# Delete all Snapshots with Certain Name:
Get-VM | Get-Snapshot | Where { $_.Name.Contains(“Consolidate”) } | Remove-Snapshot
 
# List all Snapshots:
Get-VM | Get-Snapshot | Select VM,Name,Description,Created
 
# List all RDM disks
Get-VM | Get-HardDisk -DiskType &quot;RawPhysical&quot;,&quot;RawVirtual&quot; | Select Parent,Name,DiskType,ScsiCanonicalName,DeviceName
 
# Search datastores for less than x free space
Get-Datastore | Where-Object {$_.freespaceMB -lt 100000}
Get-Datastore | Where-Object {$_.freespaceGB -lt 500 -and $_.Name -notlike &quot;*localstorage*&quot;}
 
# # of VMs per Datastore
Get-Datastore | Select Name, @{N=&quot;NumVM&quot;;E={@($_ | Get-VM).Count}} | Sort Name
 
# Mount datastore to psdrive
New-PSDrive -name &quot;mounteddatastore&quot; -Root \ -PSProvider VimDatastore -Datastore (Get-Datastore $datastore)
 
# Copy files to mounted datastore
Copy-Datastoreitem $patchLocation + $patch -Destination mounteddatastore:
 
# Delete file on mounted datastore
del mounteddatastore:$patch
 
# Unmount datastore from psdrive
Remove-PSDrive -name &quot;mounteddatastore&quot; -PSProvider VimDatastore
 
# Reload inaccessable VMs after a NFS/iSCSI outage
Get-View -ViewType VirtualMachine | ?{$_.Runtime.ConnectionState -eq &quot;invalid&quot; -or $_.Runtime.ConnectionState -eq &quot;inaccessible&quot;} | %{$_.reload()}
 
# Get Host HBA WWNs
Function Get-VMHostHbaWWN {
    param( $VMHost )
    $EsxHostHba = get-vmhosthba -VMHost $VMHost
    foreach( $hba in $EsxHostHba ){
        $WWN = &quot;{0:x}&quot; -f $hba.PortWorldWideName
        $outObj = New-Object PSObject
        $outObj | Add-Member -MemberType NoteProperty -Name Name -Value $VMHost
        $outObj | Add-Member -MemberType NoteProperty -Name WWNDec -Value $hba.PortWorldWideName
        $outObj | Add-Member -MemberType NoteProperty -Name WWNHex -Value $WWN
        $outObj | Add-Member -MemberType NoteProperty -Name Device -Value $hba.Device
        $outObj | Add-Member -MemberType NoteProperty -Name Type -Value $hba.Type
        $outObj | Add-Member -MemberType NoteProperty -Name Model -Value $hba.Model
        $outObj | Add-Member -MemberType NoteProperty -Name Status -Value $hba.Status
        $outObj
    }
}
 
 
 
# Networking
# Add Port Group “VLAN 500” with VLAN tag 500 to vSwitch1 on all hosts in a Cluster
Foreach ($esx in Get-VMHost -Location ClusterName) { $esx | Get-VirtualSwitch -Name vSwitch1 | New-VirtualPortGroup -Name &quot;VLAN500&quot; -VlanId 500 }
 
# Backup each vNetwork Distributed Switch not including the port groups
export-vdswitch $switch -Withoutportgroups -Description “Backup of $switch without port groups” -Destination “c:\vSphere\$switch.without_portgroups.$date.zip“
 
# Backup each vNetwork Distributed Switch including the port groups
export-vdswitch $switch -Description “Backup of $switch with port groups” -Destination “c:\vSphere\$switch.with_portgroups.$date.zip“
 
# Backup each port group individually
get-vdswitch $switch | Get-VDPortgroup | foreach { export-vdportgroup -vdportgroup $_ -Description “Backup of port group $($_.name)” -destination “c:\vSphere\$($_.name).portgroup.$date.zip“}
 
# Swing VMs from one port group to another
get-vm | get-networkadapter | where-object { $_.networkname -like &quot;OldPortGroup&quot; } | set-networkadapter -networkname &quot;NewPortGroup&quot; -Confirm:$false
 
 
 
# vCenter
# Gather vCenter Logons
Get-VIEvent -MaxSamples 100000 | ?{($_ -is [VMware.Vim.UserLoginSessionEvent]) -or ($_ -is [VMware.Vim.UserLogoutSessionEvent])} | %{
if ($_ -is [VMware.Vim.UserLoginSessionEvent]) {
  $strLoginOrLogout = &quot;logged in&quot;; $strSourceIP = $_.IpAddress
}
  else {
  $strLoginOrLogout = &quot;logged out&quot;; $strSourceIP = $null
  }
New-Object -TypeName PSObject -Property @{
UserName = $_.UserName
SourceIP = $strSourceIP
Time = $_.CreatedTime
Action = $strLoginOrLogout
}
} | Select UserName,SourceIP,Time,Action