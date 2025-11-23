
# Create directory path if it doesn't exist
function createPath{

    param(
        [string] $volume
    )

    $testPath = Test-Path -Path ($volume + ":\Bitlocker\")

    if($testPath){
        Write-Host "`nPath already axists"
    }else{
        Write-Host "`nPath doesn't exist, path will now be created."
        New-Item -ItemType Directory -Path ($volume + ":\Bitlocker\")
    }

}


# Check Bitlocker status 
function checkBitlocker{
    manage-bde -status
}

# Export Bitlocker key information to text file
function getVolumeKey {
    param(
        [string] $volume = (Read-Host "`nPlease input the bitlocker drive letter that you would like to export")
    )
  
    createPath($volume)

    $path = ($volume + ":\Bitlocker\BitLockerKey_" + $env:COMPUTERNAME + ".txt")

    manage-bde -protectors -get C: |  Out-File -FilePath $path
    
    Write-Host ("`nBitlocker key information is now stored at directory path "+ $path)

}

function sendEmailWithKey {
    param(
        [string] $to = (Read-Host "`nPlease input the recipient email address"),
        [string] $volume = (Read-Host "`nPlease input the bitlocker drive letter for the key file")
    )
    
    createPath($volume)

    $path = ($volume + ":\Bitlocker\BitLockerKey_" + $env:COMPUTERNAME + ".txt")

    manage-bde -protectors -get C: |  Out-File -FilePath $path
    
    # --- 1. Define Email Parameters ---
    $SMTPServer = "smtp.gmail.com"
    $Subject = "Bitlocker Key Information for " + $env:COMPUTERNAME
    $Body = "Hi, 
    
    please find the required document attached for the Bitlocker key information for computer " + $env:COMPUTERNAME + "
    
    Developed by ANDYWARE
    "


    $Attachment = $path

    # --- 2. Send the Email ---
    $credential = Get-Credential -Message "Please enter your Gmail account credentials with Secure APP Password"
    Send-MailMessage -SMTPServer $SMTPServer -Port 587 -From bitlocker88@gmail.com -To $to -Subject $subject -Body $Body -Attachment $Attachment -Credential $credential -UseSSL
}


#Enable-BitLocker -Mountpoint "C:" -UsedSpaceOnly -SkipHardwareTest -RecoveryPasswordProtector
function enableBitlocker{
    param(
        [string] $volume = (Read-Host "`nPlease input the bitlocker drive letter that you would like to enable")
    )

    Enable-BitLocker -Mountpoint ($volume + ":") -UsedSpaceOnly -SkipHardwareTest -RecoveryPasswordProtector

    Write-Host "`nBitlocker is now enabled on volume $volume`:"

    getVolumeKey($volume)

    $email = read-host "`nWould you like to email the Bitlocker key to yourself? (Y/N)"

    switch ($email) {
        { $_ -eq "Y" -or $_.ToUpper() -eq "YES" } {
            sendEmailWithKey -volume $volume
            break
        }
        { $_ -eq "N" -or $_.ToUpper() -eq "NO" } {
            Write-Host "`nNo email will be sent."
            break
        }
        Default {}
    }

}


#Disable-BitLocker -MountPoint "C:"
function disableBitlocker{
    param(
        [string] $volume = (Read-Host "`nPlease input the bitlocker drive letter that you would like to disable")
    )

    Disable-BitLocker -Mountpoint ($volume + ":")

    Write-Host "`nBitlocker is now disabled on volume $volume`:"

}

function showMenu {
    do {
        Write-Host "`n--- Bitlocker Management Menu ---`n"
        Write-Host "1. Enable Bitlocker"
        Write-Host "2. Disable Bitlocker"
        Write-Host "3. Check Bitlocker Status"
        Write-Host "4. Export Bitlocker Key"
        Write-Host "5. Send Bitlocker Key via Email"
        Write-Host "E. Exit"
        
        $choice = Read-Host "`nPlease select an option (0-5)"

        switch ($choice) {
            1 { enableBitlocker }
            2 { disableBitlocker }
            3 { checkBitlocker }
            4 { getVolumeKey }
            5 { 
                $volume = Read-Host "`nPlease input the bitlocker drive letter for the key file"
                sendEmailWithKey -volume $volume 
            }
            E { Write-Host "Exiting..."; break }
            Default { Write-Warning "`nInvalid option, please try again." }
        }
    } while ($choice -ne 0)
}

showMenu
