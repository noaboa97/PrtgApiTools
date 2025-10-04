function New-PrtgUsergroup{
    <#
.SYNOPSIS
    Creates a new user group in PRTG with optional Active Directory integration and user access settings.

.DESCRIPTION
    This function sends a multipart/form-data POST request to the PRTG Core Server to create a new user group.
    It supports both local and AD-linked groups, allows specifying default homepage, administrative rights, user type,
    alarm acknowledgment permissions, sensor creation permissions, and ticket system access.

.PARAMETER Name
    The name of the user group to be created. Mandatory.

.PARAMETER IsAdminGroup
    Specifies whether the user group has administrative rights. 1 for yes, 0 for no (default: 0).

.PARAMETER DefaultHome
    The default homepage URL for members of this user group. Default: "/welcome.htm".

.PARAMETER IsADGroup
    Indicates if this is an Active Directory-integrated group. 1 for AD group, 0 for local group (default: 0).

.PARAMETER ADGroup
    The name of the corresponding AD group (only applicable if IsADGroup is set to 1).

.PARAMETER UserType
    Type of user: 0 = read/write (default), 1 = read-only.

.PARAMETER UserAck
    Indicates if users can acknowledge alarms: 0 = no (default), 1 = yes.

.PARAMETER AllowedSensorsMode
    Sensor creation mode: 0 = all sensors (default), 1 = restricted sensors only.

.PARAMETER TicketMode
    Access to ticket system: 0 = cannot use (default), 1 = can use.

.EXAMPLE
    New-PrtgUsergroup -Name "ReadOnly Users" -UserType 1 -UserAck 0

.EXAMPLE
    New-PrtgUsergroup -Name "IT-Admins" -IsAdminGroup 1 -IsADGroup 1 -ADGroup "DOMAIN\IT-Admins"

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial creation of user group provisioning function for PRTG with support for AD integration
#>

    [CmdletBinding()]
    Param (
            [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "PRTG groupname", Position = 0)]
            [string]$name,
            [parameter(valuefrompipeline = $true, HelpMessage = "Administrative Rights", Position = 1)]
            [int]$isadmingroup = 0,
            [parameter(valuefrompipeline = $true, HelpMessage = "Home Page URL", Position = 2)]
            [string]$defaulthome = "/welcome.htm",
            [parameter(valuefrompipeline = $true, HelpMessage = "Use Active Directoriy integration")]
            [int]$isadgroup = 0,
            [parameter(valuefrompipeline = $true, HelpMessage = "AD Group name")]
            [string]$adgroup,
            [parameter(valuefrompipeline = $true, HelpMessage = "Read/write user (0) or Read-only user (1)")]
            [int]$usertype = 0,
            [parameter(valuefrompipeline = $true, HelpMessage = "cannot acknowledge alarms (default) (0) or acknowledge alarms (1)")]
            [int]$userack = 0,
            [parameter(valuefrompipeline = $true, HelpMessage = "can create all sensors (0) or can only create certain sensors")]
            [int]$allowedsensorsmode = 0,
            [parameter(valuefrompipeline = $true, HelpMessage = "cannot use the ticket system (0) or can use the ticket system")]
            [int]$ticketmode = 0
            
        )

    $sessions = Get-prtgclient

    $Header = @{}
    $Header["X-Requested-With"] = "XMLHttpRequest"   

    $oname                     = New-Object PSCustomObject @{name_                   = $name}
    $oisadmingroup             = New-Object PSCustomObject @{isadmingroup_           = $isadmingroup}
    $odefaulthome              = New-Object PSCustomObject @{defaulthome_            = $defaulthome}
    $oisadgroup                = New-Object PSCustomObject @{isadgroup_              = $isadgroup}
    $ossogroupaccessclaim      = New-Object PSCustomObject @{ssogroupaccessclaim_    = ""}
    $oadgroup                  = New-Object PSCustomObject @{adgroup_                = $adgroup}
    $ousertype                 = New-Object PSCustomObject @{adusertype_             = $usertype}
    $ouserack                  = New-Object PSCustomObject @{aduserack_              = $userack}
    $oallowedsensorsmode       = New-Object PSCustomObject @{allowedsensorsmode_     = $allowedsensorsmode}
    $oallowedsensors           = New-Object PSCustomObject @{allowedsensors_         = 1}
    $oticketmode               = New-Object PSCustomObject @{ticketmode_             = $ticketmode}
    $ousers                    = New-Object PSCustomObject @{users_                  = 1}
    $oobjecttype               = New-Object PSCustomObject @{objecttype              = "usergroup"}
    $oid                       = New-Object PSCustomObject @{id                      = "new"}
      
    $Objects = New-Object 'System.Collections.Generic.List[pscustomobject]'
    $Objects.Add($oname)
    $Objects.Add($oisadmingroup)
    $Objects.Add($odefaulthome)
    $Objects.Add($oisadgroup)
    $Objects.Add($ossogroupaccessclaim)
    $Objects.Add($oadgroup)
    $Objects.Add($ousertype)
    $Objects.Add($ouserack)
    $Objects.Add($oallowedsensorsmode)
    $Objects.Add($oallowedsensors)
    $Objects.Add($oticketmode)
    $Objects.Add($ousers)
    $Objects.Add($oobjecttype)
    $Objects.Add($oid)
    $Objects.Add($otargeturl)

    $objects

    $boundary = [System.Guid]::NewGuid().ToString(); 
    $LF = "`r`n";

    $body = ""

    foreach($o in $Objects){
        $bodyLine = ( 
            "------$boundary",
            "Content-Disposition: form-data; name=`"$($o.keys)`"",
            "",
            "$($o.Values)$LF"           
        ) -join $LF 

        $body = $body + $bodyline
    }

    $body = $body + "------$boundary--$LF"

    $response = Invoke-restmethod -Uri "$($sessions.Server)/editsettings?username=$($sessions.UserName)&passhash=$($sessions.PassHash)" -contenttype "multipart/form-data; boundary=------$boundary" -Method POST -Headers $Header -Body $Body

    return $response

}