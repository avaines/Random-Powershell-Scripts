<#
.SYNOPSIS
    Ad users to AD groups and enable O365 features based on the config file

.DESCRIPTION
    The powershell module for enabling O365 licensing is a bit shit, you can bulk enable something like E1 licenses and all its features, but you can't easily enable a feature of an E1 licenses for users like just skype, or Intune in the EMS license.

    With Intune specifically, if you just enable the EMS licenses, they also get MFA, Azure AD, Intune and so on. I only wan't intune enabled.

    Do do this in PowerShell, you have to create a new licensing option for each object containing the features which should be disabled and apply that to a user. This means if you want to enable say, Skype for business you have to enumerate all the features in the E1 license that are currently disabled, remove MCOSTANDARD and apply that new list as the disabled features in a new licensing option.

    We have several thousand users to enable Skype or Intune for, this will take ages to do manually
    We would have to add them to AD security groups and enable the O365 lisence and associated feature, powershell is the only reaslistic way to accomplish this, i realy dont like writing code only to be used once, so i wrote this

    You just update the config file with the SKU of the features like "TENANT:LICENSE:FEATURE1", the security groups you need and supply a CSV of usernames, the script will do the rest.

    NOTES
    - For the AD groups bits to work you do need to run it as an account with appropriate admin rights
    - You will be prompted for O365 admin creds
    - Make sure RSAT and the O365 powershell plugins are installed and enabled
    - I wrote it on Windows 10 so it might contain some PS 5.0 specific commands

.PARAMETER  csvpath
    csv file with usernames
     
.NOTES


 #>

 [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$CsvPath
 
    )


    #Cleanup from any previous runs
    #Remove-Variable * -ErrorAction SilentlyContinue


    #Load modules and related files
    try{ 
        #DotSource the configfile
        . ".\Config.ps1" 

        ########
        #Logging:
        #Load the logging module and set the login path so al the other scripts use it
        . ".\Modules\Init-Logging.ps1"
 
        #Initialize the log
        Log-Start -logpath $Script:LogPath

        ########



        #DotSource the files we are going to be using
        Log-write -logpath $Script:LogPath -linevalue "Loading Module: Connect-AD"
        . ".\Modules\Connect-AD.ps1" 
    
        Log-write -logpath $Script:LogPath -linevalue "Loading Module: Get-ADFunctions"
        . ".\Modules\Get-ADFunctions.ps1"

        Log-write -logpath $Script:LogPath -linevalue "Loading Module: Get-O365Licenses"
        . ".\Modules\Get-O365Licenses.ps1"

        Log-write -logpath $Script:LogPath -linevalue "Loading Module: Set-O365Licenses"
        . ".\Modules\Set-O365Licenses.ps1"

    }catch [System.Exception]{ 
        Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $True
        throw
    }
    #




    try{
        #Connect to AD
        Log-write -logpath $Script:LogPath -linevalue "`tImporting AD Modules"
        Invoke-ImportAD


        #Connect to Office365
        Log-write -logpath $Script:LogPath -linevalue "`tStarting Connect-O365"
        Connect-O365



        #Load user file to memory
        $Users = gc $CsvPath




        #loop through all users in the list
        Foreach ($user in $users){

            Log-write -logpath $Script:LogPath -linevalue "`tWorking with: $User"
            
            #Check if the current user is given as a number (probably SAM name)
            if ($user -match "^[-]?[0-9.]+$"){
                $UserDN = Get-DisplayNameFromSAM $User
                Log-write -logpath $Script:LogPath -linevalue "`t`t$User Looks like a Global ID for $UserDN"
                $UserID = $User  #Set the UserID Variable

            } else {
                #Check the user exists and return their UserID
                $UserID = Get-SAMfromDisplayName $user

            }
            

            #Assuming the user ID is valid
            if ($UserID -ne $null){
                
                #For each ActiveDirectory group listed in the config file                          
                foreach ($group in $Script:Groups){
                
                    try{

                        #Add them to the Group
                        Log-write -logpath $Script:LogPath -linevalue "`t`tAdding $User to $Group"
                        Add-ADGroupMember $Group -Members $UserID

                    } catch {
                        Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $False

                    }#end try

                }#end for each group
                


                ##################
                #Add O365 Licenses
                ##################
                #For each O365 Licenses listed in the config file   
                foreach ($AddLicense in $AddLicenses){
                    Log-write -logpath $Script:LogPath -linevalue "`t`tWorking with $AddLicense"
                    
                    #Format looks like TENANT:EMS:INTUNE_A, break it down in to constituant parts
                    $Tenant,$License,$Feature = $AddLicense.Split(":")

                    #Load the License JSON map to memory for this tenant (it'll generate one if it doesnt exist)
                    Get-O365LicenseMap -Tenant $Tenant

                    #Are there enough licenses?
                    If (Get-O365LicenseAvailable -Tenant $Tenant -License $License){
                        #True
                        $UserUPN = (get-aduser $UserID).UserPrincipalName

                        Enable-O365Feature -Tenant $Tenant -License $License -Feature $Feature -UPN $UserUPN
                        

                    }else{

                        #False, not enough licenses available, abort
                        Log-Error -LogPath $Script:LogPath -ErrorDesc "[ERROR] Insufficient $License Licenses, aborting..." -ExitGracefully $True
            
                    }#End availablity check

                }#End for each




                ##################
                #TO DO
                #Remove O365 Licenses
                ##################


            #No user ID found
            }else {

                Log-write -logpath $Script:LogPath -linevalue "[WARNING] $User does not exist"
            
            }#end if user id valid

        } #end for each


        Log-Finish -LogPath $Script:LogPath #-NoExit $True

    }catch{

        Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $True

    }#Try/Catch

