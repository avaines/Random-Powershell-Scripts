<#
  .SYNOPSIS
    Import data from an  Excel spreadsheet based on a given worksheet and cell or range of cells

  .DESCRIPTION
    Imports an Excel spreadsheet and returns an array of requested cell and/or range of cells

  .PARAMETER Path
    Mandatory. Path of where the excel sheet is to be loaded

  .PARAMETER Workbook
    Mandatory. Name of Workbook the data is located in
      
  .PARAMETER Cell
    Optional. Reference of the cell to load data from in Excel format e.g. G12 (Default is A1)
          
  .PARAMETER Range
    Optional. Reference of the range to load data from in Excel format e.g. G12:H19

  .PARAMETER debug
    Optional. Enables Verbose output

  .INPUTS
    Parameters above

  .OUTPUTS
    $ExcelData returned containing cell data as a string in $ExcelData[0] and range data as an array in $ExcelData[1]

  .EXAMPLE
           
            write-host "Loading workbook"
        Start-LoadExcel -Path "Test.xlsx" # -debug

            write-host "Getting list of worksheets"
        $ExcelWorksheets = Get-worksheets #-debug
            write-host "My file's worksheets are in the string ExcelWorksheets: " $ExcelWorksheets

            write-host "Finding Excel cell and range references"
        $ExcelData = Get-ExcelData -Worksheet "MySheet"  -Cell "I7" -Range "A2:I15" #-debug
            write-host "My Cell's data is in the string ExcelData[0]: " 
        $ExcelData[0]
            write-host "My Range's data is in the array ExcelData[1]: " 
        $ExcelData[1]
            
            write-host "Closing workbook"
        Start-CloseExcel #-debug

  .NOTE
    Only works if Excel is installed

#>


Function Start-LoadExcel ([string]$Path, [switch]$debug) {
    if($debug){
        Write-Host "`tLoading $Path..."
    }
    try {
        $Global:Path = Resolve-Path $Path
        $Global:ExcelCOM = New-Object -com "Excel.Application"
        $Global:ExcelCOM.Visible = $false
        $Global:WorkBook = $Global:ExcelCOM.workbooks.open($Global:Path)
    } catch {
        if($debug){
            write-host "`t[ERROR] $_.exceptionmes"
        } 
    }
 }
    

Function Get-worksheets ([switch]$debug) {
    #Check is a sheet as been specified and use the 1st in the workbook if not
        
    try{
        if($debug){
            write-host "`tParsing available workbooks"
        }
            
        $AWSheets += @()
        foreach ($AWSheet in $Global:Workbook.Worksheets){
            $AWSheets += @($AWSheet.Name)
        }
            

        if($debug){
            write-host "`tFound $AWSheets"
        }
        return $AWSheets

    } catch {
        if($debug){
            write-host "`t[ERROR] $_.exceptionmessage"
        }
   
    } #End catch
  
	
} #End Function


