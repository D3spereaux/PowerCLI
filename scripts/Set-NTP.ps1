# PowerCLI Script for adding ntp to hosts
# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

#Set NTP server for all hosts
Get-VMHost | Add-VMHostNTPServer -NTPserver vn.pool.ntp.org

#Restart NTP services on host
Get-VMHost | Get-VMHostService | Where-Object {$_.key -eq "ntpd"} | Stop-VMHostService
Get-VMHost | Get-VMHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService

#Set service to start automatically
Get-VMHost | Get-VMHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on"