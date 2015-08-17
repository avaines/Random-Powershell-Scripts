<#
  .SYNOPSIS
    Accepts an array of data and returns an array of duplicates

  .DESCRIPTION
    Accepts an array of data and returns an array of duplicates

  .PARAMETER $array
    Mandatory. Path of where the excel sheet is to be loaded

  .PARAMETER count
    Lists how many of a particular duplicate have been found
  



  .OUTPUTS
    an array of duplicates will be returned

  .EXAMPLE

    Get-Duplicates $MySourceArray -count
        ~or~
    $Duplicates = Get-Duplicates $MySourceArray
    write-host "The following duplicates were found: " $Duplicates-join(", ")

  .NOTE
    


#>


Function Get-Duplicates {
    param($workload, [switch]$count)
    begin {
        $store = @{}
    }
    process {
        $workload | foreach{ $store[$_] = $store[$_] + 1 }
        if($count) {
            $store.GetEnumerator() | Where-Object{$_.value -gt 1} | foreach{
                $duplicates = New-Object PSObject -Property @{
                    Value = $_.key
                    Count = $_.value
                }
            }
        }
        else {
            $store.GetEnumerator() | Where-Object{$_.value -gt 1} | foreach{$_.key}
        }  
        return $duplicates  
    }
    
}