Function Get-ExcelData ([string]$WorkSheet, [string]$Cell, [string]$Range, [switch]$debug) {    #removed [string]$Path, 
 
        #Check is a sheet as been specified and use the 1st in the workbook if not
        try {
            $ActiveWorksheet = $Worksheet.ActiveSheet
            $ActiveWorksheet = $WorkBook.Sheets.Item($WorkSheet)
        
        } Catch {
            if($debug){
                write-host "`t[Error] $WorkSheet was unable to be loaded, $_.exceptionmessage"
            }
        }
        


        #No Cell specified
        If (-not $Cell){
            if($debug){
                Write-Host "`tNo cell specified, defaulting to cell A1 (Cell might not be required output but we need one or the output is not right"
                $CellColumn = "A"
                $CellRow = "1"
            }
        }   
          
        if($debug){
            write-host "`tOpening worksheet..."
        }

	    $AWName = $ActiveWorksheet.Name
	    $AWColumns = $ActiveWorksheet.UsedRange.Columns.Count
	    $AWLines = $ActiveWorksheet.UsedRange.Rows.Count
        

        if($debug){
  	        write-host "`tWorksheet $AWName contains $AWColumns columns and $AWLines lines of data"
        }
    

        if ($cell){
            try {
                if($debug){
  	                write-host "`t Locating $Cell"
                }
                $CellData = $ActiveWorksheet.Cells.Range($Cell).text
                
                
                if($debug){
  	                write-host "`t`t Found $CellData"
                }
            }
            Catch {
                if($debug){
                    write-host "`t `t[Error] $WorkSheet was unable to be loaded, $_.exceptionmessage"
                }
            }
    
        }

        if ($Range){
            if($debug){
                write-host "`t Locating $Range"
            }
          

            #Split the range up from A2:B3 format to to the column and row references and then convert the leters to the numerical value
            $ColumnStart = ($($Range -split ":")[0] -replace "[0-9]", "").ToUpperInvariant()
            $ColumnEnd = ($($Range -split ":")[1] -replace "[0-9]", "").ToUpperInvariant()
            [int]$RowStart = $($Range -split ":")[0] -replace "[a-zA-Z]", ""
            [int]$RowEnd = $($Range -split ":")[1] -replace "[a-zA-Z]", ""

            #convert the numerical value to their relative possition
            $ColumnStart = Get-ExcelColumnInt $ColumnStart
            $ColumnEnd = Get-ExcelColumnInt $ColumnEnd
            $Columns = $ColumnEnd - $ColumnStart + 1

            #Get the System_COM object of the Range we want
            $areas = $ActiveWorkSheet.Range($Range).Areas

            #If the end row or column is not specified set it to 0
            if($RowEnd -eq $null){
                $RowEnd = 0 
            }
            if($ColumnEnd -eq $null){
                $ColumnEnd = 0
            }

            #Define some arrows
            $rowIndexes = @()
            $columnIndexes = @()
            $headers = @{} #Array for the headers
            $psAreas = @()


            foreach($area in $areas){
                $value = $null
                if($area.Rows.Count -eq 1 -and $area.Columns.Count -eq 1)
                {
                    $value = New-Object "object[,]" 2,2
                    $value[1,1] = $area.Value()
                }
                else
                {
                    $value = $area.Value()
                }

                if($area.Row -le $RowEnd){
                    $psAreas += New-Object PSObject |
                                Add-Member NoteProperty Value $value -PassThru |
                                Add-Member NoteProperty FirstRow $RowStart  -PassThru |
                                Add-Member NoteProperty LastRow $RowEnd  -PassThru |
                                Add-Member NoteProperty FirstColumn $ColumnStart  -PassThru |
                                Add-Member NoteProperty LastColumn $ColumnEnd -PassThru

                    $rowIndexes += (@($RowStart .. $RowEnd) -ne $headerRow)
                    $columnIndexes += @($ColumnStart .. $ColumnEnd)
                }
     
                #Quit if Area isn't a COM object                   
                [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($area) | Out-Null
                trap {
        
                    [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($area) | Out-Null
                    break
                }
            }
        
            foreach($c in $columnIndexes | sort -Unique) {
                $headers[$c] = ($ActiveWorkSheet.Columns.item($c).Address($true, $false) -split ':')[0]

                if($HeaderRow -gt 0){
                    $text =$ActiveWorkSheet.Cells.Item($HeaderRow, $c).Value()
                    if($text -ne $null){                    
                        if($headers[$headers.Keys -ne $c] -contains $text){
                            $text = "$text`_$c"}
                        $headers[$c] = $text
                    }
                }
            }
 
            foreach($r in $rowIndexes | sort -Unique)
            {
                $pso = New-Object PSObject
            
                if($IncludeSheetName)
                {
                    $pso | Add-Member NoteProperty "Sheet"$ActiveWorkSheet.Name
                }
            
                foreach($c in $columnIndexes | sort -Unique)
                {
                    $propertyName = $headers[$c]
                    $pso | Add-Member NoteProperty $propertyName $null
                    $psAreas |
                        Where-Object{ $r -ge $_.FirstRow -and $r -le $_.LastRow -and $c -ge $_.FirstColumn -and $c -le $_.LastColumn } |
                        foreach-object{ $pso.$propertyName = $_.Value[($r - $_.FirstRow + 1), ($c - $_.FirstColumn + 1)] }
                }

                $RangeData += @($pso)
            }

            [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($ActiveWorkSheet) | Out-Null
            [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($areas) | Out-Null
            trap{
                [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($ActiveWorkSheet) | Out-Null
                [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($areas) | Out-Null
                break
            }


        }  #End if range

    return $CellData, $RangeData #| Out-Null  #Return values and supress the output
    
}


Function Start-CloseExcel([switch]$debug) {
    if($debug){
        Write-Host "`tClosing $Global:Path..."
    }
    try {
        $Global:ExcelCOM.Quit()
    } catch {
        if($debug){
            write-host "`t[ERROR] $_.exceptionmes"
        } 
    }
 }


Function Get-ExcelColumnInt {
# Thanks to http://stackoverflow.com/questions/667802/what-is-the-algorithm-to-convert-an-excel-column-letter-into-its-number
	[cmdletbinding()]
		param($ColumnName)
	[int]$Sum = 0
	for ($i = 0; $i -lt $ColumnName.Length; $i++)
	{ 
		$sum *= 26
		$sum += ($ColumnName[$i] - 65 + 1)
	}
	$sum
}

