
# set location at the current script location
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."

# read the version number from pubspec.yaml
$version = (Get-Content pubspec.yaml | Select-String "version:").ToString().Split(":")[1].Trim()
$version_without_built_number = $version.Split("+")[0]

# print the version number
Write-Output $version
Write-Output $version_without_built_number

# extract from CHANGELOG.md the release note for the current version
# until the next version log
$changelog = Get-Content -Path "CHANGELOG.md"
$releaseNote = New-Object System.Collections.ArrayList
$foundFirstVersion = $false

foreach ($line in $changelog) {
  if ($line -match "^## \[\d+\.\d+\.\d+\]") {
    if ($foundFirstVersion) {
      break
    }
    else {
      $foundFirstVersion = $true
    }
  }
  if ($foundFirstVersion) {
    $releaseNote.Add($line) | Out-Null
  }
}

Write-Output $releaseNote