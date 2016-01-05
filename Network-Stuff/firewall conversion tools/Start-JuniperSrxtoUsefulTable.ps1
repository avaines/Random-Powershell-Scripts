#csv should have the columns 
#Use Excel to comvert the output of "show security policies | display xml | no-more | save /var/tmp/myexport.xml" to a CSV

<#
.SYNOPSIS
  
.DESCRIPTION
    Providing the source of "show security policies | display xml | no-more | save /var/tmp/myexport.xml" in either its native .xml format or first converting it to a CSV, will be moved to a more usable and searchable CSV format.
    The CSV that Excel will generate from this CSV will be multiple row for each rule, 1 row for each source, 1 row for each destination and 1 row for each application/service, 
    this script will push all the information for each given rule in to a single row.

    I figured out how to process XML data after I wrote the initial CSV conversion section so this just expands it and allows the XML to be specified instead


.OUTPUTS
    

.PARAMETER xml
    Specify an XML file

.PARAMETER csv
    Specify a CSV file

.SYNTAX
    Start-JuniperSrxToUsefulTable.ps1 [[-xml <path.xml>] {OR} [-csv <path.csv>]]

.EXAMPLE
    Start-JuniperSrxToUsefulTable.ps1 -xml myexport.xml
    Start-JuniperSrxToUsefulTable.ps1 -csv myconvertedexport.csv

.NOTE
    Created by Aiden Vaines (aiden@vaines.org)
    Dec 2015

#>
    
[CmdletBinding()]

Param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$xml, 
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$csv
)






function load-xml {
    #<COMPANY>
    #  <DEPTS>
    #    <DEPT>
    #       Sales
    #    </DEPT>            
    #    <EMPLOYEES>
    #      <NAME>CLARK</NAME>
    #      <NAME>MILLER</NAME>
    #      <NAME>KING</NAME>
    #    </EMPLOYEES>
    #  </DEPTS>
    #</COMPANY>


    # $d=([xml](gc employees.xml)).COMAPNY.DEPTS | where-object { 
    #   foreach ($i in $_.EMPLOYEES.NAME) {
    #     $o = New-Object Object
    #     Add-Member -InputObject $o -MemberType NoteProperty -Name DEPT -Value $_.DEPT
    #     Add-Member -InputObject $o -MemberType NoteProperty -Name NAME -Value $i
    #     $o
    #   }
    # }
    # $d
    Write-Host "Loading $xml`n"
    $CSVData=([xml](Get-Content $xml)).'rpc-reply'.configuration.security.policies.policy | where-object {
        foreach ($i in $_.policy){
            $obj = new-object object
        
            #write-host "`n"      
            #write-host "from-zone-name: `t`t" $_.'from-zone-name'
            #write-host "to-zone-name: `t`t`t" $_.'to-zone-name'
            #write-host "name: `t`t`t`t`t" $i.name
            #write-host "source-address: `t`t" $i.match.'source-address'
            #write-host "destination-address: `t" $i.match.'destination-address'
            #write-host "application: `t`t`t" $i.match.'application'
            #write-host "description: `t`t" $i.description
            #write-host "`n"
            #write-host $i

            add-member -inputobject $obj -MemberType NoteProperty -name from-zone-name -value $_.'from-zone-name'
            add-member -inputobject $obj -MemberType NoteProperty -name to-zone-name -value $_.'to-zone-name'
            add-member -inputobject $obj -MemberType NoteProperty -name name -value $i.name
            add-member -inputobject $obj -MemberType NoteProperty -name source-address -value $i.match.'source-address'
            $obj.'source-address' = $obj.'source-address' -join ", "
            add-member -inputobject $obj -MemberType NoteProperty -name destination-address -value $i.match.'destination-address'
            $obj.'destination-address' = $obj.'destination-address' -join ", "
            add-member -inputobject $obj -MemberType NoteProperty -name application -value $i.match.'application'
            $obj.application = $obj.application -join ", "
            add-member -inputobject $obj -MemberType NoteProperty -name description -value $i.description

            $obj | export-csv "rules.csv" -NoTypeInformation -Append -Encoding:UTF8
        }
        
    }  

}


function load-csv {

    Begin{
        $currentrule=""
        $currentsource=""
        $currentdestination=""

        $sources = @() 
        $destinations = @() 
        $services = @() 
    }

    Process {

        Write-Host "Loading $csv`n"
        try {
            $CSVData = import-csv -path $csv | Sort-Object name, from-zone-name, to-zone-name

        } catch {
            write-host "`t[ERROR] $_"

        }

    }
}


function Start-Conversion{

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

}      



try {
    if (!$xml -and $csv){
       load-csv
    }elseif ($xml -and !$csv){
        load-xml
        Start-Conversion
    }elseif ($xml -and $csv){}

}catch{
    write-host "`t[ERROR] $_.exceptionmes"
}

