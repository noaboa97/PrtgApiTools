function Remove-PrtgTag {
    <#
.SYNOPSIS
    Removes a specific tag or all tags from a PRTG object such as Probe, Group, Device, or Sensor.

.DESCRIPTION
    This function removes either a single tag or all tags from a specified PRTG object using PrtgAPI.
    It supports pipelining and explicit object retrieval via name and type.
    When using the `-All` switch, all tags will be removed from the object.
    Otherwise, the tag specified with `-Tag` will be removed from the object's tag list.

.PARAMETER Type
    The type of the PRTG object. Valid values are: Probe, Group, Device, Sensor. Mandatory when not using pipeline input.

.PARAMETER Name
    The name of the object (e.g., sensor name or device name). Mandatory if object is not passed via pipeline.

.PARAMETER Tag
    The name of the tag to remove. Mandatory unless `-All` is used.

.PARAMETER InputObject
    A PrtgAPI object (Sensor, Device, Group, or Probe). Can be passed via pipeline.

.PARAMETER All
    Switch to remove all tags from the object.

.EXAMPLE
    Remove-PrtgTag -Type Device -Name "Firewall01" -Tag "network"

.EXAMPLE
    Get-Device "Firewall01" | Remove-PrtgTag -Tag "network"

.EXAMPLE
    Get-Sensor -Tags "deprecated" | Remove-PrtgTag -All

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial creation of tag removal function using PrtgAPI
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

        [parameter(ParameterSetName="Normal")]
        [parameter(ParameterSetName="Pipeline",Mandatory,ValueFromPipeline, HelpMessage = "PrtgAPI Object")]
        [PrtgAPI.SensorOrDeviceOrGroupOrProbe]$InputObject,

        [switch]$All
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
            if($All){
                $InputObject | Set-ObjectProperty -Tags $null

            }else{
                $tags.remove($tag) | out-null
                $InputObject | Set-ObjectProperty -Tags $tags
            }

            Switch($InputObject.type){
                "Probe" {$obj = Get-Probe $InputObject.name}
                "Group" {$obj = Get-Group $InputObject.name}
                "Device"{$obj = Get-Device $InputObject.name}
                "Sensor"{$obj = Get-Sensor $InputObject.name}
            }

            If($obj.tags -notcontains $tag){
                Write-Host "Tag: $tag removed from $($obj.name)"
            }
    }

}