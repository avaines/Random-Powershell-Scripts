<#
  .SYNOPSIS
    Bulk updating DNS based on a CSV file called "DNS.csv" formatted as follows (Only the column names matter):
        CURRENT NAME,CURRENT IP,=>,NEW NAME
        server1,192.168.1.10,=>,old_server1
        server2,192.168.1.12,=>,old_server2
        server3,192.168.1.13,=>,old_server3
        server4,192.168.1.14,=>,old_server4
        new_server1,192.168.10.10,=>,server1
        new_server2,192.168.10.12,=>,server2
        new_server3,192.168.10.13,=>,server3
        new_server4,192.168.10.14,=>,server4
        ,192.168.20.10,=>,test_server1
        ,192.168.20.12,=>,test_server2



  .DESCRIPTION
    Providing a csv formatted as above and updating the $zonename variable below, all DNS entries will be updated, if no current name is specified
    a new record will be created.

    Script activly checks it is not going to create an entry for IPs or Host Names that already exist, if renaming a hostname and creating a new one
    with the same name, make sure the rename is above the creation in the CSV or the operation will fail for that entry.
  
  
  .OUTPUTS
    All screen output

  .NOTE
    Created by Aiden Vaines (aiden@vaines.org)
    Nov 2015
#>




#Edit to change DNS Zone"
$zonename="test.local"









#Load CSV to data
try {
    $CSVData = import-csv "DNS.csv"
    $csvdata
    write-host "`n`n"
}catch{
    write-host "`t[ERROR] $_.exception.message"
}


#Check out each record in turn
foreach ($record in $CSVData){
    try {
        
        #Is the current name blank implying this is a new record?
        if($record."CURRENT NAME"){
            #CURRENT NAME is not empty
            "`nR `t The A record for " + $record."CURRENT NAME" + " (" + $record."CURRENT IP" +") will be renamed " + $record."NEW NAME"
            try {
                    $OldRecord = Get-DnsServerResourceRecord -Name $record."CURRENT NAME" -ZoneName $zonename -RRType "A" -ErrorAction SilentlyContinue
                    
                    #Check the record we are going to rename matches the spreadsheet IP and IP listed in DNS
                    if ($OldRecord.RecordData.IPv4Address -eq $record.'CURRENT IP') {
                        
                        #Check the new name for teh record doesnt already exist
                        if (get-dnsserverresourcerecord -zonename $zonename |where-object {$_.hostname -eq $record.'NEW NAME'}) {
                            
                            write-host "`t`t Failed: [WARNING] New hostname already exists"
                        
                        } else {
                                Remove-DnsServerResourceRecord -inputobject $OldRecord -ZoneName $zonename -Force
                    
                                Add-DnsServerResourceRecord -ZoneName $zonename -Name $record."NEW NAME" -A -IPv4Address $record."CURRENT IP"
                                
                                write-host "`t`t Successful"
                        }

                    } else {
                       
                            write-host "`t`t Failed: [WARNING] IP Address missing or did not match record in DNS"
                    
                    }
                
                }catch{
                    write-host "`t`t Failed: [ERROR]" $_.Exception.Message
                }


        } else {
            #CURRENT NAME is empty
            #Report the new record to be added
            "`nN `t Creating A record for " + $record."NEW NAME" + " (" + $record."CURRENT IP" +")"
                
                #Create the record
                try {
                    #Check to see if the IP is already in use when its not expected to be
                    if (get-dnsserverresourcerecord -zonename $zonename |where-object {$_.recorddata.ipv4address.IPAddressToString -eq $record.'CURRENT IP'}) {
                        "`t `t Failed: [WARNING] " + $record."CURRENT IP" + "is in use already, please check DNS"
                    } else {

                        Add-DnsServerResourceRecord -ZoneName $zonename -Name $record."NEW NAME" -A -IPv4Address $record."CURRENT IP"
                        write-host "`t`t Successful"
                    }

                }catch{
                    write-host "`t`t Failed: [ERROR]" $_.CategoryInfo.Category
                }
                

        }

        
    }catch{
        write-host "`t[ERROR] $_.exception.message"
    }
    

}
"`n"
pause