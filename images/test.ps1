<#
.SYNOPSIS
Downloads files from a remote URL based on a local directory structure and replaces them.

.DESCRIPTION
This script iterates through all existing files in a local directory and its subfolders.
It constructs the corresponding remote URL for each file using a base URL,
then downloads the remote file directly to the existing local file path,
effectively replacing the current file with the remote version.

.PARAMETER LocalSourceDir
The local directory containing the existing file structure where replacements will occur.

.PARAMETER RemoteBaseUrl
The base URL of the remote folder (must end with a slash '/').

.EXAMPLE
# This will overwrite all files found in 'C:\LocalWebProject\assets\images' and its subfolders
# with files from 'https://bracketweb.com/aigence-html/assets/images/'
.\Replace-LocalFiles.ps1 `
    -LocalSourceDir 'C:\LocalWebProject\assets\images' `
    -RemoteBaseUrl 'https://bracketweb.com/aigence-html/assets/images/'
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$LocalSourceDir,

    [Parameter(Mandatory=$true)]
    [string]$RemoteBaseUrl
)

# --- Configuration Checks ---
if (-not (Test-Path -Path $LocalSourceDir -PathType Container)) {
    Write-Error "Error: Local source directory '$LocalSourceDir' does not exist."
    exit 1
}

# Ensure the local source directory path ends with a backslash for clean path trimming later
if (-not ($LocalSourceDir.EndsWith('\'))) {
    $LocalSourceDir = "$($LocalSourceDir)\"
}

# Ensure the remote URL ends with a slash
if (-not ($RemoteBaseUrl.EndsWith('/'))) {
    $RemoteBaseUrl = "$($RemoteBaseUrl)/"
}

# --- Start File Iteration ---
Write-Host "Starting file replacement process in: $LocalSourceDir" -ForegroundColor Yellow
Write-Host "Remote Base URL: $RemoteBaseUrl"
Write-Host "WARNING: Existing files in the local directory WILL BE OVERWRITTEN." -ForegroundColor Red
Write-Host "---"

# Get all files recursively from the local source directory
$FilesToReplace = Get-ChildItem -Path $LocalSourceDir -File -Recurse

if ($FilesToReplace.Count -eq 0) {
    Write-Host "No files found in $LocalSourceDir. Exiting."
    exit 0
}

foreach ($File in $FilesToReplace) {
    # 1. Calculate the relative path (e.g., 'subfolder1\file.jpg')
    $RelativePath = $File.FullName.Replace($LocalSourceDir, '')

    # 2. Construct the full remote URL (URL must be escaped for special characters)
    # The remote path uses forward slashes (/)
    $RemoteRelativePath = $RelativePath -replace '\\', '/'
    $RemoteRelativePathEscaped = [uri]::EscapeUriString($RemoteRelativePath)
    $RemoteFileUrl = "$($RemoteBaseUrl)$($RemoteRelativePathEscaped)"

    # 3. The local target path is the file's existing full name
    $LocalTargetPath = $File.FullName

    # 4. Download the file and overwrite the existing one
    Write-Host "Replacing $($RelativePath)..." -NoNewline
    try {
        # Use Invoke-WebRequest to download the file directly to the existing path
        # Note: Invoke-WebRequest will overwrite the file by default if it exists.
        Invoke-WebRequest -Uri $RemoteFileUrl -OutFile $LocalTargetPath -ErrorAction Stop

        Write-Host " SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Warning "Could not download '$RemoteFileUrl' to replace '$LocalTargetPath'. Error: $($_.Exception.Message)"
    }
}

Write-Host "---"
Write-Host "Script completed. All targeted local files have been replaced with remote versions." -ForegroundColor Cyan