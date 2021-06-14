# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

$VLAN="Your Port Group Name"

#Get list VM PowerOn Usage MHz Realtime
$starttime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
Write-Host "List VMs IP Address has powered on: ($starttime)"
Get-VM -PipelineVariable vm | where{$_.Guest.Nics.IpAddress} | Get-NetworkAdapter | Where{$_.NetworkName -eq $VLAN} |
Select @{N='VM';E={$vm.Name}},Name, @{N=”IP Address”;E={$nic = $_; (($vm.Guest.Nics | Where{$_.Device.Name -eq $nic.Name}).IPAddress | Where{$_ -match '\.'}) -join ', '}}, MacAddress