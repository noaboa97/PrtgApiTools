function Replace-PrtgTag {
<#
.SYNOPSIS
    Replaces an existing tag with a new tag on a specified PRTG object (Probe, Group, Device, or Sensor).

.DESCRIPTION
    This function retrieves a PRTG object via PrtgAPI (by name and type or through pipeline input),
    removes the specified tag if it exists, and adds a new tag using Set-ObjectProperty.
    If the old tag is not found, it won't be removed, but the new tag will still be added.

.PARAMETER Type
    The type of the PRTG object. Valid values: Probe, Group, Device, Sensor.
    Required when no InputObject is provided.

.PARAMETER Name
    The name of the PRTG object (e.g., sensor name, device name). Required if no InputObject is provided.

.PARAMETER Tag
    The existing tag to remove from the object.

.PARAMETER NewTag
    The new tag to add to the object.

.PARAMETER InputObject
    A PRTG object of type Sensor, Device, Group, or Probe from PrtgAPI. Can be provided via pipeline.

.EXAMPLE
    Replace-PrtgTag -Type Device -Name "Firewall01" -Tag "oldtag" -NewTag "newtag"

.EXAMPLE
    Get-Device "Firewall01" | Replace-PrtgTag -Tag "oldtag" -NewTag "newtag"

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Created function to replace tags on PRTG objects using PrtgAPI
#>


    [CmdletBinding()]
    Param (
        [parameter(Mandatory, ParameterSetName="Normal")]
        [parameter(ParameterSetName="Pipeline")]
        [parameter(Mandatory, ParameterSetName="All")]
        [ValidateSet("Group","Probe","Device","Sensor")]
        [string]$Type,

        [parameter(ParameterSetName="Pipeline")]
        [parameter(Mandatory, ParameterSetName="All", HelpMessage = "Name of the Probe, Group, Device or Sensor", Position = 0)]
        [parameter(Mandatory, ParameterSetName="Normal", HelpMessage = "Name of the Probe, Group, Device or Sensor", Position = 0)]
        [string]$name,

        [parameter(ParameterSetName="Pipeline")]
        [parameter(ParameterSetName="All")]
        [parameter(Mandatory, ParameterSetName="Normal", HelpMessage = "Tagname", Position = 1)]
        [string]$tag,

        [parameter(ParameterSetName="Pipeline")]
        [parameter(ParameterSetName="All")]
        [parameter(Mandatory, ParameterSetName="Normal", HelpMessage = "Tagname", Position = 1)]
        [string]$newtag,

        [parameter(ParameterSetName="Normal")]
        [parameter(ParameterSetName="Pipeline",Mandatory,ValueFromPipeline, HelpMessage = "PrtgAPI Object")]
        [PrtgAPI.SensorOrDeviceOrGroupOrProbe]$InputObject
    )
    Begin{

    }

    Process{

        If($null -eq $InputObject){
            Switch($type){
                "Probe" {$InputObject = Get-Probe $name}
                "Group" {$InputObject = Get-Group $name}
                "Device"{$InputObject = Get-Device $name}
                "Sensor"{$InputObject = Get-Sensor $name}
            }
        }
            $tags = ($InputObject | Get-ObjectProperty).tags
            if($null -eq $tags){[System.Collections.ArrayList]$tags = @()}else{$tags = [System.Collections.ArrayList]$tags }
            $tags.remove($tag) | out-null
            $tags.add($newtag) | out-null

            $InputObject | Set-ObjectProperty -Tags $tags

            Switch($InputObject.type){
                "Probe" {$obj = Get-Probe $InputObject.name}
                "Group" {$obj = Get-Group $InputObject.name}
                "Device"{$obj = Get-Device $InputObject.name}
                "Sensor"{$obj = Get-Sensor $InputObject.name}
            }

            If($obj.tags -notcontains $tag){
                Write-Host "Tag: $tag replaced with $newtag from $($obj.name)"
            }
    }

}