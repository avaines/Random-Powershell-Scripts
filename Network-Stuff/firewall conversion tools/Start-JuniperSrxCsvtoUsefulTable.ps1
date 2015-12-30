#csv should have the columns 
#Use Excel to comvert the output of "show security policies | display xml | no-more | save /var/tmp/myexport.xml" to a CSV


$CSVData.Clear()

$currentrule=""
$currentsource=""
$currentdestination=""

$sources = @() 
$destinations = @() 
$services = @() 


Write-Host "Loading 'rules.csv'`n"
try {
    $CSVData = import-csv -path .\rules.csv | Sort-Object name, from-zone-name, to-zone-name
} catch {
    write-host "`t[ERROR] $_"
}



ForEach ($object in $CSVData) {
    # Debug   
    # "`n#####################################"
    # $object.name + "`t ==> `t" + $currentrule
    # $object.'from-zone-name' + "`t`t`t`t`t ==> `t" + $currentsource
    # $object.'to-zone-name' + "`t`t`t`t`t`t ==> `t" + $currentdestination
    # "All 3 checks: " + (($object.name -ne $currentrule) -and (($object.'from-zone-name' -ne $currentsource) -or ($object.'to-zone-name' -ne $currentdestination)))
    # "Check To: " + ($object.'from-zone-name' -ne $currentsource)
    # "Check From: " + ($object.'to-zone-name' -ne $currentdestination)
    # "`n#####################################"

    #Does the current rule match the last one processed?
    if (($object.name -ne $currentrule) -or (($object.'from-zone-name' -ne $currentsource) -or ($object.'to-zone-name' -ne $currentdestination))){
        
        #No
        #Dump the last object to file
        $Result = @{'Source IF' = $object.'from-zone-name';
                    'Dest IF' = $object.'to-zone-name';
                    'Name' = $object.name;
                    'Src IP/Group/Any' = $sources -join ', ';
                    'Dest  IP/Group/Any'= $destinations -join ', ';
                    'Application' = $services -join ', ';
                    } 
        
        $Report = New-Object -TypeName PSObject -Property $Result
        #'"' + $fromzone + '","' + $tozone +  '","'  + $name + '","' + $sources + '","' + destinations + '","' + $services + '"' 
        Write-Output $Report | select-object -Property 'Source IF','Dest IF','Name','Src IP/Group/Any','Dest  IP/Group/Any','Application' | Export-CSV .\output.csv -append -NoTypeInformation
        
        
        #Reset the arrays
        $sources = @() 
        $destinations = @() 
        $services = @() 
        
        $currentrule = $object.name
        $currentsource = $object.'from-zone-name'
        $currentdestination = $object.'to-zone-name'

    }
      
    
    if (!$object.'destination-address'-and !$object.application){
        #Destination and Application are empty, implying this is a "Source Address"
        #Store the source
        $sources += $object.'source-address' 

    }elseif (!$object.'source-address'-and !$object.application){
        #Source and Application are empty, implying this is a "Destination Address"
        #store the destinations
        $destinations += $object.'destination-address'

    }elseif (!$object.'source-address'-and !$object.'destination-address'){
        #Source and destination are empty, implying this is a "Application"
        #store the services
        $services += $object.application

    } 

    $currentrule = $object.name
    $currentsource = $object.'from-zone-name'
    $currentdestination = $object.'to-zone-name'


} 

        
