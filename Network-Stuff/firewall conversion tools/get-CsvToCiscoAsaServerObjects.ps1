#csv should have the columns 
#Server, Interface, IP, VLAN, Description

$csvData.Clear()
$result.clear()
$i=0

$CSVData = import-csv -path servers.csv

ForEach ($object in $CSVData) {
    #write-host $object
    
    #SVR_[NAME]_[VLAN]_[INT]								- SVR_adp-sec-mgt01_500_eth0:1
    $server = "SVR_" + $object.server + "_" + $object.VLAN + "_" +$object.interface 
    
    
    #ASA format
        #object network SVR_T2-QA-ouqawb01:eth0:0
        #host 172.31.6.10
        #description ouqawb01:eth0:0
    write-host "object network " $server
    write-host "host" $object.IP
    write-host "description" $object.Description

   } 

        
