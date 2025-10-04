function Get-PrtgGroupAccessRights{
<#
.SYNOPSIS
    Retrieves the effective access rights for all user groups on a specified PRTG group object.
    This function is depreciated. Use Get-ObjectAccessRights

.DESCRIPTION
    This function inspects the raw access rights configuration of a PRTG group object and cross-references user group IDs 
    with their names using cached data from the PRTG object tree. It returns a readable table of all user or group entries 
    that have specific access levels on the given group, such as "Read", "Write", or "Full" access. Inherited rights are 
    also identified.

    This function is depreciated. Use Get-ObjectAccessRights

.PARAMETER Group
    The PRTG group object (of type [PrtgAPI.prtgObject]) for which access rights should be retrieved.
    Must be provided through the pipeline or explicitly via parameter.

.EXAMPLE
    Get-Group -Id 1234 | Get-PrtgGroupAccessRights

.EXAMPLE
    $group = Get-Group "Production Servers"
    Get-PrtgGroupAccessRights -Group $group

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial creation of function to map and display access rights of PRTG groups
#>

    [CmdletBinding()]
    Param (
            [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "PRTG groupname object", Position = 0)]
            [PrtgAPI.prtgObject]$group            
        )

    # Global variable only runs the first time the function is called in that session
    if($allobjects){}else{
        $global:allobjects = get-object -id -2 | get-object *
    }

    Write-Host "This function (Get-PrtgGroupAccessRights) is depreciated. Use Get-ObjectAccessRights" -ForegroundColor Yellow

    # Get all raw properties of the Prtg group and filters for the access rights groups and selects only the name and value
    $accessrights = ($group | get-objectproperty -Raw).PSObject.Properties | Where-Object {$_.name -like "accessrights_*"} | select-object name,value

    # Filters only for User and Groups 
    $ADUserOrGroup = $allobjects | Where-Object {$_.type -like "*UserOrGroup*"}

    # Creates the array to store the objects 
    $Report = @()

    foreach($accessright in $accessrights){

        # splits up the access right name because after the "_" there is the id of the user group
        $ugroupid = $accessright.name.split('_')[1]

        # searches in the variable for the id and writes the name in the variable
        $GroupName = $ADUserOrGroup | where-object id -EQ $ugroupid | select-object Name

        # Matching the access right value to human readable
        switch($accessright.value) {
                        "-1" {$rights = "Inherited (-1)";}
                        "0" {$rights = "None (0)";}
                        "100" {$rights = "Read (100)";}
                        "200" {$rights = "Write (200)";}
                        "400" {$rights = "Full (400)";}
                        default {$rights = "unknown value";}
            }
        
        # Creates the object with the group, id and rights
        $Object = New-Object PSCustomObject
        
        $Object | add-member -MemberType NoteProperty -Name "Name" -Value $Groupname.name
        $Object | add-member -MemberType NoteProperty -Name "Id" -Value $ugroupid
        $Object | add-member -MemberType NoteProperty -Name "Rights" -Value $rights

        <#$object = [PSCustomObject]@{                         
            Name        = $Groupname.name
            Id          = $ugroupid
            Rights      = $rights
        }#>
        # add the object to the report for 
        $report += $object

    }
        
        # Returns the report (whole list of all groups with their id and right)
        return $report
}

<#
accessgroup        1 = inherit vom parent group  
accessgroup        0 = don't inherit unless (-1)    
accessrights       1    
accessrightsrevert 0
#>