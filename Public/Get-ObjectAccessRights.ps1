function Get-ObjectAccessRights{
    <#
.SYNOPSIS
    Retrieves and displays access rights for a specified PRTG object.

.DESCRIPTION
    This function retrieves the access rights set on a specific PRTG object (e.g., device, sensor, group, or probe). 
    It uses the raw object properties to extract access control values and maps user group IDs to their display names. 
    The access rights are formatted into readable permissions such as "Read Access", "Write Access", etc., 
    and returned as part of the object in a new `AccessRights` NoteProperty.

.PARAMETER Object
    The PRTG object (of type [PrtgAPI.prtgObject]) whose access rights should be retrieved.
    Can be provided via the pipeline.

.EXAMPLE
    Get-Device "Firewall01" | Get-ObjectAccessRights

.EXAMPLE
    $sensor = Get-Sensor -Id 12345
    Get-ObjectAccessRights -Object $sensor

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial development
#>
    [CmdletBinding()]
    Param (
            [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "PRTG object", Position = 0)]
            [PrtgAPI.prtgObject]$object,
            [bool]$reloadusergroups       
        )
    Begin{
        Check-PrtgLogin
        # Get all usergroups, is needed because accessrights only have the ID of the group and not the name
        if(-not $script:usergroups -or $reloadusergroups){
            Write-Host "Usergroups not yet requested - requesting..."
            $script:usergroups = Get-PrtgUserGroups
        }else{
            Write-Host "Usergroups already requested"

        }
    }

    Process{

        # Get the raw values of the PRTG object where we can see the accessrights
        $objectraw = $object | Get-ObjectProperty -raw
        $accessrightsproperty = $objectraw.PSObject.Properties | Where-Object { $_.name -like "accessrights" }

        if($accessrightsproperty.value -eq 1){
            # Filter for only the raw accessrights parameters
            $accessrightsraw = $objectraw.PSObject.Properties | Where-Object { $_.name -match "accessrights_" }

            # Create the accessrights array
            $accessrights = @()

            # Loop through a single objects accessrights to beautify the output 
            foreach($ar in $accessrightsraw){

                # Gets the usergroup id from the paramter name. the usergroup id is after the underscore _
                $usergroupid = $ar.name.split("_")[1]

                # Search für usergroup with id of the access rights to find the usergroup object
                $ug = $usergroups | Where-Object { $_.id -match "^$usergroupid$"}
            # 0 No Access
            # 100 Read Access 
            # 200 Write Access
            # 400 Full Access
                switch ($ar.value) {
                    ""      { $rights = "Inherited"}
                    -1      { $rights = "Inherited"}
                    0       { $rights = "No Access" }
                    100     { $rights = "Read Access" }
                    200     { $rights = "Write Access" }
                    400     { $rights = "Full Access" }
                    Default { $rights = "Unknown"}
                } 

                $arobject = [PSCustomObject]@{                         
                    Name        = $ug.displayname
                    Id          = $ug.id
                    Rights      = $rights
                    RightsRawValue = $ar.Value
                    NameRawValue = $ar.name
                }

                $accessrights += $arobject

            }

            $object | Add-Member -MemberType NoteProperty -Name AccessRights -Value $accessrights -force

            return $object | select-object name,accessrights
        }else{
            Write-Host "Access Rights are inherited from a parent object and thus are not active on this object. "
        }
    }
}