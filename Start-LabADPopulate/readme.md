Start-LabADPopulate
===================
A script to populate a lab environment with pretend users

----------

 1. Copy this script folder to your lab DC
 2. Update the variables at the top of the "Start-LabADPopulate.ps1"script
 3. Create the base OU structure (see below)
 3. Execute the "Start-LabADPopulate.ps1 script
 4. Wait


----------

How It Works
---------
When you need to test Active Directory in a lab with sample users, creating sufficiently realistic test accounts is a time consuming and tedious process. There are a few quick scripts for creating something similar but many of them only create basic users which don't emulate a production environment very well.


This script will create users with the following attributes:

 - **SAMAccount Name** - A unique ID number authenticate a user
 - **Name** - A user has a full name sourced from a list of regional names
 - **Address** - People need an address, again regionally sourced addresses from Germany, Spain, Italy, France, Poland and the United Kingdom
 - **Email Address**
 - **Company** - Most sufficiently large organisations have multiple internal companies, this script accepts a list of possible companies and assigns each user a random one
 - **Department** - Large organisations have many departments, this script accepts a list of possible departments and assigns each user a random one
 - **Job Title** - Similar to departments, each department often has multiple roles, this script records what job roles exist in each department and assigns a random one to the user
 - **Manager** - People have managers. After creating the user accounts, the script will assign each user a manager from their department and company *(A "Manager" does have to be a valid job role in the department the user is assigned to for this to work)*
 - **EmployeeNumber** - Some organisations assign an ID number to users, this is especially helpful when people have non-alphanumeric characters in their name
 

Setup
---------
You will need to prepare the environment by creating the following OU structure first:

      LAB.local
       \---Company
           \---Users

Update the first 30 or so lines of the script to match your lab environment

 1. This is the OU in your lab where the user accounts will reside

          $BaseOU = "OU=Users,OU=Company,DC=lab,DC=local"
    

 2. The organisation short name or NETBIOS name:

          $orgShortName = "LAB"

 3. A list of companies within the organisation  a user could belong to.
    Some organisations have smaller companies within, this helps model
    that structure.
    
          $Companies = @("Lab Corp", "Lab Ltd", "Env. Testing Industries", "MyLab Inc.")

 4. A list of departments, each with a set of job roles. Each user will be assigned a random department and a role/position from within it. Once the script has finished creating the users, it will run back through all the users it created and assign everyone in each department a manager from the same department and company.

          $Departments = (
             @{"Name" = "Finance & Accounting"; Positions = ("Manager", "Accountant", "Data Entry")},
             @{"Name" = "Human Resources"; Positions = ("Manager", "Administrator", "Officer", "Coordinator")},
             @{"Name" = "Sales"; Positions = ("Manager", "Representative", "Consultant")},
             @{"Name" = "Marketing"; Positions = ("Manager", "Coordinator", "Assistant", "Specialist")},
             @{"Name" = "Engineering"; Positions = ("Manager", "Engineer", "Scientist")},
             @{"Name" = "Consulting"; Positions = ("Manager", "Consultant")},
             @{"Name" = "IT"; Positions = ("Manager", "Engineer", "Technician")}
           )
     
 5. Finally, the path for the user data, as long as the fields are the
    same feel free to replace/update it.

          $UsersFile = ".\FakeUserData.csv"


Credit
---------
The information stored in "FakeUserData.csv" was provided by https://www.fakenamegenerator.com/ and contains around 600 random users doted around Europe in the following countries:
 - Germany
 - Spain
 - Italy
 - France
 - United Kingdom
 - Poland

The foundation for this project is based on work by Helge Klein's blog post here: https://helgeklein.com/blog/2015/02/creating-realistic-test-user-accounts-active-directory/
