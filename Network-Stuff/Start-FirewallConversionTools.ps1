<#
.SYNOPSIS
    Tools for converting ASA and Juniper code to and from each other and CSV files
 
.DESCRIPTION
    Tools for converting ASA and Juniper code to and from each other and CSV files:
    1) Convert ASA Service Objects
      (Supply ASA config service objects, outputs Juniper config)

    2) Convert ASA Host Objects - BETA
      (Supply ASA config host objects, outputs Juniper config)

    3) Convert CSV list of Firewall rules to ASA format
      (Supply CSV formatted 'Server, Interface IP VLAN Description' outputs ASA host objects)

    4) Convert CSV list of Firewall rules to Juniper format - DOESNT WORK
      (Supply CSV formatted 'Server, Interface IP VLAN Description' outputs Juniper host objects)

    5) Convert ASA ASDM rule export into standardised firewall rule format
      (Supply ASDM export, output is in standard documentation format)

    6) Convert Junos config into standardised firewall rule format
      (Supply ASDM export, output is in standard documentation format)

.PARAMETER  
    None
 
.EXAMPLE
    Use Menu
     
.NOTES
    Author: Aiden Vaines
    Date: 23/07/2015
    Email: aiden@vaines.org
 #>




function Get-ServiceObjects{
    Begin
    {
        write-host "Converts ASA Service Objects to the Juniper 'Set' format"
        write-host ""
        $asafile = read-host "Enter filename of ASA config"
        $ASAServiceObjects = get-content $asafile
    }
    Process {
        $ASAServiceObjects -split "`r`n"  | foreach { 
            #If its an object definition
            if ($_ -match "object service"){
                #deals with service object definitions
                $svcname = $_.split(" ")[2]
                $outputtype=0

            }elseif ($_ -match "destination") {
                $svcproto = $_.split(" ")[3]
                $svcdest = $_.split(" ")[4]
                $svctype = $_.split(" ")[5]
                $svcport = $_.split(" ")[6]
                #If it's a range, get the end port and put them together like 1000-2000
                if ($svctype -eq "range"){               
                    $svcendport =$_.split(" ")[6]
                    $svcport=$svcport + "-" + $svcendport -join ','
                }
                $outputtype=1

            }elseif ($_ -match "object-group"){
                #deal with groups
                $grpname = $_.split(" ")[2]
                #no outpot for the group names, see the group objects

            }elseif ($_ -match "service-object object"){ 
                #deal with group objects
                $grpobject = $_.split(" ")[4]
                $outputtype=2
            }

            #output
            switch ($outputtype){
                0 {"set applications application " + $svcname + " protocol " + $svcproto -join ','}
                1 {"set applications application " + $svcname +" destination-port " + $svcport  -join ','}
                2 {"set applications application-set " + $grpname + " application " + $grpobject -join ''}
               
            }
        }
    }
}


function Get-HostObjects{
    Begin
    {
        $asafile.clear
        write-host "Converts ASA Host Objects to the Juniper 'Set' format"
        write-host "Hostnames are expected in 'SVR_hostname_vlan_eth0:0' format"
        $asafile = read-host "Enter filename of ASA config"
        $ASAHostObjects = get-content $asafile
    }
    Process {
        $ASAHostObjects -split "`r`n"  | foreach { 
         #If its an object definition
            if ($_ -match "object network"){
                #echo $_
                $svrname = $_.split(" ")[2]
                $svrzone = $svrname.split("_")[2]
            }elseif ($_ -match " host"){
                    $svrip = $_.split(" ")[2]
            }elseif ($_ -match " description"){
                    $svrdescription = $_.split(" ")[2]           
            } 
        }

        #OPTIONAL:
        #Replaces vlan in server object with actuall zone's address book
            #if ($svrzone -match "T2-CITE"){
            #    $svrzone = "SMB_103_PRD_T2-CITE"
            #         
            #}elseif ($svrzone -match "T2-Prod"){
            #   $svrzone = "SMB_101_PRD_T2-Prod"
            #    
            #}else{
            #   $svrzone = "SMB_120_LNK_T1-T2-FRW"
            #
            #}
            #
            #
            #"set security zones security-zone " + $svrzone + " address-book address " + $svrname + " " + $svrip  + "/32" -join ','
                           
    }    

}



