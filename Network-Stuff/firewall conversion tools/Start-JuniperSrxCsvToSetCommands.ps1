#Use Excel to comvert the output of "show security policies | display xml | no-more | save /var/tmp/myexport.xml" to the Juniper Set command format


$csvData.Clear()

$CSVData = import-csv -path rules.csv


ForEach ($object in $CSVData) {

#Does the current rule match the last one processed?

    if ($object.name -match $currentrule){#Yes}{
        #No


        "set security policies from-zone " + $object.'from-zone-name' + " to-zone " + $object.'to-zone-name' + " policy " + $object.name + " then permit"
        $currentrule = $object.name
    }

    
    if (!$object.'destination-address'-and !$object.application){
        #Destination and Application are empty, implying this is a "Source Address"
        "set security policies from-zone " + $object.'from-zone-name' + " to-zone " + $object.'to-zone-name' + " policy " + $object.name + " match source-address " + $object.'source-address'
        
    }elseif (!$object.'source-address'-and !$object.application){
       
        #Source and Application are empty, implying this is a "Destination Address"
       "set security policies from-zone " + $object.'from-zone-name' + " to-zone " + $object.'to-zone-name' + " policy " + $object.name + " match destination-address " + $object.'destination-address'

    }elseif (!$object.'source-address'-and !$object.'destination-address'){
        
        #Source and destination are empty, implying this is a "Application"
        "set security policies from-zone " + $object.'from-zone-name' + " to-zone " + $object.'to-zone-name' + " policy " + $object.name + " match destination-address " + $object.'destination-address'
    }

    
   } 

        
