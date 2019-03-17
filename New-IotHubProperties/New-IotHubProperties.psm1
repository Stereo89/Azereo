#Requires -Module AzureRM.IoTHub
<# 
 .Synopsis
  Create an object to set desired PartitionsCount and RetentionTimeInDays for New-AzureRmIotHub cmdlet.

 .Description
  Create an object to set desired PartitionsCount and RetentionTimeInDays for New-AzureRmIotHub cmdlet.
  The object created must be passed to -Properties param of New-AzureRmIotHub command. It is recommended to store it in a variable.

 .Parameter PartitionCount
  The desired partitions number.

 .Parameter RetentionTimeInDays
  The desired RetentionTimeInDays number.

 .Example
   # Create an PSIotHubInputProperties object with 32 Partitions and 2 days of retention.
   Create-IotHubProperties -PartitionCount 32 -RetentionTimeInDays 2

 .Example
   # Create an PSIotHubInputProperties object with 8 Partitions and 1 day of retention.
   Create-IotHubProperties -PartitionCount 8

 .Example
   # Create an PSIotHubInputProperties object with 32 Partitions and 2 days of retention and store it in a variable.
   $IotHubInputProperties = Create-IotHubProperties -PartitionCount 32 -RetentionTimeInDays 2

#>

function New-IotHubProperties {
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true)]
        [ValidateRange(2,128)]
        [Int]
        $PartitionCount,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [ValidateRange(1,7)]
        [Int]
        $RetentionTimeInDays = 1
        ) 
    Process 
    { 
       $IoTHubInputProps = New-Object -TypeName Microsoft.Azure.Commands.Management.IotHub.Models.PSIotHubInputProperties
       $EventHUbInputProps = [Microsoft.Azure.Commands.Management.IotHub.Models.PSEventHubInputProperties]::new()
       $EventHubInputProps.PartitionCount = $PartitionCount
       $EventHUbInputProps.RetentionTimeInDays = $RetentionTimeInDays

       $Dictionary = New-Object 'System.Collections.Generic.Dictionary[string,Microsoft.Azure.Commands.Management.IotHub.Models.PSEventHubInputProperties]'

       $Dictionary.Add([string]"events",[Microsoft.Azure.Commands.Management.IotHub.Models.PSEventHubInputProperties]$EventHUbInputProps)

       $IoTHubInputProps.EventHubEndpoints = $dictionary

       return $IoTHubInputProps
   } 

}

Export-ModuleMember -Function New-IotHubProperties