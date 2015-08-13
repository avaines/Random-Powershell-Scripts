<#
.SYNOPSIS
    Compares a CSV with a given active directory OU, checks the UPN against a list and replaces with the desired UPN
    TAKE GREAT CARE
 
.DESCRIPTION
    Takes a CSV called DomainChange.csv containing a data structured like
		Type, 	ADsPath, 	sAMAccountName, 	New Login Name, 	current logon
		Users, 	LDAP://DOMAIN.local/CN=Aiden vaines,OU=Standard_Users,OU=IT,DC=DOMAIN,DC=local, 	Aiden.Vaines,  	A.vaines@domain.local,  	A.vaines@newupn.com
    Breaks it down and compares each user from the specified OU against the spreadsheet, and displays in a table
    User is then prompted to remediate and update all matched UPNs, script will check the UPN exists 1st
    
.PARAMETER  
    None
 
.EXAMPLE
    Takes a CSV called DomainChange.csv from the running directory containing a data structured like:
		Type, 	ADsPath, 	sAMAccountName, 	New Login Name, 	current logon
		Users, 	LDAP://DOMAIN.local/CN=Aiden vaines,OU=Standard_Users,OU=IT,DC=DOMAIN,DC=local, 	Aiden.Vaines,  	A.vaines@domain.local,  	A.vaines@newupn.com
     run script in powershell


.NOTES
    Author: Aiden Vaines
    Date: 10/08/2015
    Email: aiden@vaines.org
 #>



Try 
{ 
    Import-Module ActiveDirectory -ErrorAction Stop 
    Remove-Variable * -ErrorAction SilentlyContinue
} 
Catch 
{ 
    Write-Host "[ERROR]`t ActiveDirectory Module couldn't be loaded. Script will stop!" 
    Exit 1 
} 



function Get-UPNListADCheck{
    Param(
     [Parameter(Mandatory=$False)]  
     [int[]]$SkipSetVars  
    )

    Begin
    {
        if ($SkipSetVars -ne 1){
            #Replace with the name of your AD server
            $Global:server = read-host "Server name (default is 'localhost')"
            if ($Global:server -eq ""){
                $Global:server = "localhost" #Set the domain controller to use # default is localhost
            }
                write-host "Server set to: " $Global:server

            $oulimiter = read-host "Enter OU to process, for best results use the format 'OU=MyOU'"
            if ($oulimiter -eq ""){
                $oulimiter = "OU=" #Limit remediation to an OU, default will include anything in any OU
            }
                write-host "Search and remdiation restricted to: "$oulimiter
        }
        write-host "reading DomaniChange.csv"
        $CSVData = import-csv -path "DomainChange.csv"

    }
    Process {

        #Loop through each item in the list where its a user and contains the string in the "oulimiter" variable
        ForEach ($object in $CSVData | where-object {
            $_.Type -match 'Users'-and $_.ADsPath -like "*"+$oulimiter+"*"}){

                #Split up the ADsPath column in to usable peices
                $PathParts = $object.ADsPath.split(",") 
                $i=0
                foreach($PathOu in $PathParts){
                    if ($i -eq $PathParts.count - 2){
                        $PathDomain = $PathOu.substring(3)
                    }
                    if ($i -eq $PathParts.count - 1){
                        $PathDomain = $PathDomain +"."+ $PathOu.substring(3)
                    }
    
                    if ($i -gt 0){
                        $PathNoUser+=",$PathOu"
                    }elseif ($i -eq 0){
                        $PathUser = $PathOu.substring(27)
                    }
                    $i+=1
                }#End of foreach block
                $OUBase = $PathNoUser.substring(1)

                #LDAP://DOMAIN.COM/CN=Dave User,OU=Standard_Users,OU=IT,DC=Domain,DC=local
                # has been split up in to:
                #     $OUbase = OU=Standard_Users,OU=IT,DC=Domain,DC=local
                #     $PathDomain = DOMAIN.local
                #     $PathUser = Dave User
                
                #Array structure:
                #[0]              [1]          [2]         [3]               [5]               [6]
                #SAM Name    Current UPN    New UPN    Actual UPN     Does actual match?     Users OU
                #create array and insert the data we know from the list
                try {
                    #Get the current line SAM account from the list
                    $ADUser = get-aduser $object.sAMAccountName

                    #Get the actuall UPN from AD
                    $OldUPN = $ADUser.UserPrincipalName
        
                    #Does that match    
                    $UPNMatch = $object.'current logon' -eq $oldUPN

                    #Build the array
                    $Global:UPNArray += [PSCustomObject]@{"SAM Name"=$object.sAMAccountName
                        "Current UPN"= $object.'current logon'
                        "New UPN"=$object.'New Login Name'
                        "Actual UPN"=$OldUPN
                        "Does actual match?"=$UPNMatch
                        "Users OU"=$OUbase}

                    $OldUPN=""
                    $OUbase=""
                    $PathNoUser=""

                } catch {
                    Write-Host "`t[ERROR] Building array!" 
                    write-host "`t " $_.exception.message
                    break
                }#End of try catch block

            }#End of Where-Object block

            #Format the table and print it
            $Global:UPNArray  | Out-GridView 

    }#End of process block
}#End of function block


