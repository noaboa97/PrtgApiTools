# PrtgApiTools extends PrtgApi from Lordmilko with wrappe functions and functionality that does not exist.
 
 
 
 ## Functions
Currently it provides the following functions
| Function  | Description   | Type   |
| ------------- | ------------- |:------:|
| Add-PrtgTag | Adds a tag to a specified PRTG object (Probe, Group, Device, or Sensor). | PowerShell Function |
| Add-SNMPCustomTable | Creates a new PRTG SNMP Custom Table Sensor | PowerShell Function |
| Check-PrtgLogin |   | PowerShell Function |
| Find-PrtgUser | Retreives one or multiple PRTG user accounts with settings | PowerShell Function |
| Get-ObjectAccessRights | Retrieves and displays access rights for a specified PRTG object. | PowerShell Function |
| Get-PrtgGroupAccessRights | Retrieves the effective access rights for all user groups on a specified PRTG group object.
This function is depreciated. Use Get-ObjectAccessRights | PowerShell Function |
| Get-PrtgUser | Retreives all PRTG user accounts with basic information | PowerShell Function |
| Get-PrtgUserGroups | Retreives all PRTG usergroups accounts with basic information | PowerShell Function |
| New-PrtgUsergroup | Creates a new user group in PRTG with optional Active Directory integration and user access settings. | PowerShell Function |
| Remove-PrtgTag | Removes a specific tag or all tags from a PRTG object such as Probe, Group, Device, or Sensor. | PowerShell Function |
| Replace-PrtgTag | Replaces an existing tag with a new tag on a specified PRTG object (Probe, Group, Device, or Sensor). | PowerShell Function |
| Set-ObjectAccessRights | Sets custom access rights on a PRTG object, breaking inheritance if needed. | PowerShell Function | 
 
### Add-PrtgTag
#### SYNTAX
``` powershell
Add-PrtgTag
   [-Type <String>]
   [-name <String>]
   [-tag <String>]
   -InputObject <SensorOrDeviceOrGroupOrProbe>
   -Type <String>
   [-name] <String>
   [-tag] <String>
   [-InputObject <SensorOrDeviceOrGroupOrProbe>]
```

#### Examples

``` powershell
Add-PrtgTag -Type Device -Name "Firewall-01" -Tag "critical"
    
Get-Device "Firewall-01" | Add-PrtgTag -Tag "critical"
```

### Add-SNMPCustomTable
#### SYNTAX
``` powershell
Add-SNMPCustomTable
   [[-device] <Device>]
   [-rowname] <String>
   [-sensorname] <String>
   [-SnmpTableOid] <String>
   [-ColumnIdentifier] <String>
   [-Channels] <Array>
   [[-logfile] <String>]
```

#### Examples

``` powershell
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
```

### Check-PrtgLogin
#### SYNTAX
``` powershell
Check-PrtgLogin
```

#### Examples

``` powershell
 
```

### Find-PrtgUser
#### SYNTAX
``` powershell
Find-PrtgUser
   [-Id] <Int32>
   [-Displayname] <String>
```

#### Examples

``` powershell
$result = Find-PrtgUser 100
    
$result = Find-PrtgUser -id 100
    
$result = Find-PrtgUser "PRTG System Administrator"
    
$result = Find-PrtgUser -DisplayName "PRTG System Administrator"
    
100, 2240 | Find-PrtgUser
    
Get-PrtgUser | Find-PrtgUser
```

### Get-ObjectAccessRights
#### SYNTAX
``` powershell
Get-ObjectAccessRights
   [-object] <PrtgObject>
   [-reloadusergroups <Boolean>]
```

#### Examples

``` powershell
Get-Device "Firewall01" | Get-ObjectAccessRights
    
$sensor = Get-Sensor -Id 12345
Get-ObjectAccessRights -Object $sensor
```

### Get-PrtgGroupAccessRights
#### SYNTAX
``` powershell
Get-PrtgGroupAccessRights
   [-group] <PrtgObject>
```

#### Examples

``` powershell
Get-Group -Id 1234 | Get-PrtgGroupAccessRights
    
$group = Get-Group "Production Servers"
Get-PrtgGroupAccessRights -Group $group
```

### Get-PrtgUser
#### SYNTAX
``` powershell
Get-PrtgUser
   [-detailed <>]
```

#### Examples

``` powershell
$result = Get-PrtgUser
    
$result = Get-PrtgUser -detailed
```

### Get-PrtgUserGroups
#### SYNTAX
``` powershell
Get-PrtgUserGroups
```

#### Examples

``` powershell
$result = Get-PrtgUserGroups
```

### New-PrtgUsergroup
#### SYNTAX
``` powershell
New-PrtgUsergroup
   [-name] <String>
   [[-isadmingroup] <Int32>]
   [[-defaulthome] <String>]
   [-isadgroup <Int32>]
   [-adgroup <String>]
   [-usertype <Int32>]
   [-userack <Int32>]
   [-allowedsensorsmode <Int32>]
   [-ticketmode <Int32>]
```

#### Examples

``` powershell
New-PrtgUsergroup -Name "ReadOnly Users" -UserType 1 -UserAck 0
    
New-PrtgUsergroup -Name "IT-Admins" -IsAdminGroup 1 -IsADGroup 1 -ADGroup "DOMAIN\IT-Admins"
```

### Remove-PrtgTag
#### SYNTAX
``` powershell
Remove-PrtgTag
   -Type <String>
   [-name] <String>
   [-tag <String>]
   [-All <>]
   [-Type <String>]
   [-name <String>]
   [-tag <String>]
   -InputObject <SensorOrDeviceOrGroupOrProbe>
   [-All <>]
   -Type <String>
   [-name] <String>
   [-tag] <String>
   [-InputObject <SensorOrDeviceOrGroupOrProbe>]
   [-All <>]
```

#### Examples

``` powershell
Remove-PrtgTag -Type Device -Name "Firewall01" -Tag "network"
    
Get-Device "Firewall01" | Remove-PrtgTag -Tag "network"
    
Get-Sensor -Tags "deprecated" | Remove-PrtgTag -All
```

### Replace-PrtgTag
#### SYNTAX
``` powershell
Replace-PrtgTag
   -Type <String>
   [-name] <String>
   [-tag <String>]
   [-newtag <String>]
   [-Type <String>]
   [-name <String>]
   [-tag <String>]
   [-newtag <String>]
   -InputObject <SensorOrDeviceOrGroupOrProbe>
   -Type <String>
   [-name] <String>
   [-tag] <String>
   [-newtag] <String>
   [-InputObject <SensorOrDeviceOrGroupOrProbe>]
```

#### Examples

``` powershell
Replace-PrtgTag -Type Device -Name "Firewall01" -Tag "oldtag" -NewTag "newtag"
    
Get-Device "Firewall01" | Replace-PrtgTag -Tag "oldtag" -NewTag "newtag"
```

### Set-ObjectAccessRights
#### SYNTAX
``` powershell
Set-ObjectAccessRights
   [-object] <PrtgObject>
   [[-noinherit] <>]
```

#### Examples

``` powershell
Get-Device "Firewall01" | Get-ObjectAccessRights | Set-ObjectAccessRights
    
$obj = Get-Group "Web Servers"
$obj.accessrights[0].rights = "Full Access"
$obj | Set-ObjectAccessRights
```

