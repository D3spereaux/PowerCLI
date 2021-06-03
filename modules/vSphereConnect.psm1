function VSphereConnect {
    # Address of the vSphere server
    $server = Read-Host -Prompt 'Enter your vSphere IP/hostname'

    # Set vSphere credentials
    # Fetch username input (from above) and request password from user 
    $credentials=Get-Credential -Message "Please enter your vCenter credentials"

    # Connect to vSphere
    Connect-VIServer -Server $server -Credential $credentials -ErrorAction Inquire > $null

    # Get a list of servers you are connected to
    $serverList = $global:DefaultVIServer

    # Check the list of connected servers
    # If the list if NULL, report error and exit
    if($serverList -eq $null) 
    {
       write-host ">>> >>> ERROR: Unable to connect to $server. Null List."
       BREAK
    } 
    else 
    {
        # Loop the list of connected servers to check connection
        foreach ($server in $serverList) 
        {       
            $serverName = $server.Name
            if ($serverName -eq $server)
            {
                write-Host ">>> Connected to $serverName"
            } 
            else 
            {
                write-host ">>> ERROR: Unable to connect to $server. No Server Match."
                BREAK
            }
        }
    }
}