#
# Global variables
#
# User properties
# Base OU for users, sub OU for country code will be created
$BaseOU = "OU=Users,OU=Company,DC=lab,DC=local" 

# Domain Details
$orgShortName = "LAB"                         # This is used to build a user's sAMAccountName
$dnsDomain = "lab.local"                      # Domain is used for e-mail address and UPN

#Companies the user could be part of
$Companies = @("Lab Corp", "Lab Ltd", "Env. Testing Industries", "MyLab Inc.")                      

#Departments and their sub positions users could be part of
$Departments = (                             # Departments and associated job titles to assign to the users
                  @{"Name" = "Finance & Accounting"; Positions = ("Manager", "Accountant", "Data Entry")},
                  @{"Name" = "Human Resources"; Positions = ("Manager", "Administrator", "Officer", "Coordinator")},
                  @{"Name" = "Sales"; Positions = ("Manager", "Representative", "Consultant")},
                  @{"Name" = "Marketing"; Positions = ("Manager", "Coordinator", "Assistant", "Specialist")},
                  @{"Name" = "Engineering"; Positions = ("Manager", "Engineer", "Scientist")},
                  @{"Name" = "Consulting"; Positions = ("Manager", "Consultant")},
                  @{"Name" = "IT"; Positions = ("Manager", "Engineer", "Technician")}
               )
$employeeTypes = @("EMP", "Regular", "Contractor", "Fixed Term Regular", "Temporary", "Full-Time")


#File with list of users format as:
#   Title	GivenName	Surname	EmailAddress	    Username	Password	TelephoneNumber	StreetAddress	    City	ZipCode	Country	CountryFull
#   Mr.	    Mike	    Lowe	MikeLowe@rhyta.com	10073001	Eigei7ye	0951 85 76 34	Mühlenstrasse 30	Bamberg	96010	DE	    Germany
$UsersFile = ".\FakeUserData.csv"


#################################
#             Begin
#################################

$ListOfUsers = import-csv $UsersFile

foreach($User in $Listofusers){
    if((dsquery user -samid $user.Username) -eq $null){
            Write-host "Creating user" $User.Givenname $User.Surname
            #Assigning the user to a company
            $UserCompany = $Companies[(get-random -Minimum 0 -max $Companies.count)]

            #Assign the user to a department
            $DepartmentIndex = get-random -Minimum 0 -max $departments.count
            $UserDepartment = $Departments[$DepartmentIndex].name
            $UserJob = $Departments[$DepartmentIndex].Positions[$(Get-Random -Minimum 0 -Maximum $Departments[$DepartmentIndex].Positions.Count)]       

            $UserEmployeeType = $employeeTypes[(get-random -Minimum 0 -max $employeeTypes.count)]
            Write-host "`tAssigning the user to $UserJob in the $UserDapartment deptartment for $UserCompany, their employment type is $UserEmplyeeType"


            $UserFullName = $User.GivenName + " " + $User.Surname
            $UserPrincipalName = $User.Username + "@lab.local"

            #Check OU Exists, create it if not
            $UserOUPath = "OU=" + $User.Country + "," + $BaseOU
            If (!([adsi]::Exists("LDAP://" + $UserOUPath))){
                try {
                    New-ADOrganizationalUnit $User.Country -Path $BaseOU
                }catch{
                    $UserOUPath = $BaseOU
                }
            }
      
            #Conver the plain text password to a secure string
            $UserPassword = ConvertTo-SecureString -AsPlainText $user.Password -Force
    
            write-host "`t`t`tCreating AD Object...`n"

            New-AdUser -SamAccountName $User.Username -Name $UserFullName -Path $UserOUPath -AccountPassword $UserPassword -Enabled $True `
            -GivenName $User.GivenName -Surname $User.Surname -DisplayName $UserFullName -EmailAddress $User.EmailAddress`
            -StreetAddress $User.StreetAddress -City $User.City -PostalCode $User.ZipCode -Country $User.Country -UserPrincipalName $UserPrincipalName `
            -Company $UserCompany -Department $UserDepartment -EmployeeNumber $User.Username -Title $UserJob -OfficePhone $User.TelephoneNumber
    
     }else{

        write-host $User.GivenName $User.Surname " already exists"

     }
     
}


 write-host "All users created. Calculating managers..."

$AllUsers = get-adUser -searchbase $BaseOU -filter * -properties Title,Company,Department,Manager

# Foreach company
foreach ($MGRCompany in $Companies){
    write-host "`tWorking with $MGRCompany"

    #Get the list of all users in this company
    $AllUsers_Company = $Allusers | where-object {$_.Company -eq $MGRCompany}
    

    # Foreach department in the company...
    foreach($MGRDepartment in $Departments.name){
        write-host "`t`Setting the managers for $MGRCompany, $MGRDepartment" 

        #Get the list of departments in this company...
        $AllUsers_Company_Dept = $AllUsers_Company | where-object {$_.Department -eq $MGRDepartment}

        #Get the list of managers in this department
        $MGRDepartment_Managers = $AllUsers_Company_Dept | Where-object{$_.title -match "Manager"}

        
        #for each user who is not a manger in this department...
        foreach($NotManagerUSR in ($AllUsers_Company_Dept | Where-object{$_.title -notmatch "Manager" -and $_.manager -eq $null})){
            
            # Get a random manager from this department
            $UserMGR = $MGRDepartment_Managers[(get-random -Minimum 0 -max $MGRDepartment_Managers.count)]

            write-host "`t`t`tAssigning " $UserMGR.name " as the manager for " $NotManagerUSR.name

            #Set the Non-manager's manager to the randomly assigned manager
            Set-aduser $NotManagerUSR.SamAccountName -Manager $UserMGR.SamAccountName

        }#End Manager
    }#End foreach department
}#End foreach Company


pause
Exit