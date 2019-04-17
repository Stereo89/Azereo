#Requires -Module Az.IotHub
#Requires -PSEdition Core, Desktop
#Requires -Version 5.1

function New-IotHubProperties {
    <# 
 .Synopsis
  Create an object to set desired PartitionsCount and RetentionTimeInDays for New-AzIotHub cmdlet.

 .Description
  Create an object to set desired PartitionsCount and RetentionTimeInDays for New-AzIotHub cmdlet.
  The object created must be passed to -Properties param of New-AzIotHub command. It is recommended to store it in a variable.

 .Parameter PartitionsCount
  The desired partitions number (min 2, MAX 128)

 .Parameter RetentionTimeInDays
  The desired RetentionTimeInDays number (min 1, MAX 7)

 .Example
   # Create an PSIotHubInputProperties object with 32 Partitions and 2 days of retention.
   New-IotHubProperties -PartitionsCount 32 -RetentionTimeInDays 2

 .Example
   # Create an PSIotHubInputProperties object with 8 Partitions and 1 day of retention.
   New-IotHubProperties -Partitions 8

 .Example
   # Create an PSIotHubInputProperties object with 32 Partitions and 2 days of retention and store it in a variable.
   $IotHubInputProperties = New-IotHubProperties -Partitions 32 -Retention 2

   .Link
   https://github.com/Stereo89/Azereo/tree/master/New-IotHubProperties
   
#>

[OutputType('Microsoft.Azure.Commands.Management.IotHub.Models.PSIotHubInputProperties')]

    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true)]
        [ValidateRange(2,128)]
        [Alias("Partitions")]
        [int16]
        $PartitionCount,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [ValidateRange(1,7)]
        [Alias("Retention")]
        [int16]
        $RetentionTimeInDays = 1
        ) 
    Process 
    { 
       $IotHubInputProps = [Microsoft.Azure.Commands.Management.IotHub.Models.PSIotHubInputProperties]::new()
       $EventHubInputProps = [Microsoft.Azure.Commands.Management.IotHub.Models.PSEventHubInputProperties]::new()
       $EventHubInputProps.PartitionCount = $PartitionCount
       $EventHubInputProps.RetentionTimeInDays = $RetentionTimeInDays

       $Dictionary = New-Object 'System.Collections.Generic.Dictionary[string,Microsoft.Azure.Commands.Management.IotHub.Models.PSEventHubInputProperties]'

       $Dictionary.Add([string]"events",[Microsoft.Azure.Commands.Management.IotHub.Models.PSEventHubInputProperties]$EventHubInputProps)

       $IotHubInputProps.EventHubEndpoints = $dictionary

       return $IotHubInputProps
   } 

}

Export-ModuleMember -Function New-IotHubProperties