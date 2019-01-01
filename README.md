# Random Microsoft Powershell Scripts
A Repository of random Microsoft related PowerShell scripts

# Start-LabADPopulate 
When you need to test Active Directory in a lab with sample users, creating sufficiently realistic test accounts is a time consuming and tedious process. There are a few quick scripts for creating something similar but many of them only create basic users which don’t emulate a production environment very well.

# Start-ManagerMailMerge
Sometime it's nessessary to email an individual about multiple people. Sometimes, its nessessary to email loads of people about loads of people.

I needed a way to email managers about staff in their team who were recieving new equipment. As this was multiple people in multiple teams with multiple managers it was a bit out of the scope of what mailmerge is designed to handle.

# New-WeeklyMenu
We got sick than eating the same set of meals week in week out, so we put together a spreadsheet of the recipes we use on a regular basis and built a little set of Excel functions to automatically generate a menu for 4 weeks.

This had some issues; we would get duplicates, we couldn't tell which would make enough for leftovers for lunch the day after and most importantly we had to check the recipes for that week and work out a shopping list.

This script addresses those issues and generates a HTML page for the menu and one for the shopping list which can then be printed or whatever you need to do with it.

Update the RecipesList.xlsx with your own.

**NOTE: It doesnt do Mondays and Fridays as we don't need these but if you dont go to my mums for tea on a Monday or Friday then you can fix this by commenting out lines 172 and 173.**