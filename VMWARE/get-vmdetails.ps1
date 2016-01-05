<#
.SYNOPSIS
Retrieves info on Virtual Machines 

NB.
Script to colate info about all vms on a given platform, there are more variables which can be added at the bottom
 
.DESCRIPTION
Retrieves information on VMs'
 
.PARAMETER  None
 
.EXAMPLE
Usage - 
.\Get-VMdetails.ps1 | Export-Csv vmdetails.csv -NoTypeInformation
.\Get-VMdetails.ps1 | out-gridview

 
.NOTES
Author: Aiden Vaines
Date: 20/4/2015
Email: aiden@vaines.org
 
#>
 
 function Get-VMdetails {  
 function Get-vNicInfo {  
   [CmdletBinding()]  
   param (  
     [Parameter(Mandatory=$True)]  
     [string[]]$VMName  
     )  
         $vNicInfo = Get-VM -Name $VMName | Get-NetworkAdapter  
         $Result = foreach ($vNic in $VnicInfo) {  
           "{0}={1}"-f ($vnic.Name.split("")[2]), ($vNic.Type)  
         }  
         $Result -join (", ")  
 }  
 
 
function Get-VmDisks {  
     [CmdletBinding()]  
   param (  
     [Parameter(Mandatory=$True)]  
     [string[]]$VMName  
     ) 
	 
	$VMDiskInfo = Get-HardDisk -VM $VMName	
	$Result = foreach ($vDisk in $VMDiskInfo) {  
		"{0}={1}"-f ($vDisk.Name.split("")[2]), ($vDisk.CapacityGB)
    }  
	$Result -join (",")
}
 
 
function Get-VmPartitions {  
     [CmdletBinding()]  
   param (  
     [Parameter(Mandatory=$True)]  
     [string[]]$VMName  
     ) 
	 
	$VMPartInfo = ForEach ($VM in Get-VM -Name $VMName ){
		($VM.Extensiondata.Guest.Disk | Select DiskPath, @{N="Capacity";E={[math]::Round($_.Capacity/ 1GB)}})
	}
	
	$Result = foreach ($vPart in $VMPartInfo) {  
		"{0}={1}"-f ($vPart.DiskPath), ($vPart.Capacity)  
    }  
	$Result -join (",")

}


 function Get-InternalHDD {  
   [CmdletBinding()]  
   param (  
     [Parameter(Mandatory=$True)]  
     [string[]]$VMName  
     )  
         $VMInfo = Get-VMGuest -VM $VMName # (get-vm $VMName).extensiondata  
         $InternalHDD = $VMInfo.ExtensionData.disk   
         $result = foreach ($vdisk in $InternalHDD) {  
           "{0}={1}GB/{2}GB"-f ($vdisk.DiskPath), ($vdisk.FreeSpace /1GB -as [int]),($vdisk.Capacity /1GB -as [int])  
         }  
         $result -join (", ")  
 }

 
 foreach ($vm in (get-vm)) {  
     $props = @{'Name'=$vm.Name;  
           'IP Address'= $vm.Guest.IPAddress[0]; #$VM.ExtensionData.Summary.Guest.IpAddress  
           'PowerState'= $vm.PowerState;  
           'DNS Domain'= ($vm.ExtensionData.Guest.Hostname -split '\.')[1,2] -join '.';     
           'Comments' = ($vm | Select-Object -ExpandProperty Notes); 
           'CPUs'= $vm.NumCpu;  
           'Memory (MB)'= ($vm.MemoryGB * 1024);  
           'Disks (GB)' = Get-VmDisks -VMName $vm.Name
           'Partitions (GB)' = Get-VmPartitions  -VMName $vm.Name
		   'HDDs(GB)'= ($vm | get-harddisk | select-object -ExpandProperty CapacityGB) -join " + "            
           'Datastore'= (Get-Datastore -vm $vm) -split ", " -join ", ";  
           'Partition/Size' = Get-InternalHDD -VMName $vm.Name  
           'Real-OS'= $vm.guest.OSFullName;  
           'Attributes' = $VM.ExtensionData.summary.config.guestfullname;  
           'EsxiHost'= $vm.VMHost;  
           'vCenter Reference' = ($vm).ExtensionData.Client.ServiceUrl.Split('/')[2].trimend(":443")  
           'Hardware Version'= $vm.Version;  
           'Folder'= $vm.folder;  
           'MAC Address' = ($vm | Get-NetworkAdapter).MacAddress -join ", ";  
           'VMX' = $vm.ExtensionData.config.files.VMpathname;  
           'VMDK' = ($vm | Get-HardDisk).filename -join ", ";  
           'VMTools Status' = $vm.ExtensionData.Guest.ToolsStatus;  
           'VMTools Version' = $vm.ExtensionData.Guest.ToolsVersion;  
           'VMTools Version Status' = $vm.ExtensionData.Guest.ToolsVersionStatus;  
           'VMTools Running Status' = $vm.ExtensionData.Guest.ToolsRunningStatus;  
           'SnapShots' = ($vm | get-snapshot).count;  
           'Location' = $vm | Get-Datacenter;  
		       'Subcategory' = $VM | Get-Cluster;
           'vNic' = Get-VNICinfo -VMName $vm.name;  
           'PortGroup' = ($vm | Get-NetworkAdapter).NetworkName -join ", ";  
           }  

     $obj = New-Object -TypeName PSObject -Property $Props  
	  Write-Output $obj | select-object -Property 'Name', 'CPUs', 'Memory (MB)', 'Disks (GB)','Partitions (GB)', 'vNic', 'DNS Domain', 'MAC Address', 'Subcategory', 'vCenter Reference', 'IP Address', 'EsxiHost', 'Comments'

   }  
 }  
 
 Get-VMdetails
