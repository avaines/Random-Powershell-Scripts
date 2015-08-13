
<#
.SYNOPSIS
    Recursivly create AD directory structure form LDAP string format
    TAKE GREAT CARE
 
.DESCRIPTION
    Takes a CSV called DomainChange.csv containing a data structured like
		Type, 	ADsPath, 	sAMAccountName, 	New Login Name, 	current logon
		Users, 	LDAP://DOMAIN.local/CN=Aiden vaines,OU=Standard_Users,OU=IT,DC=DOMAIN,DC=local, 	Aiden.Vaines,  	A.vaines@domain.local,  	A.vaines@newupn.com

    Breaks it down and recursivly creates the OUs and user accounts with a default password
    
.PARAMETER  
    None
 
.EXAMPLE
    Create a CSV with a column called "Users and save it in the same directory as this script (or change $CSVData variable)
    Run the script as a domain admin
     
.NOTES
    Author: Aiden Vaines
    Date: 10/08/2015
    Email: aiden@vaines.org
 #>


#$ErrorActionPreference = 'silentlycontinue'
$CSVData = import-csv -path "DomainChange.csv"
$PathNoUser=""



ForEach ($object in $CSVData)  {  
    if ($object.Type ="Users"){
       
        #Create OUs
        ###########

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
        }
        $PathNoUser = $PathNoUser.substring(1)
        
        try {
            #Build the OU structure
            #################################
            #write-host "Check if $PathNoUser exists"
                
            # The desired resulting OU DN  
            # A regex to split the DN, taking escaped commas into account
            $PathNoUserRegex = '(?<![\\]),'
        
            # We'll need to traverse the path, level by level, let's figure out the number of possible levels 
            $Depth = ($PathNoUser -split $PathNoUserRegex).Count
            # Step through each possible parent OU
            for($i = 1;$i -le $Depth;$i++)
            {
                $NextOU = ($PathNoUser -split $PathNoUserRegex,$i)[-1]
                if($NextOU.IndexOf("OU=") -ne 0 -or [ADSI]::Exists("LDAP://$NextOU"))
                {
                    break
                }
                else
                {
                    # OU does not exist, remember this for later
                    [String[]]$MissingOUs += $NextOU 
                }
            }
        
            # Reverse the order of missing OUs, we want to create the top-most needed level first
            [array]::Reverse($MissingOUs)
        
            # Now create the missing part of the tree, including the desired OU
            foreach($OU in $MissingOUs)
            {
                $newOUName = (($OU -split $PathNoUserRegex,2)[0] -split "=")[1]
                $newOUPath = ($OU -split $PathNoUserRegex,2)[1]
                New-ADOrganizationalUnit -Name $newOUName -Path $newOUPath
            }
            
        }catch{
            Write-Host "[ERROR] Create OU failed => " $_.exception.message
        }
    }
        #################################
        

        #Create the user accounts
        #########################
        
        try {
            $pathusername = $object.sAMAccountName
            write-host ""
            #new-AdUser -name $pathusername -SamAccountName $pathusername -path $Pathnouserpadded -enabled $true -PasswordNotRequired $true -passThru

            New-ADUser -Name $PathUser -SamAccountName $pathusername -userprincipalname ($pathusername +'@' + $PathDomain) -Path $PathNoUser -Description "TEST" -Enabled $True -AccountPassword (ConvertTo-SecureString "Password1@"-AsPlainText -force) -PassThru
        
        }catch{
            Write-Host "[ERROR] Create user failed => " $_.exception.message
        }
        #################################


        

        #Clear VARs
        $PathUser="" 
        $PathNoUser=""
        $PathDomain=""
#pause
}
