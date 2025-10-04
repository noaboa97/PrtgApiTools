function Get-PrtgUserGroups{
    <#
    .SYNOPSIS
    Retreives all PRTG usergroups accounts with basic information

    .DESCRIPTION
    Retreives all PRTG user groups with basic information by scraping the returned HTML table of the PRTG Webinterface user overview
    Afaik there is no API v1 Endpoint for that.

    This Function is dependent on PrtgAPI PowerShell Module from lordmilko

    .PARAMETER None
    Currently there are no Parameters for this function
    Maybe filtering in the future, but anyways would still need to parse the whole html

    .OUTPUTS
    Array of PSCustomObject

    .EXAMPLE
    $result = Get-PrtgUserGroups

    .NOTES
    Version: 1.1
    CreateDate:  20.09.2024
    Author:     Noah Li Wan Po
    ModifyDate: 20.09.2024
    ModifyUser: Noah Li Wan Po
    Purpose/Change: fixed bug, error when URL of PRTG server contained https://
    #>

    BEGIN{

        if(-not (Get-Module PrtgAPI)){
            Write-Error -Message "Please install PrtgAPI by Lordmilko Command: Install-Module PrtgAPI"
        }

        $session = Get-prtgclient
        if(-not $session){
            Write-Error -Message "Please login to a PRTG server first. Command: Connect-PrtgServer"
        }

        $Header = @{}
        $Header["X-Requested-With"] = "XMLHttpRequest" 

    }

    PROCESS{
        Try{
            if($session.server -like "https://*"){
                $response = Invoke-webrequest -Uri "$($session.server)/controls/table.htm?refreshable=true&tableid=grouptable&content=usergroups&columns=name%2Ctype%2Cmembers%2Cprimarygroup%2Cactivedirectorygroup%2Cssoclaim%2Ccheckbox&tools=delete%2Cedit&count=all&sortby=name&sortable=true&tabletitle=User%20Groups&varexpand=tabletitle%2C%20columns&links=true&_=1726850855796&username=$($session.UserName)&passhash=$($session.PassHash)" -Headers $Header 

            }else{
                $response = Invoke-webrequest -Uri "https://$($session.server)/controls/table.htm?refreshable=true&tableid=grouptable&content=usergroups&columns=name%2Ctype%2Cmembers%2Cprimarygroup%2Cactivedirectorygroup%2Cssoclaim%2Ccheckbox&tools=delete%2Cedit&count=all&sortby=name&sortable=true&tabletitle=User%20Groups&varexpand=tabletitle%2C%20columns&links=true&_=1726850855796&username=$($session.UserName)&passhash=$($session.PassHash)" -Headers $Header 

            }
            
        }catch{
            throw "An Error occured `n $_"
        }
        
        $htmldoc = $response.ParsedHtml

        # Find the table using the class attribute
        $table = $htmlDoc.getElementById('table_grouptable')

        # Check if the table is found
        if ($null -eq $table) {
            Write-Host "Table not found."
        } else {
            # Extract rows from the table
            $rows = $table.getElementsByTagName('tr') | where {$null -ne $_.classname}

            $UserGroupList = @()

            # Iterate through rows and extract data
            foreach ($row in $rows) {
                if($row.getElementsByTagName('td')[0].innerText){
                    $obj = [pscustomobject]@{

                        Id = $row.childNodes[0].children[0].id
                        DisplayName = $row.getElementsByTagName('td')[0].innerText.trimend()
                        Type = $row.getElementsByTagName('td')[1].innerText
                        Members = $row.getElementsByTagName('td')[2].innerText
                        # Also find IDs of User $row.getElementsByTagName('td')[2].childnodes | where {$_.search -like "*=*"} | foreach {$_.search.split("=")[1]; $_.innerText}
                        Primarygroup = $row.getElementsByTagName('td')[3].innerText
                        ActiveDirectory = $row.getElementsByTagName('td')[4].innerText
                        SSOClaim = $row.getElementsByTagName('td')[5].innerText
                        Server = $session.server.split(".")[0]

                    }
                }

                $UserGroupList += $obj
                
            }
        }
    }

    END{
        return $UserGroupList
    }
}