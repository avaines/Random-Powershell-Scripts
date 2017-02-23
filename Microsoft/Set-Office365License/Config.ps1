$Script:LoggingDebug = $true #Causes debug output to console when true, uses Write-Host, don't enable for production
$Script:LogFolder = "Logs"
$Script:LogPath = "$Script:LogFolder\Log-$(get-date -f yyyy-MM-dd).log"  #Set log path

#AD Security groups
$Script:Groups = @("COR_SG_InTune_Users", "SG_ActiveSync_Mobile_Devices")

#Office365 licenses to add in format "TENANT:LICENSE:FEATURE"
$Script:AddLicenses = @("TENANT1:EMS:INTUNE_A")

#TODO
#Office365 licenses to remove in format "TENANT:LICENSE:FEATURE"
#$Script:removeLicenses = @()