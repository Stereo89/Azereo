# .SYNOPSIS
Create/update a .csv report based on consumer group blobs and an Azure EventHub (or Azure IoTHub) and return a list PartitionCompare objects.

# .DESCRIPTION
Create/update a .csv report based on consumer group blobs and an Azure EventHub (or Azure IoTHub) and return a list PartitionCompare objects.
The .csv file name will be in the form eventhubname_yyyyMMdd.csv
  
# .PARAMETER **EventHubConnectionString**
The EventHub connection string to query. Format:
`Endpoint=sb://mynamespace.servicebus.windows.net/;SharedAccessKeyName=myKeyName;SharedAccessKey=mySharedAccessKey;EntityPath=myeventHubname`

# .PARAMETER **StorageName**
The StorageName that contains the consumer group folder of the processor.

# .PARAMETER **StorageKey**
The primary or secondary key of the storage containing the consumer group blobs.

# .PARAMETER **ContainerName**
The container name containing the consumer group blobs.
 
# .PARAMETER **ConsumerGroupFolder**
The consumer group name used by event processor.

# .PARAMETER **OutputPath**
The output path where the .csv report will be saved/updated.

# .PARAMETER **InputFile**
The absolute or relative path of the input file containing required parameters.

# .PARAMETER **Clipboard**
Switch to export result to clipboard. Available on Windows.

# .EXAMPLE
# Create a report on directory C:\Export\ getting parameter from file C:\users\<username>\inputFile.txt and copy the result to clipboard.
    Get-Partitions -InputFile C:\users\<username>\inputFile.txt -OutputPath C:\Export\ -Clipboard
(Clipboard option available on Windows Platform)

# .EXAMPLE
# Create a report on directory C:\Export\
    Get-Partitions -EventHubConnectionString <EventHubConnectionString> -StorageName <StorageName> -StorageKey <StorageKey> -ContainerName <ContainerName> -ConsumerGroupFolder <ConsumerGroupFolder> -OutputPath "C:\Export\"