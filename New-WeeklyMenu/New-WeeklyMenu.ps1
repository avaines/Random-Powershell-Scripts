<#
.SYNOPSIS
   Script to generate a weekly menu 

.DESCRIPTION
    Brief description of script

.PARAMETER  Param
    Brief description of parameter input required, repeat this section as required
     
.NOTES
    Author:     Aiden Vaines
    Purpose:    Weekly Menu
    
    Date        Change
    31/12/2018  First build

 #>
 
 
 [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true)][string]$RecipeListPath = "RecipeList.xlsx" #{throw "No RecipeList provided as argument"}
    )

function GetRecipeList {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)]
        [string]$recipeListPath
    )

    if(-Not(Test-Path $recipeListPath)) {
        Write-Error -ErrorDesc "Could not find file '$recipeListPath'" -ExitGracefully $true
    }

    $fileType = [IO.Path]::GetExtension($recipeListPath)

    Write-Log -linevalue "Importing $recipeListPath"
    switch ($fileType) {
        ".xlsx" {
            try{
                Write-Log -linevalue "Excel file detected. Importing required modules"
                Import-Module importExcel -MinimumVersion 5.0

                $recipeList = Import-Excel -Path $recipeListPath -StartColumn 1 -EndColumn 4
                
            } catch {
                Write-Error -ErrorDesc "$_.Exception" -ExitGracefully $true
            }
        }
        ".csv" {
            try{
                $recipeList = Import-Csv $recipeListPath
            } catch {
                Write-Error -ErrorDesc "$_.Exception" -ExitGracefully $true
            }
        }
        Default {
            Write-Error -ErrorDesc "Unable to read file type: $fileType"  -ExitGracefully $true
        }
    }

    return $recipeList
}

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
    Start-Log
    ########

    # Load the other modules in the module folder (except the Logging module as that is already loaded)
    ##############
    $Modules = Get-ChildItem ".\Modules\" | Where-Object {$_.name -ne "Init-Logging.ps1"}
    
    foreach ($Module in $Modules){  
        $ModuleName = $Module.Name
        Write-Log -linevalue "Loading Module: $ModuleName"
        . ".\Modules\$ModuleName"
    }
    
}catch{ 

    Write-Error -ErrorDesc $_.Exception -ExitGracefully $True

}