function Get-CsvToAsaHosts{
    Begin
    {
        $csvData.Clear()
        $result.clear()
        $i=0
        
        write-host "Supply CSV outputs ASA host objects"
        write-host "CSV should be formatted 'Server, Interface, IP, VLAN, Description' outputs ASA host objects"
       
        $CSVDataPath = read-host "Enter filename of CSV"
        $CSVData = import-csv -path $CSVDataPath
    }
    Process {
        ForEach ($object in $CSVData) {  
            #SVR_[NAME]_[VLAN]_[INT]
            $server = "SVR_" + $object.server + "_" + $object.VLAN + "_" +$object.interface 
    
            #ASA format
                #object network SVR_T2-QA-ouqawb01:eth0:0
                #host 172.31.6.10
                #description ouqawb01:eth0:0
            write-host "object network " $server
            write-host "host" $object.IP
            write-host "description" $object.Description

        } 
    }
}


function Get-CsvToJunosHosts{
    Begin
    {
    }
    Process {
    }
}



function Get-AsaToCSV{
    Begin
    {
        $csvData.Clear()
        
        write-host "Supply ASA export to be converted"

        $CSVDataPath = read-host "Enter filename of CSV"
        $CSVData = import-csv -path $CSVDataPath
    }
    Process {
        ForEach ($object in $CSVData) {
           
            [string]$SourceInt = $object.Interface
            [string]$SourceInt = $SourceInt.split("(")[0]
        
            $Result = @{'Source IF' = $SourceInt -join ', ';
                        'Dest IF' = "";
                        'Src IP/Group/Any' = $object.Source.split(",") -join ', ';
                        'Dest  IP/Group/Any'= $object.Destination.split(",") -join ', ';
                        'Application' = $object.Service.split(",") -join ', ';
                        'Action' = $object.Action.split(",") -join ', ';
                        'Comment' = $object.Description.trim("[","]") -join ', '
                        } 
    
            $Report = New-Object -TypeName PSObject -Property $Result  
            Write-Output $Report | select-object -Property 'Source IF','Dest IF','Src IP/Group/Any','Dest  IP/Group/Any','Application','Action','Comment' | Export-CSV .\output.csv -append -notype
    
        } 
    }
}



function Get-JunosToCSV{
    Begin
    {
        $csvData.Clear()
        
        write-host "Supply Juniper config to be converted"
        write-host "CSV should be formatted 'Server, Interface, IP, VLAN, Description' outputs ASA host objects"
        
        $SRXConfigPath = read-host "Enter filename of config file"
        $SRXConfig = import-csv -path $SRXConfigPath
    }
    Process {
        #Stores the whole rules table as a jagged array in format:
        #(fromZone, toZone, Name, Source, Destination, Service, Action)
        $rulesarray = @() 
        $SRXConfig -split "`r`n"  | foreach { 
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
                    if ($rulesarray[$j][0].ToString() -notcontains ""){$fromzone = $rulesarray[$j][0].ToString()}
                    if ($rulesarray[$j][1].ToString() -notcontains ""){$tozone = $rulesarray[$j][1].ToString()}
                    $name=$rule
                    if ($rulesarray[$j][3].ToString() -notcontains ""){$sources += $rulesarray[$j][3].ToString()}
                    if ($rulesarray[$j][4].ToString() -notcontains ""){$destinations += $rulesarray[$j][4].ToString()}
                    if ($rulesarray[$j][5].ToString() -notcontains ""){$services += $rulesarray[$j][5].ToString()}
                    if ($rulesarray[$j][6].ToString() -notcontains ""){$action = $rulesarray[$j][6].ToString()}
                }
            }

            #Print the line
            $Result = @{'Source IF' = $fromzone;
                    'Dest IF' = $tozone;
                    'Src IP/Group/Any' = $sources -join ', ';
                    'Dest  IP/Group/Any'= $destinations -join ', ';
                    'Application' = $services -join ', ';
                    'Action' = $action;
                    'Comment' = $name
                    } 
        
            $Report = New-Object -TypeName PSObject -Property $Result
            #'"' + $fromzone + '","' + $tozone + '","' + $sources + '","' + $destinations + '","' + $services + '","' + $action + '","'  + $name + '"'  
            Write-Output $Report | select-object -Property 'Source IF','Dest IF','Src IP/Group/Any','Dest  IP/Group/Any','Application','Action','Comment' | Export-CSV .\output.csv -append  -NoTypeInformation
            
            #Clear the variables for the next rule name
            $sources=@()
            $destinations=@()
            $services=@( )
        }

    }
}

