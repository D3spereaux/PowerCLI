# Get Root Directory
$pwd = $PSScriptRoot
Invoke-Expression $pwd\Connect-vCenter.ps1

## Imports CSV file
$starttime = Get-Date
Write-Host "Powering Off the following VMs: ($starttime)"
Import-Csv "D:\Studying\PowerCLI\scripts\DeployVM.csv" -UseCulture | %{
## Power Off VM
    Get-VM $_.Name| Where {$_.PowerState -eq "Suspend"} | Stop-VM -Confirm:$false `
    | Select-Object Name, PowerState
    Remove-VM $_.Name -Confirm:$false | Out-Null
}