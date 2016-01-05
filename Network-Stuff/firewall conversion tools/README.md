Firewall Conversion Tools
==============================================

Start-CiscoAsaObjectsToCsv.ps1
------------------------------
Converts ASA Network Objects to CSV format


Start-JuniperSrxCsvToSetCommands.ps1
------------------------------------
Use Excel to comvert the output of "show security policies | display xml | no-more | save /var/tmp/myexport.xml" to the Juniper Set command format
	
	
Start-JuniperSrxCsvtoUsefulTable.ps1
------------------------------------
Providing the source of "show security policies | display xml | no-more | save /var/tmp/myexport.xml" in either its native .xml format or first converting it to a CSV, will be moved to a more usable and searchable CSV format.
The CSV that Excel will generate from this CSV will be multiple row for each rule, 1 row for each source, 1 row for each destination and 1 row for each application/service, 
this script will push all the information for each given rule in to a single row.

I figured out how to process XML data after I wrote the initial CSV conversion section so this just expands it and allows the XML to be specified instead

	
Start-JuniperSrxSetFormatToUsefulTable.ps1
------------------------------------------
Convert firewall rules in the Set format of a Juniper SRX (v15) to a CSV file
**currently has issues**
