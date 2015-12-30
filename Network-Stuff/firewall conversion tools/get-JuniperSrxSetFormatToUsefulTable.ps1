<#
.SYNOPSIS
    Convert Juniper SRX rules (v15) to a CSV file
 
.DESCRIPTION
    Convert firewall rules in the format of a Juniper SRX (v15) to a CSV file
 
.PARAMETER  
    None
 
.EXAMPLE
    Save the configuration of a Juniper SRX to text file, (must be "display set" format)

    1) Save the result of "show configuration | display set" to a file called input.txt in the execution DIR
    2) Execute the script with .\get-FRWtoTDDFormatSRX
     
.NOTES
    Author: Aiden Vaines
    Date: 09/07/2015
    Email: aiden@vaines.org
 #>



#Getting the data
Write-Host "Loading 'input.txt'"
try {
    $SRXConfig = get-content -path .\input.txt
} catch {
    write-host "`t[ERROR] $_.exceptionmes"
}



#Stores the whole rules table as a jagged array in format:
#(fromZone, toZone, Name, Source, Destination, Service, Action)
$rulesarray = @() 
$SRXConfig -split “`r`n” | foreach { 
     #If its an object definition
    if($_ -match "source-address"){
        $rulesarray += ,@($_.split(" ")[4], $_.split(" ")[6], $_.split(" ")[8], $_.split(" ")[11], "", "", "")

    }elseif ($_ -match "destination-address"){
        $rulesarray += ,@($_.split(" ")[4], $_.split(" ")[6], $_.split(" ")[8], "", $_.split(" ")[11], "", "")
        
    }elseif ($_ -match "application"){
        $rulesarray += ,@($_.split(" ")[4], $_.split(" ")[6], $_.split(" ")[8], "", "", $_.split(" ")[11], "")

    }elseif ($_ -match "then"){
        $rulesarray += ,@($_.split(" ")[4], $_.split(" ")[6], $_.split(" ")[8], "", "", "", $_.split(" ")[10])
    }

}




#Get the unique rule names by listing everything in the "name" column of the main array to a new clean array, 
#then looping through it and outputting the unique entries. 
#The unique entries are then used to overwrite the $rulenames variable
$rulenames=@()
for ($i=0;$i -lt $rulesarray.length; $i++){
    $rulenames += $rulesarray[$i][2]
}
#$rulenames | Foreach {$_} | Select-Object -unique #get the unique values from the list of rule names
$rulenames = $rulenames | Foreach {$_} | Select-Object -unique #get the unique values from the list of rule names





$sources=@() #array to collect multiple source addresses
$destinations=@() #array to collect multiple destination addresses
$services=@( )#array to collect multiple services
#loop through the list of rule names and for each one, start the process of assembling the correct output
foreach ($rule in $rulenames){ 
       
    #taking the rule's name, sort through the full table where the rule name matches
    for ($j=0; $j -lt $rulesarray.count; $j++){
        if ($rulesarray[$j][2] -eq $rule) {
            try {
                if ($rulesarray[$j][0].ToString() -notcontains ""){$fromzone = $rulesarray[$j][0].ToString()}
                if ($rulesarray[$j][1].ToString() -notcontains ""){$tozone = $rulesarray[$j][1].ToString()}
                $name=$rule
                if ($rulesarray[$j][3].ToString() -notcontains ""){$sources += $rulesarray[$j][3].ToString()}
                if ($rulesarray[$j][4].ToString() -notcontains ""){$destinations += $rulesarray[$j][4].ToString()}
                if ($rulesarray[$j][5].ToString() -notcontains ""){$services += $rulesarray[$j][5].ToString()}
                if ($rulesarray[$j][6].ToString() -notcontains ""){$action = $rulesarray[$j][6].ToString()}

            } catch {
                # write-host "`t[ERROR] $_.exceptionmes"
            }

        }
    }

    #Print the line
        $Result = @{'Source IF' = $fromzone;
                    'Dest IF' = $tozone;
                    'Name' = $name;
                    'Src IP/Group/Any' = $sources -join ', ';
                    'Dest  IP/Group/Any'= $destinations -join ', ';
                    'Application' = $services -join ', ';
                    'Action' = $action
                    } 
        
        $Report = New-Object -TypeName PSObject -Property $Result
        #'"' + $fromzone + '","' + $tozone +  '","'  + $name + '","' + $sources + '","' + destinations + '","' + $services + '","' + $action + '"'  
        Write-Output $Report | select-object -Property 'Source IF','Dest IF','Name','Src IP/Group/Any','Dest  IP/Group/Any','Application','Action' | Export-CSV .\output.csv -append  -NoTypeInformation
        

        #Clear the variables for the next rule name
        $sources=@()
        $destinations=@()
        $services=@( )
 }