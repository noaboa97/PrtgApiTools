<#
.SYNOPSIS
    Installs the PowerShell module into the system or user module path.

.DESCRIPTION
    This script determines the name and path of the current module based on the script location.
    It performs the following actions:

    - Updates the module manifest using a helper script (`Update-Manifest.ps1`)
    - Determines whether write access exists to the system or user PowerShell module path
    - Removes existing module folders if present
    - Copies the module files (excluding the Tools folder) to the target module path
    - Prints the installation path if successful

    If no write access is available to either the system or user path, the script throws an error.

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial development
#>

function Test-WriteAccess {
    <#
.SYNOPSIS
    Tests whether the current user has write access to a specified path.

.DESCRIPTION
    This function attempts to create and immediately delete a temporary file in the given directory path.
    If both operations succeed, it returns $true, indicating write access is available.
    If an exception occurs, it returns $false.

.PARAMETER Path
    The file system path to check for write access.

.EXAMPLE
    Test-WriteAccess -Path "C:\Program Files"
    # Returns $true if write access is available, otherwise $false.

.NOTES
    Version:        0.1
    CreateDate:     12.05.2025
    Author:         Noah Li Wan Po
    ModifyDate:     12.05.2025
    ModifyUser:     Noah Li Wan Po
    Purpose/Change: Initial development
#>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $testFile = [System.IO.Path]::Combine($Path, [System.IO.Path]::GetRandomFileName())
        New-Item -Path $testFile -ItemType File -Force -ErrorAction Stop
        Remove-Item -Path $testFile -Force -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}


$array= $PSScriptRoot.split("\")
[array]::Reverse($array)
$ModuleName = $array[1] # Should be the parent folder name
$ModulePath = "$PSScriptRoot\..\*"

. "$PSScriptRoot\Update-Manifest.ps1"

#$ModuleName = "PrtgApiTools"
#$ModulePath = "h:\my documents\PrtgApiTools\Tools\.."


$System = Join-Path -Path $env:PSModulePath.Split(';')[0] -ChildPath $ModuleName
$User = Join-Path -Path $env:PSModulePath.Split(';')[1] -ChildPath $ModuleName

# To Do Ask / try elevation to install at system level.
if (Test-Path $System) {
    Remove-Item $System -Recurse -Force 
    $Target = $System
}elseif(Test-Path $User){
    Remove-Item $User -Recurse -Force 
    $Target = $User 
}else{

    if (Test-WriteAccess -Path $System) {
        $Target = $System
    } elseif (Test-WriteAccess -Path $User) {
        $Target = $User
    } else {
        Write-Error "No write access to either system or user path."
    }

}

if($Target){
    New-Item -Path $Target -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path $ModulePath -Destination $Target -Recurse -Exclude Tools, .*
    Write-Host "Modul installiert in: $Target" -ForegroundColor Green
}else{
    Write-Error "Target / destination path is empty"
}

