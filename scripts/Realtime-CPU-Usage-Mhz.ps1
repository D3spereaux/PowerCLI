# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

#Get list VM PowerOn Usage MHz Realtime
$starttime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
Write-Host "List VMs usage MHz in realtime: ($starttime)"
Get-VM | Where {$_.PowerState -eq "PoweredOn"} | Sort-Object |
Get-Stat -Stat cpu.usagemhz.average -Realtime -MaxSamples 1 | 
where{$_.Instance -eq ''} | Select @{N='VMs';E={$_.Entity.Name}},Value, Unit
