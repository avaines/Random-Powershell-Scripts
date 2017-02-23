<#
.SYNOPSIS
    
.FUNCTIONS
    
 #>



 ### Get-NestedGroupMember ###
<#
	.DESCRIPTION
		Accepts a group name as string, and return an array with the SAM Account Name of every user that is a member of that group, including users that are members of nested groups.
        For instance if the requested group is "group2" and the structure looks like:
            Group2:
                Group1
                Joe Blogs

            Group1:
                Mike Jones

        Both Joe and Mike will be in the returned


	.PARAMETER  
		$Group (Default)
			Accepts the name of an AD Group
	 
	.EXAMPLE
		$MyGroup = "A Group"
        $MyUsers = Get-NestedGroupMember $MyGroup
		write-host $MyUsers
            PS C:\> Joe.Bloggs
                Mike.Jones
		 
	.NOTES
   
#>
function Get-NestedGroupMember {
    [CmdletBinding()] 
    param (
        [Parameter(Mandatory)] [string]$Group 
    )
  ## Find all members in the group specified 
  $GroupUsers = @()

  $members = Get-ADGroupMember -Identity $Group 

      foreach ($member in $members){

          ## If any member in that group is another group just call this function again 

          if ($member.objectClass -eq 'group'){
              Get-NestedGroupMember -Group $member.Name
          }else{
          ## otherwise, just  output the non-group object (probably a user account) 

          $GroupUsers += $member.SamAccountName

          }#End If
      }#End ForEach

    return $GroupUsers

  }#End Function





### Get-SAMfromDisplayName ###
<#
	.DESCRIPTION
		Accepts a users name and returns the users SAM Account Name as a string

	.PARAMETER  
		$DisplayName (Default)
			Accepts a string
	 
	.EXAMPLE
		$MyUser = "Joe Blogs"
		$UserSAM = Get-SAMfromDisplayName $MyUser
		write-host $UserSAM
            PS C:\> 10123456
		 
	.NOTES
   
#>
Function Get-SAMfromDisplayName { 
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$DisplayName
    )

    Begin {
        Log-write -logpath "$Script:LogPath" -linevalue "`tStarting Get-SAMfromDisplayName.ps1"
    }

    Process{
        
        try{
            
            $UserObj = get-aduser -filter {DisplayName -eq $DisplayName}

            if ($UserObj -ne $null){
                return $UserObj.SamAccountName   
            }
            

        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`tGet-shares: [ERROR] $_.exceptionmessage"

        }#Try/Catch
    }#Process
}#Function





### Get-DisplayNameFromSAM ###
<#
	.DESCRIPTION
		Accepts a SAM Account Name as a string and returns theuUsers display name

	.PARAMETER  
		$SAM (Default)
			Accepts a string
	 
	.EXAMPLE
		$MyUserSAM = "10123456"
		$UserName = Get-DisplayNameFromSAM $MyUserSAM
		write-host $UserSAM
            PS C:\> Joe Bloggs
		 
	.NOTES
   
#>
Function Get-DisplayNameFromSAM { 
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$SAM
    )

    Begin {
        Log-write -logpath "$Script:LogPath" -linevalue "`tStarting Get-DisplayNameFromSAM.ps1"
    }

    Process{
        
        try{
            
            $UserObj = get-aduser -filter {SamAccountName -eq $SAM} -properties DisplayName

            if ($UserObj -ne $null){
                return $UserObj.DisplayName   
            }
            

        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`tGet-shares: [ERROR] $_.exceptionmessage"

        }#Try/Catch
    }#Process
}#Function



### Get-UPNFromSAM ###
<#
	.DESCRIPTION
		Accepts a SAM Account Name as a string and returns the Users UPN

	.PARAMETER  
		$SAM (Default)
			Accepts a string
	 
	.EXAMPLE
		$MyUserSAM = "10123456"
		$UPN = Get-UPNFromSAM $MyUserSAM
		write-host $UPN
            PS C:\> JoeBlogg@domain.com
		 
	.NOTES
   
#>
Function Get-UPNFromSAM { 
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$SAM
    )

    Begin {
        Log-write -logpath "$Script:LogPath" -linevalue "`tStarting Get-UPNFromSAM.ps1"
    }

    Process{
        
        try{
            
            $UserObj = get-aduser -filter {SamAccountName -eq $SAM}

            if ($UserObj -ne $null){
                return $UserObj.userprincipalname   
            }
            

        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`tGet-shares: [ERROR] $_.exceptionmessage"

        }#Try/Catch
    }#Process
}#Function

