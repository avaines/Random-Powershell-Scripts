Function Log-Start{
  <#
    .SYNOPSIS
      Creates log file
  
    .DESCRIPTION
      Creates log file with path and name that is passed. Checks if log file exists, and if it does deletes it and creates a new one.
      Once created, writes initial logging data
  
    .PARAMETER LogPath
      Mandatory. Path of where log is to be created. Example: C:\Windows\Temp
  
    .PARAMETER LogName
      Mandatory. Name of log file to be created. Example: Test_Script.log
        
    .PARAMETER ScriptVersion
      Mandatory. Version of the running script which will be written in the log. Example: 1.5
  
    .OUTPUTS
      Log file created
  
    .NOTES
  
    .EXAMPLE
      Log-Start -LogPath "C:\Windows\Temp" -LogName "Test_Script.log" -ScriptVersion "1.5"
  #>
      
  [CmdletBinding()]
  
    Param (
        [Parameter(Mandatory=$true)][string]$LogPath, 
        [Parameter(Mandatory=$false)][string]$ScriptVersion
    )
  
    Process{
        $sFullPath = $LogPath
    
    # Check if file exists and delete if it does
    # If((Test-Path -Path $sFullPath)){
    # Remove-Item -Path $sFullPath -Force
    #}
    
    # Create file and start logging
    # Does the folder for Logs exist?
      If((Test-Path -Path $script:LogFolder) -eq $false){
        #Create it if not
        New-Item -Path $LogFolder -Value $Logfolder -ItemType Directory
      }

      # Does the logfile exist?
      If((Test-Path -Path $sFullPath) -eq $false){
        # Create it if not
        New-Item -Path $LogPath -Value $LogName -ItemType File
      }


    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value "Started logging at [$([DateTime]::Now)]."
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    }
}
 

Function Log-Write{
  <#
    .SYNOPSIS
    Writes to a log file
    
    .DESCRIPTION
    Appends a new line to the end of the specified log file
      
    .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log
      
    .PARAMETER LineValue
    Mandatory. The string that you want to write to the log
          
    .INPUTS
    Parameters above
    
    .OUTPUTS
    None
    
    .NOTES
    
    .EXAMPLE
    Log-Write -LogPath "C:\Windows\Temp\Test_Script.log" -LineValue "This is a new line which I am appending to the end of the log file."
  #>
  
  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$LineValue)
  
  Process{
    $datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$datetime] $LineValue"
  
    # Write to screen for debug mode
    if ($Script:LoggingDebug -eq $true){
        Write-Debug $LineValue
        Write-Host $LineValue
    }

  }
}
 

Function Log-Error{
  <#
    .SYNOPSIS
      Writes an error to a log file
  
    .DESCRIPTION
      Writes the passed error to a new line at the end of the specified log file
    
    .PARAMETER LogPath
      Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log
    
    .PARAMETER ErrorDesc
      Mandatory. The description of the error you want to pass (use $_.Exception)
    
    .PARAMETER ExitGracefully
      Mandatory. Boolean. If set to True, runs Log-Finish and then exits script
  
    .INPUTS
      Parameters above
  
    .EXAMPLE
      Log-Error -LogPath "C:\Windows\Temp\Test_Script.log" -ErrorDesc $_.Exception -ExitGracefully $True
  #>
  
  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$ErrorDesc, [Parameter(Mandatory=$true)][boolean]$ExitGracefully)
  
  Process{
    $datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$datetime] [ERROR] An error has occurred: $ErrorDesc"
  
    # Write to screen for debug mode
    if ($Script:LoggingDebug -eq $true){
        Write-Debug "[ERROR] An error has occurred: $ErrorDesc"
        Write-Host "[ERROR] An error has occurred: $ErrorDesc"
    }
   
    
    # If $ExitGracefully = True then run Log-Finish and exit script
    If ($ExitGracefully -eq $True){
      Log-Finish -LogPath $LogPath
      Break
    }
  }
}
 

Function Log-Finish{
  <#
    .SYNOPSIS
    Write closing logging data & exit
    
    .DESCRIPTION
    Writes finishing logging data to specified log and then exits the calling script
      
    .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write finishing data to. Example: C:\Windows\Temp\Test_Script.log
    
    .PARAMETER NoExit
    Optional. If this is set to True, then the function will not exit the calling script, so that further execution can occur

    .EXAMPLE
    Log-Finish -LogPath "C:\Windows\Temp\Test_Script.log"
    
    .EXAMPLE
    Log-Finish -LogPath "C:\Windows\Temp\Test_Script.log" -NoExit $True
  #>  
  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$false)][string]$NoExit)
  
  Process{
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value "Finished processing at [$([DateTime]::Now)]."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
  
    # Write to screen for debug mode
    Write-Debug ""
    Write-Debug "***************************************************************************************************"
    Write-Debug "Finished processing at [$([DateTime]::Now)]."
    Write-Debug "***************************************************************************************************`n`n"
  
    # Exit calling script if NoExit has not been specified or is set to False
    If(!($NoExit) -or ($NoExit -eq $False)){
      Exit
    }    
  }
}
 


Function Log-Email{  
  <#
    .SYNOPSIS
      Emails log file to list of recipients
  
    .DESCRIPTION
      Emails the contents of the specified log file to a list of recipients
    
    .PARAMETER LogPath
      Mandatory. Full path of the log file you want to email. Example: C:\Windows\Temp\Test_Script.log
    
    .PARAMETER EmailFrom
      Mandatory. The email addresses of who you want to send the email from. Example: "admin@domain.com"
  
    .PARAMETER EmailTo
      Mandatory. The email addresses of where to send the email to. Seperate multiple emails by ",". Example: "admin@domain.com, test@test.com"
    
    .PARAMETER EmailSubject
      Mandatory. The subject of the email you want to send. Example: "Cool Script - [" + (Get-Date).ToShortDateString() + "]"
  
    .EXAMPLE
      Log-Email -LogPath "C:\Windows\Temp\Test_Script.log" -EmailFrom "admin@domain.com" -EmailTo "admin@domain.com, test@test.com" -EmailSubject "Cool Script - [" + (Get-Date).ToShortDateString() + "]"
  #>

  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$EmailFrom, [Parameter(Mandatory=$true)][string]$EmailTo, [Parameter(Mandatory=$true)][string]$EmailSubject)
  
  Process{
    Try{

      Send-MailMessage -SmtpServer $Script:LogSMTPServer `
      -From "$Script:EmailFrom" `
      -To "$Script:EmailTo" `
      -Subject "$Script:EmailSubject" `
      -Body (Get-Content $LogPath | out-string) `
      -Attachments $Script:LogPath `-Priority High -dno onSuccess, onFailure 
      
      #$sBody = (Get-Content $LogPath | out-string)
      #
      # Create SMTP object and send email
      #$sSmtpServer = "relay01.domain.com"
      #$oSmtp = new-object Net.Mail.SmtpClient($sSmtpServer)
      #$oSmtp.Send($EmailFrom, $EmailTo, $EmailSubject, $sBody)
      
      Exit 0
    }
    
    Catch{
      Exit 1
    } 
  }
}