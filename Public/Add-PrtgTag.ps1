function Add-PrtgTag{
    <#
.SYNOPSIS
    Adds a tag to a specified PRTG object (Probe, Group, Device, or Sensor).

.DESCRIPTION
    This function allows the user to add a custom tag to a PRTG object using PrtgAPI. 
    The object can be passed directly through the pipeline or determined by name and type.
    The tag is appended to the existing tag list and updated using Set-ObjectProperty.

.PARAMETER Type
    Specifies the type of PRTG object to target: Probe, Group, Device, or Sensor.

.PARAMETER Name
    The name of the PRTG object. Used to resolve the object if not passed via pipeline.

.PARAMETER Tag
    The tag to be added to the specified PRTG object.

.PARAMETER InputObject
    The PRTG object to modify. Can be piped into the function.

.EXAMPLE
    Add-PrtgTag -Type Device -Name "Firewall-01" -Tag "critical"

.EXAMPLE
    Get-Device "Firewall-01" | Add-PrtgTag -Tag "critical"

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
        [parameter(Mandatory, ParameterSetName="Normal")]
        [parameter(ParameterSetName="Pipeline")]
        [ValidateSet("Group","Probe","Device","Sensor")]
        [string]$Type,

        [parameter(ParameterSetName="Pipeline")]
        [parameter(Mandatory, ParameterSetName="Normal", HelpMessage = "Name of the Probe, Group, Device or Sensor", Position = 0)]
        [string]$name,

        [parameter(ParameterSetName="Pipeline")]
        [parameter(Mandatory, ParameterSetName="Normal", HelpMessage = "Tagname", Position = 1)]
        [string]$tag,

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
        $tags.add($tag) | out-null
        $InputObject | Set-ObjectProperty -Tags $tags

        Switch($InputObject.type){
            "Probe" {$obj = Get-Probe $InputObject.name}
            "Group" {$obj = Get-Group $InputObject.name}
            "Device"{$obj = Get-Device $InputObject.name}
            "Sensor"{$obj = Get-Sensor $InputObject.name}
        }

        If($obj.tags -contains $tag){
            Write-Host "Tag: $tag added to $($obj.name)"
        }
    }

}