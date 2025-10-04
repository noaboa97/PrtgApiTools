<#
.SYNOPSIS
    Initializes the basic structure for a new PowerShell module including folders, base files, and helper scripts.

.DESCRIPTION
    This script should be placed inside a new folder named after the intended PowerShell module.
    It automates the setup of a module by performing the following:
    
    - Detects the module name from the folder structure.
    - Creates standard subfolders: `Public`, `Private`, and `Tools`.
    - Generates a `.psm1` file that auto-imports all `.ps1` files from the `Public` and `Private` folders.
    - Creates a `.psd1` module manifest file with default metadata.
    - Generates two utility scripts inside the `Tools` folder:
        - `Install-Module.ps1`: Installs the module into the user or system `$PSModulePath`.
        - `Update-Manifest.ps1`: Automatically updates the `FunctionsToExport` section in the `.psd1` file based on the scripts in the `Public` folder.
    - Finally, the script moves itself into the `Tools` folder after execution.

.PARAMETER (none)
    This script does not take any parameters and must be executed directly from within the new module root folder.

.EXAMPLE
    .\Create-NewModule.ps1
    # Creates the required folder structure and base files for the module in the current folder.

.NOTES
    Version: 0.3
    CreateDate:  09.05.2025
    Author:     Noah Li Wan Po
    ModifyDate: 12.05.2023
    ModifyUser: Noah Li Wan Po
    Purpose/Change: Initial development
#>

$array= $PSScriptRoot.split("\")
[array]::Reverse($array)
$ModuleName = $array[0] # Should be the parent folder name

$BasePath = $PSScriptRoot


    
# Create directorys in documents folder 
New-Item -ItemType Directory -Path "$BasePath\Public" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\Private" -Force | Out-Null
$ToolsPath = New-Item -ItemType Directory -Path "$BasePath\Tools" -Force


# CREATING PSM1
$psm1Path = "$BasePath\$ModuleName.psm1"

@'
#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error -Message ('Failed to import function {0}: {1}' -f $import.fullname, $_)
        }
    }

Export-ModuleMember -Function $Public.Basename
'@ | Set-Content -Path $psm1Path -Encoding UTF8

# CREATE PSD1 ####

$psd1Path = "$BasePath\$ModuleName.psd1"

# Change language to english
$CurrentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
   

New-ModuleManifest -Path $psd1Path `
    -RootModule "$ModuleName.psm1" `
    -Author "Noah Li Wan Po" `
    -ModuleVersion "1.0.0" `
    -FunctionsToExport @() `
    -PowerShellVersion "5.1" `

[System.Threading.Thread]::CurrentThread.CurrentUICulture = $CurrentUICulture


@'
function Test-WriteAccess {
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
'@ | Set-Content -Path "$ToolsPath\Install-Module.ps1" -Encoding UTF8

@'
[string]$ModuleRoot = "$PSScriptRoot\.."
[string]$ManifestFile = "$ModuleRoot\*.psd1"
[string]$PublicFolder = "$ModuleRoot\Public"

# Prüfen, ob Manifest existiert
if (-not (Test-Path -Path $ManifestFile)) {
    Write-Error "Manifestdatei '$ManifestFile' nicht gefunden."
    exit 1
}

# Funktionsnamen aus Public-Ordner ableiten
$functionNames = Get-ChildItem -Path $PublicFolder -Filter *.ps1 |
    Select-Object -ExpandProperty BaseName

if ($functionNames.Count -eq 0) {
    Write-Warning "Keine Public-Funktionen gefunden unter '$PublicFolder'."
    exit 1
}

# Neue Zeile erzeugen
$quotedNames = $functionNames | ForEach-Object { "`"$($_)`"" }
$newExportLine = "FunctionsToExport = @(" + ($quotedNames -join ", ") + ")"

# .psd1 als Text einlesen
$psd1Lines = Get-Content -Path $ManifestFile -Raw -Encoding UTF8 -ErrorAction Stop

# Alte Zeile ersetzen (auch wenn sie leer ist: FunctionsToExport = @())
$updatedContent = $psd1Lines -replace 'FunctionsToExport\s*=\s*@\([^\)]*\)', $newExportLine

# Überschreiben
Set-Content -Path $ManifestFile -Value $updatedContent -Encoding UTF8 -Force

Write-Host "Manifest wurde aktualisiert mit folgenden Funktionen:"
$functionNames | ForEach-Object { Write-Host " - $_" }
'@ | Set-Content -Path "$ToolsPath\Update-Manifest.ps1" -Encoding UTF8

Move-Item -Path $MyInvocation.MyCommand.Path -Destination $ToolsPath
