function Get-NetworkObjects{
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
        $ASAServiceObjects -split “`r`n” | foreach { 
            
            
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

Get-NetworkObjects