<#
.SYNOPSIS
    AD Comms via RSAT-AD

.DESCRIPTION
    Connects and disconnects from AD with RSAT

.SYNTAX  
    For MSOL dotsource this module and call the functions like
    . "Modules/Connect-AD.ps1"
   
     
.NOTES
    This module requires the Logging Module be pre-loaded to accept the "Log-Write" calls

 #>
 Function Invoke-ImportAD { 
 Log-write -logpath $Script:LogPath -linevalue "Checking for ActiveDirectory Module"

     If ((Get-module -Name activedirectory -ErrorAction SilentlyContinue) -eq $null) {
     
        Log-write -logpath $Script:LogPath -linevalue "`t`tActiveDirectory module not loaded, attempting to add..."
         try {
            import-module activedirectory -ErrorAction SilentlyContinue
            while ((get-module -listAvailable -Name ActiveDirectory) -eq $null) {
               log-write -LogPath $Script:LogPath -linevalue "`t`t[ERROR] Unable to ActiveDirectory module, check RSAT is installed"
               import-module activedirectory -ErrorAction SilentlyContinue

            }

         } catch {
            Log-write -logpath $Script:LogPath -linevalue "`t`t[ERROR] $_.exceptionmessage"  
         }

    } else {
        Log-write -logpath $Script:LogPath -linevalue "`t`tActiveDirectory module is already loaded"

    }


}


#Function to check if MSOL is connected
function Get-MSOLStatus {
    Get-MsolDomain -ErrorAction SilentlyContinue | out-null
    $result = $?
    return $result
}


 Function Connect-O365 { 
    Begin {

        Log-write -logpath $Script:LogPath -linevalue "`t`tConnecting to O365..."

        $script:Credentials = Get-Credential -Message "Enter your Office 365 admin credentials"

    }

    Process{
        
        try{
            
            if (-not (Get-MSOLStatus)) {
                Connect-MsolService -Credential $Credentials
            }
        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`t`t`tConnect-O365: [ERROR] $_.exceptionmessage"

        }#Try/Catch
    }#Process
}#Function


Function Connect-CSOnlineSession { 
    Begin {

        Log-write -logpath $Script:LogPath -linevalue "`t`t`t`tConnecting to ExchangeOnline..."

        #Moved to ConnectO365
        #$Script:Credentials = Get-Credential -Message "Enter your Office 365 admin credentials"

    }

    Process{
        
        try{
            $CURRExchangeSession = Get-PSSession | where {$_.State -eq 'Opened' -and $_.configurationName -eq 'Microsoft.Exchange'}
            $CURRLyncSession = Get-PSSession | where {$_.State -eq 'Opened' -and $_.configurationName -eq 'Microsoft.Powershell'}

            
            if (-not $CURRExchangeSession) {
                $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Script:Credentials -Authentication Basic -AllowRedirection
                Import-PSSession $exchangeSession
            }

            if (-not $CURRLyncSession) {
                $lyncsession = New-CsOnlineSession -Credential $Script:Credentials
                Import-PSSession $lyncsession
            } 

        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`t`t`tConnect-CSOnlineSession: [ERROR] $_.exceptionmessage"

        }#Try/Catch
    }#Process
}#Function








