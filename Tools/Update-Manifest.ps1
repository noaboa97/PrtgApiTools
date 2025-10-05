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
$updatedContent | Out-File -FilePath $ManifestFile -Encoding UTF8 -Force -NoNewline

Write-Host "Manifest wurde aktualisiert mit folgenden Funktionen:"
$functionNames | ForEach-Object { Write-Host " - $_" }