try{

    #####################################
    # MAIN SCRIPT BLOCK BEGINS HERE.....#
    #####################################

    $RecipeList = GetRecipeList $RecipeListPath

    try{
        #Checking for outputs folder and creating if unavailable
        If((Test-Path -Path Outputs) -eq $false){
            #Create it if not
            New-Item -Path Outputs -Value "Outputs" -ItemType Directory | Out-Null
        }

        $DocumentMenuPath = (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\Outputs\Menu-" + $(get-date -f "yyyy-MM-dd") + ".html"
        $DocumentMenu = @()
        $DocumentMenu += $htmlPartStart
        $DocumentShopListPath = (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\Outputs\ShoppingList-" + $(get-date -f "yyyy-MM-dd") + ".html"
        $DocumentShopList = @()
        $DocumentShopList += $htmlPartStart
    } catch {
        Write-Error -ErrorDesc "$_.Exception" -ExitGracefully $True
    }

    #Object for each week, each output will show 4 weeks worth of menus
    $Menu = @{
        0 = @()
        1 = @()
        2 = @()
        3 = @()
    }

    ## For each of the 4 weeks there are 7 days of recipes to generate
        # Placeholder var for holding the index/rows used already so we dont get duplicate entries in the week
        $RecipeRowsUsed = @()
    
    # Generate a menu for each of the 4 weeks
    Write-Log -linevalue "Generating Menu..." -Level "Menu"
    for($i=0; $i -le 3; $i++){
        Write-Log -linevalue ("Generating menu for week " + ($i + 1))
        for($a=0; $a -le 6; $a++){
            ## This next bit gets a random index/row from the Recipe List but not one thats already been used this week
            # Build a range from 0 to the number of entries in the recipe list (-1 because count starts at 1 not 0),
            # excluding any numbers already in the "recipeRowsUsed" variable
            $RandomRecipeRange = 0..($RecipeList.count -1) | Where-Object { $RecipeRowsUsed -notcontains $_ }

            # Get a random number from this range
            $RecipeRowIndex = Get-Random -InputObject ($RandomRecipeRange)

            # add this random number to the "recipeRowsUsed" variable for next time
            $RecipeRowsUsed += $RecipeRowIndex

            # Using the number generated, add the row from the recipelist to this weeks menu in the "Menu" variable
            $Menu.($i) += $RecipeList[$RecipeRowIndex]
        }#End Week Day
    }#End Week Num


     Write-Log -linevalue "Menu generated, building output" -Level "Menu"



    $ShoppingList = @{
        0=@()
        1=@()
        2=@()
        3=@()
    }

      #Build the table header
       $DocumentMenu += "<tr>
      <th>Monday</th>
      <th>Tuesday</th>
      <th>Wednesday</th>
      <th>Thursday</th>
      <th>Friday</th>
      <th>Saturday</th>
      <th>Sunday</th>
    </tr>"
    
    #Foreach week
    For($w=0; $w -le 3; $w++){
            #For Mon-Sun
            $DocumentMenu +="<tr>"
            for($d=0; $d -le 6; $d++){
                $Day = ($Menu.($w))[$d]
                
                if($Day.lunch -eq "Yes"){
                    $lunchImg='<img src="https://cdn0.iconfinder.com/data/icons/tools-in-black-and-white/84/Tool_Box-512.png" alt="">'
                }else{
                    $LunchImg = ''
                }
                
                switch($d){
                    #Dont want any recipes shows for Monday (day 0) and Friday (day 4)
                    0{if($w -eq 0){$DocumentMenu += "<td rowspan='0' style='width:1px'></td>"}}
                    4{if($w -eq 0){$DocumentMenu += "<td rowspan='0' style='width:1px'></td>"}}
                    default{$DocumentMenu += "<td>
                        <div class='nested-table'>
                            <div class='book'> "+ $Day.book + "</div>
                            <div class='lunch'>" + $lunchImg +" </div>
                        </div>
                        <div class='nested-table'>
                            <div class='recipe'>" +  $Day.Recipe + "</div>
                        </div>
                        </td>"

                        $ShoppingList.($w) += $Day.Ingredients
                    }
                }
            }# End each day Mon-Sun

    } #end each week
    
    $DocumentMenu += "</table>
    </div>"

    Write-Log -linevalue "Menu output built" -Level "Menu"
    $DocumentMenu += $htmlPartStop
    $DocumentMenu | out-file $DocumentMenuPath -force



     #Build the table header
     $DocumentShopList += "<tr>
      <th>Week 1</th>
      <th>Week 2</th>
	  <th>Week 3</th>
	  <th>Week 4</th>
    </tr>
    <tr>
    <td valign='top'> <p><ul><li>" + ( (($shoppinglist.0 -split "`n" | group-object | sort-object name) | Select @{N="name"; E={     
        if($_.count -gt 1){
            $_.name + " <i>(" + $_.count + " recipies)</i>"
        }
        else {
            $_.name 
        }}} ).name -join "</li><li>" ) + "</li></ul></p></td>

	<td valign='top'> <p><ul><li>" + ( (($shoppinglist.1 -split "`n" | group-object | sort-object name) | Select @{N="name"; E={        
        if($_.count -gt 1){
            $_.name + " <i>(" + $_.count + " recipies)</i>"
        }
        else {
            $_.name 
        }}}).name -join "</li><li>") + "</li></ul></p></td>

    

	<td valign='top'> <p><ul><li>" + ( (($shoppinglist.2 -split "`n" | group-object | sort-object name) | Select @{N="name"; E={
        if($_.count -gt 1){
            $_.name + " <i>(" + $_.count + " recipies)</i>"
        }
        else {
            $_.name 
        }}}).name -join "</li><li>") + "</li></ul></p></td>


	<td valign='top'> <p><ul><li>" + ( (($shoppinglist.3 -split "`n" | group-object | sort-object name) | Select @{N="name"; E={
        if($_.count -gt 1){
            $_.name + " <i>(" + $_.count + " recipies)</i>"
        }
        else {
            $_.name 
        }}}).name -join "</li><li>") + "</li></ul></p></td>
   </tr>
   </table>"

    
    Write-Log -linevalue "Shopping list built" -Level "Menu"
    $DocumentShopList += $htmlPartStop
    $DocumentShopList | out-file $DocumentShopListPath -force
    

    Invoke-item $DocumentMenuPath
    Invoke-item $DocumentShopListPath


    #####################
    #.....AND ENDS HERE #
    #####################
   
}catch{

    Write-Error -ErrorDesc "$_.Exception" -ExitGracefully $True

} finally {
    
    # Cleanup from any previous runs
    Stop-Log -NoExit $True
    
    #Get-Variable | Where-Object { $SystemVars -notcontains $_.Name } | Where-Object { Remove-Variable -Name “$($_.Name)” -Force -Scope “global” -ErrorAction SilentlyContinue}
    
} # Try/Catch
