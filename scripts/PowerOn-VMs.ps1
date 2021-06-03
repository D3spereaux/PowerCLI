# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

## Imports CSV file
$starttime = Get-Date –uformat "%I:%M:%S %d-%m-%Y"
Write-Host "Powering On the following VMs: ($starttime)"
Import-Csv "D:\Studying\PowerCLI\scripts\DeployVM.csv" -UseCulture | %{
## Power On VM
    Get-VM $_.Name| Where {$_.PowerState -eq "PoweredOff"} | Start-VM -Confirm:$false  | Select-Object Name, PowerState
}