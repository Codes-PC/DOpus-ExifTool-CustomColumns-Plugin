Function Info($msg) {
    Write-Host -ForegroundColor DarkGreen "`nINFO: $msg`n"
  }

Function Error($msg) {
  Write-Host `n`n
  Write-Error $msg
  exit 1
}

Function CheckReturnCodeOfPreviousCommand($msg) {
  if(-Not $?) {
    Error "${msg}. Error code: $LastExitCode"
  }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Resolve-Path $PSScriptRoot
$buildDir = "$root/build"

Info "Remove the build directory if it exists"
Remove-Item $buildDir -Force -Recurse -ErrorAction SilentlyContinue > $null
New-Item $buildDir -Force -ItemType "directory" > $null

Info "Download ExifTool"
Invoke-WebRequest -Uri https://exiftool.org/exiftool-13.40_64.zip -OutFile $buildDir/exiftool.zip
[System.IO.Compression.ZipFile]::ExtractToDirectory("$buildDir/exiftool.zip", "$buildDir")
Rename-Item -Path $buildDir/exiftool-13.40_64 -NewName $buildDir/exiftool
Rename-Item -Path "$buildDir/exiftool/exiftool(-k).exe" -NewName $buildDir/exiftool/exiftool.exe

Info "Generate ExifTool tag names database 'TagNamesDatabase.txt' file"
[xml] $exifToolTagNamesDatabaseXml = & $buildDir/exiftool/exiftool.exe -listx -lang en
CheckReturnCodeOfPreviousCommand "exiftool failed"

$allExifToolTagNames = @()
foreach ($table in $exifToolTagNamesDatabaseXml.taginfo.table) {
  $group0Name = $table.g0
  foreach ($tag in $table.tag) {
    $allExifToolTagNames += "`"${group0Name}__$($tag.name)`": `"$($tag.desc.InnerText)`","
  }
}

Set-Content -Path $root/doc/TagNamesDatabase.txt -Encoding UTF8 -Value $allExifToolTagNames
