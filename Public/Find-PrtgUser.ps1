
function Find-PrtgUser {
    <#
    .SYNOPSIS
    Retreives one or multiple PRTG user accounts with settings

    .DESCRIPTION
    Retreives one or multiple PRTG user accounts with settings by scraping the returned HTML of the PRTG Webinterface edit user site
    Afaik there is no API v1 Endpoint for that.

    This Function is dependent on PrtgAPI PowerShell Module from lordmilko

    Known bug: Requesting account information of the user that is used to authenticate to PRTG will show Active: False even though the user is active and not paused


    .PARAMETER Id
    PRTG user id 
    Unfortunatly it's not displayed the webinterface only in the URL.

    With PrtgAPI you can list all users like this
    get-object -Name Benutzer -Type System | get-object

    .PARAMETER Displayname
    PRTG displayname

    .OUTPUTS
    Array of PSCustomObject
    PSCustomobject

    .EXAMPLE
    $result = Find-PrtgUser 100      

    .EXAMPLE
    $result = Find-PrtgUser -id 100 

    .EXAMPLE
    $result = Find-PrtgUser "PRTG System Administrator"

    .EXAMPLE
    $result = Find-PrtgUser -DisplayName "PRTG System Administrator"

    .EXAMPLE
    100, 2240 | Find-PrtgUser

    .EXAMPLE
    Get-PrtgUser | Find-PrtgUser

    .NOTES
    Version: 1.0
    CreateDate:  13.10.2023
    Author:     Noah Li Wan Po
    ModifyDate: 15.10.2023
    ModifyUser: Noah Li Wan Po
    Purpose/Change: Initial function development
    #>

    [CmdletBinding()]
        Param (
                [Parameter(ValueFromPipelineByPropertyName = $true, valuefrompipeline = $true, mandatory = $true, HelpMessage = "PRTG UserID", Position = 0,ParameterSetName="Id")]
                [int]$Id,

                [Parameter(mandatory = $true, HelpMessage = "PRTG Displayname", Position = 1,ParameterSetName="Displayname")]
                [string]$Displayname

            )
    BEGIN{

        if(-not (Get-Module PrtgAPI)){
            Write-Error -Message "Please install PrtgAPI by Lordmilko Command: Install-Module PrtgAPI"
        }

        $session = Get-prtgclient
        if(-not $session){
            Write-Error -Message "Please login to a PRTG server first. Command: Connect-PrtgServer"
        }
        
        if($Displayname){
            Write-Verbose "Username provided - using PrtgAPI to determin userID"
            $id = (get-object -Name Users -Type System | get-object | Where-Object {$_.name -eq $Displayname}).id
        }

        $Header = @{}
        $Header["X-Requested-With"] = "XMLHttpRequest" 

        $useraccountlist = @()

    }
    PROCESS{

        Try{
            ### Gets the HTML Output of the edit user site
            $resp = Invoke-WebRequest -Uri  "https://$($session.server)/controls/edituser.htm?id=$id&tabid=1&username=$($session.UserName)&passhash=$($session.PassHash)" -Method Get -Headers $headers
        }catch{
            throw "An Error occured `n $_"
        }
            #### Parses the Radio Buttons List for the User Permissions
            $Usertype = $resp.Forms[0].Fields | Where-Object {$_.keys -like "usertype*"} | ForEach-Object {
                if($_.key -eq "usertype0" -and $_.value -eq 1){
                    [PSCustomObject]@{
                        Permission = "Read"
                        CanAcknowledge = [System.Convert]::ToBoolean([int]($resp.Forms[0].Fields["allowack1"]))
                        CanChangePassword = [System.Convert]::ToBoolean([int]($resp.Forms[0].Fields["allowpwchange1"]))
                    }
                } else {
                    [PSCustomObject]@{
                        Permission = "Read/Write"
                        CanAcknowledge = [System.Convert]::ToBoolean([int]($resp.Forms[0].Fields["allowack1"]))
                        CanChangePassword = [System.Convert]::ToBoolean([int]($resp.Forms[0].Fields["allowpwchange1"]))
                    }
                }
            }
            ####
        
            ##### Get Primary Group user is in
            $usergroups = $resp.ParsedHtml.getElementsByName("primarygroup_")[0] | select-object outertext,outerhtml,value,selected
            foreach($p in $usergroups){
                if($p.selected -eq $true){
                    $primarygroup = [PSCustomObject]@{
                    
                        Id = $p.value.split("|")[0]
                        Name = $p.value.split("|")[1]
                        DisplayType = $p.value.split("|")[4] | ForEach-Object {if($_ -eq 1){"PRTG (Administratoren)"} else {"PRTG"}}
                        
                    }
                }
            }
            ####
        
        
            #### Parses the additional groups table from the user edit page
            $table = $resp.ParsedHtml.getElementsByTagName("Table")
        
            # Check if the table is found
            if ($null -eq $table) {
                Write-Host "Didn't find HTML Table for the additional user groups"
                Write-Verbose "Table not found."
            } else {
                # Extract rows from the table
                $rows = $table[0].getElementsByTagName('tr')
        
                # Remove first row in the array - should be the title of the table
                # $rows.removenode[0]
        
                $grouplist = @()
        
                # Iterate through rows and extract data
                foreach ($row in $rows) {
                    if($row.innertext -ne "Name der Benutzergruppe" -and $row.innertext -ne "User Group Name" -and $row.innertext -notlike "*empty*" ){
                        $grouplist += $row.innerText
                    }
                    
                            
                }
            }
            ####
        
            ##### Creates the object to be returned - TO DO maybe create a proper class
            $useraccount = [PSCustomObject]@{
                Id = $id
                Username = $resp.Forms[0].Fields["login_"]
                Displayname = $resp.Forms[0].Fields["name_"]
                Email = $resp.Forms[0].Fields["email"]
                Usertype = $Usertype
                Primaryusergroup = $primarygroup
                Additionalgroups = $grouplist
                Active = [System.Convert]::ToBoolean([int]$resp.Forms[0].Fields["active1"])
                Autorefresh = [System.Convert]::ToBoolean([int]$resp.Forms[0].Fields["autorefreshtype1"])
                Autorefreshinterval = $resp.Forms[0].Fields["autorefreshinterval_"]
                HomepageURL = $resp.Forms[0].Fields["homepage_"]
                TicketChangeEmailNotification =  [System.Convert]::ToBoolean([int]$resp.Forms[0].Fields["ticketmail0"])
                FormFieldRaw = $resp.Forms[0].Fields
            }
            ####

            $useraccountlist += $useraccount
        
    }
    END{
        if($useraccountlist.count -lt 1){
            return $useraccount
        }else{
            return $useraccountlist
        }
            

    }
    
   

    

    

    

}