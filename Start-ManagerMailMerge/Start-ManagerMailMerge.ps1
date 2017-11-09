<#
.SYNOPSIS
    Script to email manager a report of related staff given a CSV file and HTML formatted email

.DESCRIPTION
    Script to email manager a report of related staff given a CSV file and HTML formatted email
    where the source.csv file is structured with the following headings:
        ID,Name,Device,ManagerID,ManagerName,ManagerEmail
    
    ...and the template file is a worddocument saved as htm file type

.PARAMETER  Param
    Brief description of parameter input required, repeat this section as required
     
.NOTES
    Author:     Aiden Vaines
    Purpose:    Bulk email to managers regarding their staff based on a given list
    
    Date        Change
    09/11/2017  1st script draft

 #>
 
 #[CmdletBinding()]
 #   Param (
 #       [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Word
# 
#    )

# Load modules and related files
try{ 
    # Create a list of system Variables already in place before running the script,
    # Will be used to clear any session variables
    $SystemVars = Get-Variable | Where-Object{$_.Name}

    # 'cd' to execution dir
    Set-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
        

    # DotSource the configfile
    . ".\Config.ps1" 

    ########
    # Logging:
    # Load the logging module and set the log path so all the other scripts use it
    . ".\Modules\Init-Logging.ps1"
    
    # Initialize the log
    Log-Start -logpath $Script:LogPath
    ########

    # Load the other modules in the module folder (except the Logging module as that is already loaded)
    ##############
    $Modules = Get-ChildItem ".\Modules\" | Where-Object {$_.name -ne "Init-Logging.ps1"}
        
    foreach ($Module in $Modules){  
        $ModuleName = $Module.Name
        Log-write -logpath $Script:LogPath -linevalue "Loading Module: $ModuleName"
        . ".\Modules\$ModuleName"
    }

    
}catch{ 

    Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $True

}