function Get-ASANetworkObjects{
    Begin
    {
        write-host "Converts ASA Network Objects to CSV format"
        write-host ""
        $asafile = read-host "Enter filename of ASA config"
        $ASAServiceObjects = get-content $asafile
    }
    Process {
        $Counter=0
        $object = ""
        $objectip = ""
        write-host "Exporting to output.csv"
        $ASAServiceObjects -split "`r`n" | foreach { 
            
            
            #If its an object definition
            if ($_ -match "object network"){
                if ($Counter -eq 0) {
                    $object = ""
                    $object = $_.split(" ")[2]
                    $outputtype=0
                    $counter = 1
                }

            }elseif ($_ -match "host") {
                if ($counter -eq 1) {
                    $objectip = ""
                    $objectip = $_.split(" ")[2]
                    $outputtype = 0
                    $counter = 0
                }
            }

            #output

            switch ($outputtype){
                0 {
                    if ($object -ne "" -AND $objectip -ne ""){
                        $object + ', ' + $objectip | out-file .\output.csv -append
                        $object = ""
                        $objectip = ""
                    }
                }
                
               
            }
        }
    }
}






while ($x =! 0){
    clear
        write-host ""
        write-host "Application"
        write-host "-----------"
        write-host "1) Convert ASA Service Objects"
        write-host "  (Supply ASA config service objects, outputs Juniper config)"
        write-host ""
        Write-host "2) Convert ASA Host Objects - BETA"
        write-host "  (Supply ASA config host objects, outputs Juniper config)"
        write-host ""
        write-host "3) Convert CSV list of Firewall rules to ASA format"
        write-host "  (Supply CSV formatted 'Server, Interface IP VLAN Description' outputs ASA host objects)"
        write-host ""
        write-host "4) Convert CSV list of Firewall rules to Juniper format - DOESNT WORK"
        write-host "  (Supply CSV formatted 'Server, Interface IP VLAN Description' outputs Juniper host objects)"
        write-host ""
        write-host "5) Convert ASA ASDM rule export into standardised firewall rule format"
        write-host "  (Supply ASDM export, output is in starndard documentation format)"
        write-host ""
        write-host "6) Convert Junos config into standardised firewall rule format"
        write-host "  (Supply ASDM export, output is in starndard documentation format)"
        write-host ""
        write-host "7) Convert ASA config into CSV of network objects and IPs"
        write-host "  (Supply ASDM export, output is in CSV format)"
        write-host ""


    while ($choice -notmatch "[1234567]"){
        $choice = read-host "Select Application"
    }
    switch ($choice){
            1{Get-ServiceObjects}
            2{Get-HostObjects}
            3{Get-CsvToAsaHosts}
            4{Get-CsvToJunosHosts}
            5{Get-AsaToCSV}
            6{Get-JunosToCSV}
            7{Get-ASANetworkObjects}

            default{write-host "Invalid selection, exiting"}
    }

    " "
    pause
    $choice = ""

}



