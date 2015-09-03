# Excel-Tools
Import Excel cell or range to an Array

Import-Excel => 
	Tools for sending messages consitantly to multiple addresses when testing mail flow through Exchange servers with authentication
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

	
