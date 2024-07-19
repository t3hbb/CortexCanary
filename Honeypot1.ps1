# Function to output a separator line
function Write-Separator {
    Write-Output "===================="
}

# Function to output a title with optional font color
function Write-Title {
    param(
        [string]$title,
        [string]$color = "White"
    )
    Write-Host $title -ForegroundColor $color
}

# Function to process a folder

function Process-Folder {
    param(
        [string]$downloadsFolder
    )
#rite-Title "DEBUG: Folder being passed to be processed: $downloadsFolder"
# Get directory listing using cmd.exe and dir
$cmdListing = cmd /c dir $downloadsFolder /b

# Get directory listing using PowerShell
$psListing = Get-ChildItem -Path $downloadsFolder | Select-Object -ExpandProperty Name

# Compare the lists to find the differences
$differences = Compare-Object -ReferenceObject $cmdListing -DifferenceObject $psListing | Where-Object { $_.SideIndicator -eq "=>" } | Select-Object -ExpandProperty InputObject

    if ($differences -eq 0) {
        Write-Title "No candidate files found in $downloadsFolder. Moving to next most likely folder" -color "Red"
        return $false
    }
# Output a title for the found files
Write-Separator 
Write-Title "Potential Cortex EDR Honeypot/Canary files found in $downloadsFolder" -color "Green"
Write-Separator 
Write-Host ""
# Output the file names present in cmd listing but not in PowerShell listing
foreach ($file in $differences) {
    Write-Title "File: $file"
    
    # Retrieve the target property for the file
    $targetProperty = (Get-Item -Path (Join-Path $downloadsFolder $file)).Target
    
    if ($targetProperty) {
        #Write-Title "Target Path: $targetProperty"
        
        # Remove the filename from the honeypot directory path
        $honeypotDirectory = Split-Path $targetProperty
    } else {
        Write-Title "[!]Target Property not available." -color "Red"
    }
}
Write-Host ""
Write-Separator 
Write-Title "Cortex EDR Ransomware folder discovered" -color "Green"
Write-Separator 
Write-Host ""
Write-Title "Cortex EDR decoy ransomware files are located at : $honeypotdirectory" 
Write-Host ""
# Output a title for the Honeypot finder
Write-Separator 
Write-Title "Files located in the Ransomware Directory" -color "Green"
Write-Separator 
Write-Host ""
# Get directory listing for the Honeypot directory including hidden files
$honeypotListing = Get-ChildItem -Path $honeypotDirectory -Force | Select-Object Name, Length, LastWriteTime, Mode

# Define column widths
$colWidthName = 40
$colWidthSize = 15
$colWidthDate = 25
$colWidthMode = 10

# Output header
$header = "{0,-$colWidthName} {1,-$colWidthSize} {2,-$colWidthDate} {3,-$colWidthMode}" -f "Canary File", "Size (bytes)", "Last Write Date", "Mode"
Write-Host $header -ForegroundColor Green

# Output the filenames, file size, last write date, and mode of all files in the Honeypot directory
foreach ($file in $honeypotListing) {
    $fileName = $file.Name
    $fileSize = $file.Length
    $lastWriteDate = $file.LastWriteTime
    $fileMode = $file.Mode

    $output = "{0,-$colWidthName} {1,-$colWidthSize} {2,-$colWidthDate} {3,-$colWidthMode}" -f $fileName, $fileSize, $lastWriteDate, $fileMode
    Write-Host $output
}
Write-Host ""
return $true
}


Write-Title ""
Write-Title "_________                __                  ___________________ __________ " -color "Green"
Write-Title "\_   ___ \  ____________/  |_  ____ ___  ___ \_   _____/\______ \\______   \" -color "Green"
Write-Title "/    \  \/ /  _ \_  __ \   __\/ __ \\  \/  /  |    __)_  |    |  \|       _/" -color "Green"
Write-Title "\     \___(  <_> )  | \/|  | \  ___/ >    <   |        \ |    `   \    |   \" -color "Green"
Write-Title " \______  /\____/|__|   |__|  \___  >__/\_ \ /_______  //_______  /____|_  /" -color "Green"
Write-Title "        \/                        \/      \/         \/         \/       \/ " -color "Green"
Write-Title ""
Write-Title "Find potential Cortex ransomware canary files and display candidates" -color "Green"
Write-Title ""
Write-Title "by @bb_hacks" -color "Yellow"
Write-Title ""

# Get the downloads folder path
#write-host "DEBUG: Starting"
$havefound = $false
$foldersToCheck = @("", "Downloads", "Documents", "Desktop", "Music", "Pictures", "Videos")

foreach ($folder in $foldersToCheck) {
    $folderPath = Join-Path $env:USERPROFILE $folder
    $havefound = Process-Folder -downloadsFolder $folderPath
    if ($havefound -eq $true) {
        exit
    }
}
Write-Host ""
Write-Separator 
Write-Title "No candidate files found"  -color "Red"
Write-Separator 
Write-Host ""