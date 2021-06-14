# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

#Get list VM PowerOn Usage MHz Realtime
$starttime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
Write-Host "List VMs IP Address has powered on: ($starttime)"
Get-VM -PipelineVariable vm | where{$_.Guest.Nics.IpAddress} | Get-NetworkAdapter |
Select @{N='VM';E={$vm.Name}},Name,

   @{N=”IP Address”;E={$nic = $_; ($vm.Guest.Nics | where{$_.Device.Name -eq $nic.Name}).IPAddress -join '|'}},

  MacAddress