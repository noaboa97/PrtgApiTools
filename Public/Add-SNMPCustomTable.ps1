
function Add-SNMPCustomTable {
    <#
    .SYNOPSIS
    Creates a new PRTG SNMP Custom Table Sensor
    .DESCRIPTION
    Creates a new PRTG SNMP Custom Table Sensor
    Currently there is no function and the script needs a lot of tweeking
    This script is used to create a snmp custom table sensor for N&S for a Meraki firewall

    This Script is dependent on PrtgAPI PowerShell Module from lordmilko

    .PARAMETER None
    Currently there are no Parameters for this function

    .OUTPUTS
    PrtgAPI Sensor which was created

    .EXAMPLE
    $channel = @{
        "name" = "Traffic IN"
        "type" = "diff"
        "unit" = "BytesBandwidth"
        "valuelookup" = ""
        "customunit" = ""
        "column" = "ifHCInOctets"
    }

    $channel2 = @{
        "name" = "Traffic OUT"
        "type" = "diff"
        "unit" = "BytesBandwidth"
        "valuelookup" = ""
        "customunit" = ""
        "column" = "ifHCOutOctets"
    }

    $Channels = @($channel, $channel2)

    Add-SnmpCustomTable -device $device -rowname "port2" -sensorname "port2 / INET" -SnmpTableOid "1.3.6.1.2.1.31.1.1" -ColumnIdentifier "ifName" -Channels $Channels


    .NOTES
    Version: 0.1
    CreateDate:  20.11.2023
    Author:     Noah Li Wan Po
    ModifyDate: 20.11.2023
    ModifyUser: Noah Li Wan Po
    Purpose/Change: Initial development

    Tested with PRTG Version 23.4.88.1429+
    #>
    Param (
        [parameter(valuefrompipeline = $true, HelpMessage = "PRTG Device Object", Position = 0)]
        [PrtgAPI.Device]$device,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter row name", Position = 1)]
        [string]$rowname,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter sensor name", Position = 2)]
        [string]$sensorname,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter SNMP Table OID", Position = 3)]
        [string]$SnmpTableOid,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter the column to identify each row", Position = 3)]
        [string]$ColumnIdentifier,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter SNMP Table OID", Position = 3)]
        [array]$Channels,
        [parameter(valuefrompipeline = $true, HelpMessage = "Enter logfile path", Position = 4)]
        [string]$logfile = "C:\Scripts\PRTG\Logs\LOG_Add-SNMPCustomTable.txt"

    )

    If (!(Test-Path $logfile)) {New-Item -Path $logfile -Force}

    # defining port number
    # $number = 2

    # get the device
    # $device = get-device -id $device.id

    # generate sensor parameters of type snmpcustomtable needs the queryparameters snmp table oid 
    $param = $device | New-SensorParameters -RawType snmpcustomtable -QueryParameters @{ "tableoid" = $SnmpTableOid} 

    # name of the new sensor
    $param.Name = $sensorname

    if($null -eq $rowname){
        $param.snmptable__check = $param.targets.snmptable__check
    }else {
        # row to choose from the table and filter by name 
        $param.snmptable__check = $param.targets.snmptable__check | where {$_.name -eq $rowname}
    }

    # column to choose. We use all. Never had a use case where I need to filter
    $param.columns__check= $param.targets.columns__check

    # Identification Column
    $param.identcolumn = $param.Targets.identcolumn | Where-Object {$_.name -eq $ColumnIdentifier}

    $i = 1

    foreach($channel in $channels){

        if($i -ne 1){
            $param."usechannel$i" = 1
        }

        # name of the first channel
        $param."channel$($i)name"  = $channel.name

        # snmptype in webinterface it's called value type possible values: float=Absolute (float),diff=delta (counter),abs=(unsigned integer),sign=Absolute (signed integer) 
        $param."channel$($i)snmptype" = $channel.type

        # Channel Unit the see options check the dropdown in the webinterface of PRTG 
        $param."channel$($i)unit" = $channel.unit

        # Column which value to show as sensor
        $param."channel$($i)column" = $param.Targets."channel$($i)column" | Where-Object {$_.Name -eq $channel.column}

        $i++
    }

    # Add Sensor to device
    $device | Add-Sensor $param

}


