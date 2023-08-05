# run distribute_windows_apk_to_google_drive.ps1 first
& "$PSScriptRoot/distribute_windows_apk_to_google_drive.ps1"

# run distribute_google_drive_to_github.ps1 second
& "$PSScriptRoot/distribute_google_drive_to_github.ps1"
