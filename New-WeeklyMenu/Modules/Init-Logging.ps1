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
    Log-Start -LogPath "./Test_Script.log" -ScriptVersion "1.5"
  #>


Function Start-Log{ 
       
    #Create file and start logging
    #Does the folder for Logs exist?
    If((Test-Path -Path $script:LogFolder) -eq $false){
      #Create it if not
      New-Item -Path $LogFolder -Value $Logfolder -ItemType Directory | Out-Null
    }

    #$StartTime = (((get-date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")

    [int]$Script:l++ | Out-Null

    # Create log file with a "u" formatted time-date stamp
    $LogFile = "Log-" + $(get-date -f "yyyy-MM-dd") + ".log"

    $Script:Log = Join-Path -Path $LogFolder -ChildPath $LogFile

    If((Test-Path -Path $Log) -eq $Null){
      New-Item -Path $Log -ItemType File -Force | Out-Null
    }

    $Script:BeginTimer = Get-Date

    $SCript:DelimDouble = ("=" * 100)
    $Header = "Started logging at: " + $(get-date -f "yyyy-MM-dd hh:mm:ss")

    Write-Log -LineValue ($DelimDouble) -SkipTimeStamp
    Write-Log -LineValue ($Header) -SkipTimeStamp
    Write-Log -LineValue ($DelimDouble) -SkipTimeStamp
    Write-Log -LineValue ($DelimDouble) -SkipTimeStamp
}
 

Function Write-Log{  
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true)]$LineValue,
    [Parameter(Mandatory=$false)][switch]$SkipTimeStamp, 
    [Parameter(Mandatory=$false)][string]$logpath,
    [Parameter(Mandatory=$false)][string]$level
  )
  
  Process{ 
    $datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    #Add-Content -Path $Log -Value "[$datetime] $LineValue"

    #Write to screen for debug mode
    If($Level -ne ""){
      $LineValue = "[" + $Level.toupper() + "]: " + $LineValue
    }

    if ($Script:LoggingDebug -eq $true){
      write-host $LineValue
      
    }       
    
    If(!$SkipTimeStamp){
      $LineValue = "[" + $datetime + "] " + $LineValue
    }

      Add-Content -Path $Log -Value $LineValue

  }
}

Function Write-Error{
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$false)][string]$LogPath, 
    [Parameter(Mandatory=$true)][string]$ErrorDesc,
    [Parameter(Mandatory=$true)][boolean]$ExitGracefully

  )
  
  Process{
    $datetime = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    Add-Content -Path $Log -Value "[$datetime] [ERROR]: $ErrorDesc"
  
    #Write to screen for debug mode
    Write-host "[ERROR]: $ErrorDesc" -ForegroundColor Red
    
    #If $ExitGracefully = True then run Log-Finish and exit script
    If ($ExitGracefully -eq $True){
      Stop-Log
      Break
    }
  }
}
 
Function Stop-Log{
  
  [CmdletBinding()]
  
  Param (
    [Parameter(Mandatory=$false)][string]$LogPath, 
    [Parameter(Mandatory=$false)][string]$NoExit
  )
  
  Process{

    $StopTimer = Get-Date
    $EndTime = (((Get-Date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")
    $ExecutionTime = New-TimeSpan -Start $Script:BeginTimer -End $StopTimer

    Write-Log($DelimDouble) -SkipTimeStamp
    Write-Log("SCRIPT COMPLETED AT: $EndTime") -SkipTimeStamp
    Write-Log("TOTAL SCRIPT EXECUTION TIME: $ExecutionTime") -SkipTimeStamp
    Write-Log($DelimDouble) -SkipTimeStamp
    Write-Log(" ") -SkipTimeStamp
    Write-Log(" ") -SkipTimeStamp

    Write-host "LOG CAN BE FOUND HERE: $Log" -ForegroundColor Green

    #Exit calling script if NoExit has not been specified or is set to False
    If(!($NoExit) -or ($NoExit -eq $False)){
      Exit
    }    
  }
}
 

Function Send-LogEmail{  

  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$EmailFrom, 
  [Parameter(Mandatory=$true)][string]$EmailTo, 
  [Parameter(Mandatory=$true)][string]$EmailBody,
  [Parameter(Mandatory=$true)][string]$EmailSubject)
  
  Process{
    Try{

      Send-MailMessage -SmtpServer $Script:LogSMTPServer `
      -From $EmailFrom -To $EmailTo `
      -Subject $EmailSubject `
      -Body $EmailBody `
      -Attachments $Log
          
    }
    
    Catch{
      write-error -ErrorDesc "$_.Exception" -ExitGracefully $True
    } 
  }
}


set-alias -name Log-Start -value Start-Log
set-alias -name Log-Write -value Write-Log
set-alias -name Log-Error -value Write-Error
set-alias -name Log-Finish -value Stop-log
set-alias -name Log-Email -value Send-LogEmail
