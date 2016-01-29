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
    #   foreach ($i in $_.EMPLOYEES.'policy-name') {
    #     $o = New-Object Object
    #     Add-Member -InputObject $o -MemberType NoteProperty -Name DEPT -Value $_.DEPT
    #     Add-Member -InputObject $o -MemberType NoteProperty -Name NAME -Value $i
    #     $o
    #   }
    # }
    # $d
    Write-Host "Loading $xml`n"
    $global:CSVData=([xml](Get-Content $xml)).'rpc-reply'.configuration.security.policies.policy | where-object {
        foreach ($i in $_.policy){
            $obj = new-object object
        
            #write-host "`n"      
            #write-host "from-zone-name: `t`t" $_.'source-zone-name'
            #write-host "to-zone-name: `t`t`t" $_.'destination-zone-name'
            #write-host "name: `t`t`t`t`t" $i.'policy-name'
            #write-host "source-address: `t`t" $i.match.'address-name'
            #write-host "destination-address: `t" $i.match.'address-name6'
            #write-host "application: `t`t`t" $i.match.'application'
            #write-host "description: `t`t" $i.description
            #write-host "`n"
            #write-host $i

            add-member -inputobject $obj -MemberType NoteProperty -name from-zone-name -value $_.'source-zone-name'
            add-member -inputobject $obj -MemberType NoteProperty -name to-zone-name -value $_.'destination-zone-name'
            add-member -inputobject $obj -MemberType NoteProperty -name name -value $i.'policy-name'
            add-member -inputobject $obj -MemberType NoteProperty -name source-address -value $i.match.'address-name'
            $obj.'address-name' = $obj.'address-name' -join ", "
            add-member -inputobject $obj -MemberType NoteProperty -name destination-address -value $i.match.'address-name6'
            $obj.'address-name6' = $obj.'address-name6' -join ", "
            add-member -inputobject $obj -MemberType NoteProperty -name application -value $i.match.'application-name'
            $obj.'application-name' = $obj.'application-name' -join ", "
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
            $global:CSVData = import-csv -path $csv | Sort-Object name, from-zone-name, to-zone-name

        } catch {
            write-host "`t[ERROR] $_"

        }

    }
}


function Start-Conversion{

    ForEach ($object in $global:CSVData) {
    # Debug   
    # "`n#####################################"
    # $object.'policy-name' + "`t ==> `t" + $currentrule
    # $object.'source-zone-name' + "`t`t`t`t`t ==> `t" + $currentsource
    # $object.'destination-zone-name' + "`t`t`t`t`t`t ==> `t" + $currentdestination
    # "All 3 checks: " + (($object.'policy-name' -ne $currentrule) -and (($object.'source-zone-name' -ne $currentsource) -or ($object.'destination-zone-name' -ne $currentdestination)))
    # "Check To: " + ($object.'source-zone-name' -ne $currentsource)
    # "Check From: " + ($object.'destination-zone-name' -ne $currentdestination)
    # "`n#####################################"



    #Does the current rule match the last one processed?
    if (($object.'policy-name' -ne $currentrule) -or (($object.'source-zone-name' -ne $currentsource) -or ($object.'destination-zone-name' -ne $currentdestination))){
        
        #No
        #Dump the last object to file
        $Result = @{'Source IF' = $object.'source-zone-name';
                    'Dest IF' = $object.'destination-zone-name';
                    'Name' = $object.'policy-name';
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
        
        $currentrule = $object.'policy-name'
        $currentsource = $object.'source-zone-name'
        $currentdestination = $object.'destination-zone-name'

    }
      
    
    if (!$object.'address-name6'-and !$object.'application-name'){
        #Destination and Application are empty, implying this is a "Source Address"
        #Store the source
        $sources += $object.'address-name' 

    }elseif (!$object.'address-name'-and !$object.'application-name'){
        #Source and Application are empty, implying this is a "Destination Address"
        #store the destinations
        $destinations += $object.'address-name6'

    }elseif (!$object.'address-name'-and !$object.'address-name6'){
        #Source and destination are empty, implying this is a "Application"
        #store the services
        $services += $object.'application-name'

    } 

    $currentrule = $object.'policy-name'
    $currentsource = $object.'source-zone-name'
    $currentdestination = $object.'destination-zone-name'


} 

}      



try {
    if (!$xml -and $csv){
       load-csv
       Start-Conversion
    }elseif ($xml -and !$csv){
       write-host "Old format XML is crap, use CSV method"
    }elseif ($xml -and $csv){}

}catch{
    write-host "`t[ERROR] $_.exceptionmes"
}