function Start-ReplaceUPNs{
    Begin
    {
        $DesiredUPNs = @()
    }
    Process {
        while ($choice -notmatch "[YN]"){
            $choice = read-host "Continue with UPN rename process [Y/N]?"
        }

        switch ($choice){
            Y{
                foreach ($row in $Global:UPNArray){
                    $DesiredUPNs += @($row.'New UPN'.tolower().split("@")[1])
                }
                 $DesiredUPNs = $DesiredUPNs.tolower() | sort-object | get-unique   



                #Find out all UPNs listed in Domains and Trusts
                write-host "Checking for UPN Suffix: " $DesiredUPNs
                $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()            
                $domaindn = ($domain.GetDirectoryEntry()).distinguishedName            
                $upnDN = "cn=Partitions,cn=Configuration,$domaindn" 
                $upnList = Get-ADObject -Identity $upnDN -Properties upnsuffixes | select -ExpandProperty upnsuffixes
                               
                #Check the exsisting UPNs agains the new UPN we want to use   
                [regex] $RF_regex = ‘(?i)^(‘ + (($DesiredUPNs |foreach {[regex]::escape($_)}) –join “|”) + ‘)$’  #regex from $DesiredUPNs. Matched against $UPNList, it will return true/false.

                               
                if (($UPNList -match $RF_regex).count -eq $DesiredUPNs.count){
                        write-host "Desired UPNs are found in the Domain's config"


                        write-host "Renaming UPNs"
                        #Go through the array top to bottom replacing the users UPN suffix as agreed
                        for ($j=0; $j -lt $Global:UPNArray.count; $j++){

                            "`tRenaming " + $Global:UPNArray[$j].'SAM Name' + " (" + $Global:UPNArray[$j].'Current UPN' + " => " + $Global:UPNArray[$j].'New UPN' + ")"
                            try{
                                if ($Global:UPNArray[$j].'Does actual match?' = $true ){
                                    #Array structure
                                    #[0]              [1]          [2]         [3]               [5]               [6]
                                    #SAM Name    Current UPN    New UPN    Actual UPN     Does actual match?     Users OU

                                    $ADUser = get-aduser $Global:UPNArray[$j].'SAM Name'
                                    $NewUPN = $ADUser.UserPrincipalName.Replace($Global:UPNArray[$j].'Actual UPN',$Global:UPNArray[$j].'New UPN')
                                    $ADUser | Set-ADUser -server $server -UserPrincipalName $NewUPN

                                }else{
                                    write-host "Skipping, (list doesnt match AD)"
                                }
                                }catch{
                                    Write-Host "[ERROR] Rename failed!" 
                                    write-host "`t" $_.exception.message
                                    break
                                }

                        }
                    }else{
                        write-host "Desired UPNs were not found in the Domain's config!"
                        compare-object $upnList $DesiredUPNs
                        write-host "Existing"
                        exit
                    }#End UPN suffix check block


                }#End of switch Y block
                N{
                    write-host "Exiting"
                    exit
                }#End of switch N block
                default{
                    write-host "Invalid selection, exiting"
                    exit
                }#End of switch default block
        }#End of switch block

    }#End of process block
}#End of function block


$Global:UPNArray=@()

write-host "Running comparison of list to AD: `n"
Get-UPNListADCheck

write-host "`nStarting remediation process`n"
Start-ReplaceUPNs

write-host "`nRe-Running comparison of list to AD following changes: `n"
pause
Get-UPNListADCheck -SkipSetVars 1