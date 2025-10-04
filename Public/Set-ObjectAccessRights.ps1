function Set-ObjectAccessRights{
    <#
.SYNOPSIS
    Sets custom access rights on a PRTG object, breaking inheritance if needed.

.DESCRIPTION
    This function uses PrtgAPI to apply specific access rights to a Probe, Group, Device, or Sensor object.
    Access rights must first be gathered and optionally modified using the Get-ObjectAccessRights function.
    The function converts human-readable access levels into their corresponding PRTG backend values and updates
    all access rights at once using Set-ObjectProperty.
    Note: PRTG does not support partial updates—changing one right resets all others unless the full access rights set is submitted.

.PARAMETER Object
    The PRTG object (Probe, Group, Device, or Sensor) to which access rights will be applied.
    Must include the `.accessrights` property. Pipeline input is supported.

.PARAMETER NoInherit
    Optional switch to indicate that inheritance should be broken. This is **not implemented in the current function**
    but is acknowledged for future use if inheritance breaking should be triggered.

.EXAMPLE
    Get-Device "Firewall01" | Get-ObjectAccessRights | Set-ObjectAccessRights

.EXAMPLE
    $obj = Get-Group "Web Servers"
    $obj.accessrights[0].rights = "Full Access"
    $obj | Set-ObjectAccessRights

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial creation to apply access rights to PRTG objects using PrtgAPI
#>
    [CmdletBinding()]
    Param (
            [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "PRTG object", Position = 0)]
            [PrtgAPI.prtgObject]$object,
            [parameter(HelpMessage = "PRTG object", Position = 1)]
            [switch]$noinherit

        )
    Begin{
        Check-PrtgLogin
    }

    Process{
        if($null -ne $object.accessrights){
            Write-Verbose "Access Rights are available"
        }else{
            Write-Host "Access Rights are not available - please run Get-ObjectAccessRights first and edit .accessrights.rights of the groups you want to change the access rights for." -ForegroundColor Yellow
            return
        }

        # Get the raw values of the PRTG object where we can see the accessrights
        $objectraw = $object | Get-ObjectProperty -raw
        $accessrightsproperty = $objectraw.PSObject.Properties | Where-Object { $_.name -like "accessrights" }

        if($accessrightsproperty.value -eq 1){
            # defining the array
            $params = @{
                "accessgroup"="0"
                "accessrights_"="1"
            }
            
            # Loop through a single objects accessrights to add it to the array and set all accessrights. PRTG only accepts the whole list of all accessrights for all groups. single update will reset all others to inheried!!!
            foreach($ar in $object.accessrights){
                $rights = $ar.rights
            # 0 No Access
            # 100 Read Access 
            # 200 Write Access
            # 400 Full Access
                switch ($rights) {
                    "Inherited"      { $rightsRawValue = "-1"}
                    "No Access"       { $rightsRawValue = "0" }
                    "Read Access"     { $rightsRawValue = "100" }
                    "Write Access"     { $rightsRawValue = "200" }
                    "Full Access"     { $rightsRawValue = "400" }
                    Default { $rightsRawValue = "0"}
                }

                # Add the backend name of the group and the access level to the array
                $params.Add("$($ar.NameRawValue)",$rightsRawValue)
            }

            # Setting all the properties to the object
            $object | Set-ObjectProperty -RawParameters $params -Force

            return 
        }else{
            Write-Host "Access Rights are inherited from a parent object and thus are not active on this object. Use -noinherit to break inherintace from parent object and use access rights from the object you like to set." -ForegroundColor Yellow
        }
    }
}