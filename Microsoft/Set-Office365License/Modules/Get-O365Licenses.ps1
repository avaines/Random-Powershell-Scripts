
### Get-LicencedFeatures ###
<#
.SYNOPSIS
    Collects all available services and license information for a given Office365 tenant
 
.DESCRIPTION
    Collects all available services and license information for a given Office365 tenant. Stores the information in a JSON file named "O365LicenseStructure.json" in the execution directory.

    JSON structure looks like this:
    {
    "Tenant":  [
                   "XYZ1"
               ],
    "Licenses":  [
                    {
                         "ENTERPRISEPACK":  [
                                                {
                                                    "ActiveLicenses":  100,
                                                    "AssignedLicenses":  13,
                                                    "LockedOutLicenses":  0,
                                                    "SuspendedLicenses":  0,
                                                    "Features":  [
                                                                "FLOW_O365_P2",
                                                                "POWERAPPS_O365_P2",
                                                                "TEAMS1",
                                                                "PROJECTWORKMANAGEMENT",
                                                                "SWAY",
                                                                "INTUNE_O365",
                                                                "YAMMER_ENTERPRISE",
                                                                "RMS_S_ENTERPRISE",
                                                                "OFFICESUBSCRIPTION",
                                                                "MCOSTANDARD",
                                                                "SHAREPOINTWAC",
                                                                "SHAREPOINTENTERPRISE",
                                                                "EXCHANGE_S_ENTERPRISE"   
                                                                ]
                                                    }
                                                ]
                        }
                 ]
    }
  
.PARAMETER tenant
    Mandatory. Name of Office 365 Tenant. "(Get-MsolAccountSku).accountname" will give you this info
  
.OUTPUTS
    O365LicenseStructure.json
 
.NOTES
 
.EXAMPLE
    Get-LicencedFeatures -tenant "XYZ1"
#>
 Function Get-LicencedFeatures { 
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Tenant
    )

    Begin {
        Log-write -logpath $Script:LogPath -linevalue "`t`t`tWorking with tenant: $Tenant"
        $365LicesesContainer = new-object -TypeName PSObject
        $SKUFeatureDetails = @()
        $365ReportContainer = new-object -TypeName PSObject
        $MapFileName = ".\Output\" + $Tenant + "O36LicenseStructure.json"
    
   }

    Process{

        try{ 
    
            #Add tenant details to the container
            $365ReportContainer | 
                Add-Member -MemberType NoteProperty -Name "Tenant" -Value $tenant
            
            Log-write -logpath $Script:LogPath -linevalue "`t`tTenant details collected"


            #Collect all Licenses currently available
            Log-write -logpath $Script:LogPath -linevalue "`t`tLooking for all available licenses & features"
            
            foreach ($SKULicense in Get-MsolAccountSku){
                #Collect the SKU name as a string for logging messages etc. like "ENTERPRISEPACK"
                $SKULicenseName = $SKULicense.AccountSkuId 
                 
                                
                #Look for each feature/service plan in the current license
                foreach ($SKUFeature in $SKULicense.servicestatus){
                    $SKUFeatureName = $SkuFeature.ServicePlan.ServiceName
                    
                    #Record the service plan/feature name          
                    $SKUFeatureDetails += $SKUFeatureName

                }#end foreach (feature)


                #Create an object for each individual license like "ENTERPRISEPACK"
                $O365LicenseDetails = new-object -TypeName PSObject | 
                    Add-Member -Force -PassThru NoteProperty -Name "ActiveLicenses" -Value $SKULicense.ActiveUnits |
                    Add-Member -Force -PassThru NoteProperty -Name "AssignedLicenses" -Value $SKULicense.ConsumedUnits |
                    Add-Member -Force -PassThru NoteProperty -Name "LockedOutLicenses" -Value $SKULicense.LockedoutUnits |
                    Add-Member -Force -PassThru NoteProperty -Name "SuspendedLicenses" -Value $SKULicense.SuspendedUnits |
                    Add-Member -Force -PassThru NoteProperty -Name "Features" -Value @($SKUFeatureDetails)


                #Add License SKU details to the container    
                $365LicesesContainer | 
                    Add-Member -MemberType NoteProperty -Name $SKULicenseName -Value @($O365LicenseDetails)
                
                  
                #Reset the features array ready for the next license
                $SKUFeatureDetails = @()  

                #Spammy
                #Log-write -logpath $Script:LogPath -linevalue "`t`tLicense details collected: $SKULicenseName"              
                
            }#end foreach (license)


            
            $365ReportContainer | 
                Add-Member -MemberType NoteProperty -Name "Licenses" -Value @($365LicesesContainer) 
                Log-write -logpath $Script:LogPath -linevalue "`t`t`tLicense details collected"

          
            try{
                #Write the JSON to file
               
                $365ReportContainer| convertto-json -depth 10 | out-file $MapFileName
                Log-write -logpath $Script:LogPath -linevalue "`t`tJSON Written to file successfully"
                
                } catch {
                
                    Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $False
                
                }


        }catch{
            Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $False
        }#Try/Catch
    }#Process
}#Function





### Get-O365LicenseStructure ###
<#
.SYNOPSIS
    Loads the license map created by Get-LicencedFeatures in to the script namespace
 
.DESCRIPTION
    Loads the license map created by Get-LicencedFeatures in to the script namespace

.OUTPUTS
    $script:O365LicenseMap is available
 
.NOTES
    

.EXAMPLE
    Get-O365LicenseMap

#>
 Function Get-O365LicenseMap { 
 [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Tenant
    )
    Begin{
    
    $MapFileName = ".\Output\" + $Tenant + "O36LicenseStructure.json"
    
    }
    
    Process {

        try{ 
  
            Get-LicencedFeatures -Tenant $Tenant

            $script:O365LicenseMap = convertfrom-json -InputObject (Get-Content $MapFileName -raw)

            Log-write -logpath $Script:LogPath -linevalue "`t`tLicense Map loaded"
            
        }catch{

            Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $False
    
        }#Try/Catch
    
    }#end Process

}#Function




### Get-O365LicenseAvailable ###
<#
.SYNOPSIS
    Based on the Get-LicencedFeatures JSON map, is there atleast 1 available license
 
.DESCRIPTION
    Based on the Get-LicencedFeatures JSON map, is there atleast 1 available license

.OUTPUTS
    True/False
 
.NOTES
    

.EXAMPLE
    if (Get-O365LicenseAvailable -Tenant $Tenant -License $License){
        #is true
        #Licenses are available
    }

#>
 Function Get-O365LicenseAvailable { 
 [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Tenant,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$License
    )

    try{ 
        $ProductCode = $Tenant + ":" + $license       
        
        If ($script:O365LicenseMap.Licenses.$ProductCode.ActiveLicenses - $script:O365LicenseMap.Licenses.$ProductCode.AssignedLicenses -ge 1){
            #active lisences - assigned licenses is 1 or greater
            return $true

        } else{

            return $false
        }

    }catch{

        Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $False
        return $false
    
    }#Try/Catch

}#Function