try{

    #####################################
    # MAIN SCRIPT BLOCK BEGINS HERE.....#
    #####################################
    
    #mail/doc?
    #send?
    $MailSubject = "TestMailSubject"
    #Load Source Data
    Log-write -logpath $Script:LogPath -linevalue "Loading Source data"
    $SourceData = import-csv .\source.csv

    #Assume this is a mail template
    Log-write -logpath $Script:LogPath -linevalue "Loading MS Outlook..."
    $Outlook = new-object -comobject outlook.application

    Log-write -logpath $Script:LogPath -linevalue "Loading mail template"
    #$MailTemplate = $Outlook.session.openshareditem(".\_template.msg")
    $MailTemplate = get-content .\_template.htm

    #Structure file
    Log-write -logpath $Script:LogPath -linevalue "Locating unique managers"
    foreach ($ManagerID in $Sourcedata.ManagerID | sort-object -unique){
        #New file for managername
        Log-write -logpath $Script:LogPath -linevalue "`tWorking with $ManagerID"
        $managerEmail = ($sourcedata | where-object ManagerID -eq $ManagerID).ManagerEmail | sort-object -unique [0]
        $managerName =  ($sourcedata | where-object ManagerID -eq $ManagerID).ManagerName | sort-object -unique [0]
        

        #Assemble the table
        Log-write -logpath $Script:LogPath -linevalue "`t`tBuilding Employee Table"
        $EmployeeData = $sourcedata | where-object ManagerID -eq $ManagerID | select-Object ID, Name, Device

        $EmployeeDataHtml="<table class=MsoTable15Grid4Accent1 border=1 cellspacing=0 cellpadding=0
        style='border-collapse:collapse;border:none;mso-border-alt:solid #9CC2E5 .5pt;
        mso-border-themecolor:accent1;mso-border-themetint:153;mso-yfti-tbllook:1184;
        mso-padding-alt:0cm 5.4pt 0cm 5.4pt'>"


        $EmployeeDataHtml+="<tr style='mso-yfti-irow:-1;mso-yfti-firstrow:yes;mso-yfti-lastfirstrow:yes'>
        <td width=152 valign=top style='width:114.3pt;border:solid #5B9BD5 1.0pt;
        mso-border-themecolor:accent1;border-right:none;mso-border-top-alt:solid #5B9BD5 .5pt;
        mso-border-top-themecolor:accent1;mso-border-left-alt:solid #5B9BD5 .5pt;
        mso-border-left-themecolor:accent1;mso-border-bottom-alt:solid #5B9BD5 .5pt;
        mso-border-bottom-themecolor:accent1;background:#5B9BD5;mso-background-themecolor:
        accent1;padding:0cm 5.4pt 0cm 5.4pt'>
        <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
        normal;mso-yfti-cnfc:5'><b><span style='color:white;mso-themecolor:background1'>Global
        ID Number<o:p></o:p></span></b></p>
        </td>
        <td width=175 valign=top style='width:131.55pt;border-top:solid #5B9BD5 1.0pt;
        mso-border-top-themecolor:accent1;border-left:none;border-bottom:solid #5B9BD5 1.0pt;
        mso-border-bottom-themecolor:accent1;border-right:none;mso-border-top-alt:
        solid #5B9BD5 .5pt;mso-border-top-themecolor:accent1;mso-border-bottom-alt:
        solid #5B9BD5 .5pt;mso-border-bottom-themecolor:accent1;background:#5B9BD5;
        mso-background-themecolor:accent1;padding:0cm 5.4pt 0cm 5.4pt'>
        <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
        normal;mso-yfti-cnfc:1'><b><span style='color:white;mso-themecolor:background1'>Name<o:p></o:p></span></b></p>
        </td>
        <td width=179 valign=top style='width:134.55pt;border:solid #5B9BD5 1.0pt;
        mso-border-themecolor:accent1;border-left:none;mso-border-top-alt:solid #5B9BD5 .5pt;
        mso-border-top-themecolor:accent1;mso-border-bottom-alt:solid #5B9BD5 .5pt;
        mso-border-bottom-themecolor:accent1;mso-border-right-alt:solid #5B9BD5 .5pt;
        mso-border-right-themecolor:accent1;background:#5B9BD5;mso-background-themecolor:
        accent1;padding:0cm 5.4pt 0cm 5.4pt'>
        <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
        normal;mso-yfti-cnfc:1'><b><span style='color:white;mso-themecolor:background1'>Device<o:p></o:p></span></b></p>
        </td>
       </tr>"
        
       #Create each row in the table
        foreach($row in $EmployeeData){
            $EmployeeDataHtml+="<tr style='mso-yfti-irow:0;mso-yfti-lastrow:yes'>
            <td width=152 valign=top style='width:114.3pt;border:solid #9CC2E5 1.0pt;
            mso-border-themecolor:accent1;mso-border-themetint:153;border-top:none;
            mso-border-top-alt:solid #9CC2E5 .5pt;mso-border-top-themecolor:accent1;
            mso-border-top-themetint:153;mso-border-alt:solid #9CC2E5 .5pt;mso-border-themecolor:
            accent1;mso-border-themetint:153;background:#DEEAF6;mso-background-themecolor:
            accent1;mso-background-themetint:51;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
            normal;mso-yfti-cnfc:68'><span style='mso-bidi-font-weight:bold'>$($row.ID)<o:p></o:p></span></p>
            </td>
            <td width=175 valign=top style='width:131.55pt;border-top:none;border-left:
            none;border-bottom:solid #9CC2E5 1.0pt;mso-border-bottom-themecolor:accent1;
            mso-border-bottom-themetint:153;border-right:solid #9CC2E5 1.0pt;mso-border-right-themecolor:
            accent1;mso-border-right-themetint:153;mso-border-top-alt:solid #9CC2E5 .5pt;
            mso-border-top-themecolor:accent1;mso-border-top-themetint:153;mso-border-left-alt:
            solid #9CC2E5 .5pt;mso-border-left-themecolor:accent1;mso-border-left-themetint:
            153;mso-border-alt:solid #9CC2E5 .5pt;mso-border-themecolor:accent1;
            mso-border-themetint:153;background:#DEEAF6;mso-background-themecolor:accent1;
            mso-background-themetint:51;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
            normal;mso-yfti-cnfc:64'><span class=SpellE>$($row.Name)</span></p>
            </td>
            <td width=179 valign=top style='width:134.55pt;border-top:none;border-left:
            none;border-bottom:solid #9CC2E5 1.0pt;mso-border-bottom-themecolor:accent1;
            mso-border-bottom-themetint:153;border-right:solid #9CC2E5 1.0pt;mso-border-right-themecolor:
            accent1;mso-border-right-themetint:153;mso-border-top-alt:solid #9CC2E5 .5pt;
            mso-border-top-themecolor:accent1;mso-border-top-themetint:153;mso-border-left-alt:
            solid #9CC2E5 .5pt;mso-border-left-themecolor:accent1;mso-border-left-themetint:
            153;mso-border-alt:solid #9CC2E5 .5pt;mso-border-themecolor:accent1;
            mso-border-themetint:153;background:#DEEAF6;mso-background-themecolor:accent1;
            mso-background-themetint:51;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
            normal;mso-yfti-cnfc:64'><span class=SpellE>$($row.Device)</span></p>
            </td>
           </tr>"
        }
        
        $EmployeeDataHtml+="</table>"
        $EmployeeDataHtml = $EmployeeDataHtml | out-string

        Log-write -logpath $Script:LogPath -linevalue "`t`tAssembling template"
        #Assemble manager template
        $ManagerMailTemplate = $MailTemplate | out-string

        $ManagerMailTemplate = $ManagerMailTemplate.replace("UNIQUE_MARKER_MgrName", $managerName `
        ).replace("UNIQUE_MARKER_TableHere", $EmployeeDataHtml )

        #Create message
        Log-write -logpath $Script:LogPath -linevalue "`t`tSaving draft message"
        $ManagerMailDocument = $Outlook.CreateItem(0)
        $ManagerMailDocument.To = $managerEmail
        $ManagerMailDocument.Subject = $MailSubject
        $ManagerMailDocument.HTMLBody = $ManagerMailTemplate
        
        $ManagerMailDocument.save()
        
        #$inspector = $ManagerMailDocument.GetInspector
        #$inspector.Display()
        Log-write -logpath $Script:LogPath -linevalue "`t`tDone"

   }   



   
    #####################
    #.....AND ENDS HERE #
    #####################

    Log-Finish -LogPath $Script:LogPath -NoExit $True

}catch{

    Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $false
    
    Log-Finish -LogPath $Script:LogPath -NoExit $True

} finally {
   
    # Cleanup from any previous runs
    Get-Variable | Where-Object { $SystemVars -notcontains $_.Name } | Where-Object { Remove-Variable -Name “$($_.Name)” -Force -Scope “global” -ErrorAction SilentlyContinue}

} # Try/Catch