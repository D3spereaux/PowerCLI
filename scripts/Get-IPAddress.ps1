# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

#Get list VM PowerOn Usage MHz Realtime
$starttime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
Write-Host "List VMs IP Address has powered on: ($starttime)"
Get-VM | Where {$_.PowerState -eq "PoweredOn"} | `
Get-VMGuest | Sort-Object| Format-Table VM, IPAddress