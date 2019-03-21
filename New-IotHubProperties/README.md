# New-IotHubProperties

## .SYNOPSIS
Create an object to set desired PartitionsCount and RetentionTimeInDays for New-AzIotHub cmdlet.

## .DESCRIPTION
Create an object to set desired PartitionsCount and RetentionTimeInDays for New-AzIotHub cmdlet.
The object created must be passed to -Properties param of New-AzIotHub command. It is recommended to store it in a variable
  
## .PARAMETER **PartitionsCount**
The desired partitions number (min 2, MAX 128)

## .PARAMETER **RetentionTimeInDays**
The desired RetentionTimeInDays number (min 1, MAX 7)

##  .EXAMPLE
## Create an PSIotHubInputProperties object with 32 Partitions and 2 days of retention.
    New-IotHubProperties -PartitionsCount 32 -RetentionTimeInDays 2

## .EXAMPLE
## Create an PSIotHubInputProperties object with 8 Partitions and 1 day of retention.
    New-IotHubProperties -Partitions 8

## .EXAMPLE
## Create an PSIotHubInputProperties object with 32 Partitions and 2 days of retention and store it in a variable.
    $IotHubInputProperties = New-IotHubProperties -Partitions 32 -Retention 2

## .OUTPUTS
  [Microsoft.Azure.Commands.Management.IotHub.Models.PSIotHubInputProperties] object 

## .LINK
  https://github.com/Stereo89/Azereo/tree/master/New-IotHubProperties