# Get-PartitionsReport

## .SYNOPSIS
Create/update a .csv report based on consumer group blobs and an Azure EventHub (or Azure IoTHub) and return a list PartitionCompare objects.

## .DESCRIPTION
Create/update a .csv report based on consumer group blobs and an Azure EventHub (or Azure IoTHub) and return a list PartitionCompare objects.
The .csv file name will be in the form eventhubname_yyyyMMdd.csv
  
## .PARAMETER **EventHubConnectionString**
The EventHub connection string to query. Format:
`Endpoint=sb://mynamespace.servicebus.windows.net/;SharedAccessKeyName=myKeyName;SharedAccessKey=mySharedAccessKey;EntityPath=myeventHubname`

## .PARAMETER **StorageName**
The StorageName that contains the consumer group folder of the processor.

## .PARAMETER **StorageKey**
The primary or secondary key of the storage containing the consumer group blobs.

## .PARAMETER **ContainerName**
The container name containing the consumer group blobs.
 
## .PARAMETER **ConsumerGroupFolder**
The consumer group name used by event processor.

## .PARAMETER **OutputPath**
The output path where the .csv report will be saved/updated.

## .PARAMETER **InputFile**
The absolute or relative path of the input file containing required parameters.
You can find an example of the input file here: https://github.com/Stereo89/Azereo/blob/master/Get-PartitionsReport/inputTemplate.txt

## .PARAMETER **ProcessorOnly**
Switch to get only Processor info (on storage).

##  .EXAMPLE
## Create a report on directory C:\Export\ getting parameter from file C:\users\<username>\inputFile.txt
```powershell
    Get-PartitionsReport -InputFile C:\users\<username>\inputFile.txt -OutputPath C:\Export\
```
## .EXAMPLE
## Create a report on directory C:\Export\
```powershell
    Get-PartitionsReport -EventHubConnectionString <EventHubConnectionString> -StorageName <StorageName> -StorageKey <StorageKey> -ContainerName <ContainerName> -ConsumerGroupFolder <ConsumerGroupFolder> -OutputPath "C:\Export\"
```
## .EXAMPLE
## Create a report of the Processor blobs status on directory C:\Export\ getting parameter from file C:\users\<username>\inputFile.txt
```powershell
    Get-PartitionsReport -InputFile C:\users\<username>\inputFile.txt -OutputPath "C:\Export\" -ProcessorOnly
```
## .OUTPUTS
  A .csv file (file name will be in the form eventhubname_yyyyMMdd.csv or eventhubnamePO_yyyyMMdd.csv in case of ProcessorOnly switch)
  PartitionBlob list object in case of -ProcessorOnly switch
  PartitionCompare list object if -ProcessorOnly switch is NOT used

## .LINK
  https://github.com/Stereo89/Azereo/tree/master/Get-PartitionsReport
