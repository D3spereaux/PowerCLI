clear-host
# Get Root Directory
$pwd = $PSScriptRoot
# Import the vSphere connect module from the module directory
Import-Module $pwd\..\modules\vSphereConnect
# Get a list of servers you are connected to
$serverlist = $global:DefaultVIServer
# Check the list of connected servers to the server
if($serverlist -eq $null) {
    Write-Host ">> Not connected to server."
    Write-Host ">> Attempting to connect now..."
    VSphereConnect
    }
Write-Host ">> List Server already connected:" 
Write-Host "$serverlist" -foreground Green `n