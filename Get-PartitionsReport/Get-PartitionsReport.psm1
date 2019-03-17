#Requires -Modules Az.Storage
#Requires -PSEdition Core
function Get-PartitionsReport {
<# 
 .SYNOPSIS
  Create/update a .csv report based on consumer group blobs and an Azure EventHub (or Azure IoTHub) and return a list PartitionCompare objects.

 .DESCRIPTION
  Create/update a .csv report based on consumer group blobs and an Azure EventHub (or Azure IoTHub) and return a list PartitionCompare objects.
  The .csv file name will be in the form eventhubname_yyyyMMdd.csv
  
 .PARAMETER EventHubConnectionString
  The EventHub connection string to query.
  Format: Endpoint=sb://mynamespace.servicebus.windows.net/;SharedAccessKeyName=myKeyName;SharedAccessKey=mySharedAccessKey;EntityPath=myeventHubname

 .PARAMETER StorageName
  The StorageName that contains the consumer group folder of the processor.

 .PARAMETER StorageKey
  The primary or secondary key of the storage containing the consumer group blobs.

 .PARAMETER ContainerName
  The container name containing the consumer group blobs.
 
  .PARAMETER ConsumerGroupFolder
  The consumer group name used by event processor.

  .PARAMETER OutputPath
  The output path where the .csv report will be saved/updated.

  .PARAMETER InputFile
  The absolute or relative path of the input file containing required parameters.

  .PARAMETER Clipboard
  Switch to export result to clipboard. Available on Windows.

 .EXAMPLE
   # Create a report on directory C:\Export\ getting parameter from file C:\users\<username>\inputFile.txt and copy the result to clipboard.
   Get-Partitions -InputFile C:\users\<username>\inputFile.txt -OutputPath "C:\Export\" -Clipboard (Clipboard option available on Windows Platform)

 .EXAMPLE
   # Create a report on directory C:\Export\
   Get-Partitions -EventHubConnectionString <EventHubConnectionString> -StorageName <StorageName> `
        -StorageKey <StorageKey> -ContainerName <ContainerName> -ConsumerGroupFolder <ConsumerGroupFolder> -OutputPath "C:\Export\"
#>
    [OutputType('PartitionCompare')]
    [cmdletbinding(DefaultParameterSetName='InputFile')]

    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='NoFile')]
        [Alias("EH", "EventHub", "EHConnString")]
        [string] $EventHubConnectionString,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='NoFile')]
        [Alias("SN")]
        [string] $StorageName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='NoFile')]
        [Alias("SK")]
        [string] $StorageKey,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='NoFile')]
        [Alias("Container")]
        [string] $ContainerName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='NoFile')]
        [Alias("ConsumerGroup", "CG")]
        [string] $ConsumerGroupFolder,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='NoFile')]
        [Alias("OutputDir")]
        [string] $OutputPath,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName='InputFile')]
        [Alias("Input")]
        [string] $InputFile
    )

    DynamicParam
        {
            if($IsWindows)
                {
                # Begin dynamic parameter definition
                $ParamName_Clipboard = 'Clipboard'
                $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                
                $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
                $ParameterAttribute.Mandatory = $false
                $ParameterAttribute.ValueFromPipelineByPropertyName = $true
                $ParameterAttribute.ValueFromPipeline = $true
                $AttributeCollection.Add($ParameterAttribute)
                
                $ParamAlias = New-Object System.Management.Automation.AliasAttribute -ArgumentList "Clip"
                $AttributeCollection.Add($ParamAlias)
                
                <#
                [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
                [Alias("Clip")]
                [switch] $Clipboard

                $ValidationValues = Get-CsOnlineTelephoneNumber -IsNotAssigned | Select -ExpandProperty Id
                
                $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidationValues)
                $AttributeCollection.Add($ValidateSetAttribute)
                #>
                
                # End Dynamic parameter definition
                
                # When done building dynamic parameters, return

                # Set up the Run-Time Parameter Dictionary
                $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
                $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_Clipboard, [System.Management.Automation.SwitchParameter], $AttributeCollection)
                $RuntimeParameterDictionary.Add($ParamName_Clipboard, $RuntimeParameter)
                return $RuntimeParameterDictionary
            }
            
        }
        begin {
            
            if($PSCmdlet.ParameterSetName -eq "InputFile"){
                
                if(!(Test-Path -Path $InputFile -PathType Leaf)) {
                    throw ("Input File '$InputFile' doesn't exists or it is a directory")
                }
                else{
                    
                    $inputFileContent = (Get-Content $InputFile) -split "`n"
        
                    $EventHubConnectionString = ($inputFileContent | Where-Object {$_.StartsWith("EventHubConnectionString=")}).Trim().TrimEnd(";")
                    
                    $StorageName = ($inputFileContent | Where-Object {$_.StartsWith("StorageName=")}).Trim()
                    $pattern = "StorageName=(\w+)"
                    $regex = [Regex]::new($pattern)
                    $match = $regex.Match($StorageName)
                    $StorageName = $match.Groups[1].ToString()
        
                    $StorageKey = ($inputFileContent | Where-Object {$_.StartsWith("StorageKey=")}).Trim()
                    $pattern = "StorageKey=([^;|^`n]*)"
                    $regex = [Regex]::new($pattern)
                    $match = $regex.Match($StorageKey)
                    $StorageKey = $match.Groups[1].ToString()

                    $ContainerName = ($inputFileContent | Where-Object {$_.StartsWith("ContainerName=")}).Trim()
                    $pattern = "ContainerName=(\w+)"
                    $regex = [Regex]::new($pattern)
                    $match = $regex.Match($ContainerName)
                    $ContainerName = $match.Groups[1].ToString()

                    $ConsumerGroupFolder = ($inputFileContent | Where-Object {$_.StartsWith("ConsumerGroupFolder=")}).Trim()
                    $pattern = "ConsumerGroupFolder=(\w+)"
                    $regex = [Regex]::new($pattern)
                    $match = $regex.Match($ConsumerGroupFolder)
                    $ConsumerGroupFolder = $match.Groups[1].ToString()

                    $OutputPath = ($inputFileContent | Where-Object {$_.StartsWith("OutputPath=")}).Trim()
                    $pattern = "OutputPath=([^`n]*)"
                    $regex = [Regex]::new($pattern)
                    $match = $regex.Match($OutputPath)
                    $OutputPath = $match.Groups[1].ToString()
                }
            }
        }
        
        process
        {
            function Get-SasToken(){
                Param(
                    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
                    [string] $URI,
                    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
                    [string] $KeyName,
                    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
                    [string] $Key,
                    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
                    [int] $ExpiresIn = 600
                )

                [Reflection.Assembly]::LoadWithPartialName("System.Web")| out-null

                #Token defauls expires now+600
                $Expires=([DateTimeOffset]::Now.ToUnixTimeSeconds())+$ExpiresIn
                $SignatureString=[System.Web.HttpUtility]::UrlEncode($URI)+ "`n" + [string]$Expires
                $HMAC = New-Object System.Security.Cryptography.HMACSHA256
                $HMAC.key = [Text.Encoding]::ASCII.GetBytes($Key)
                $Signature = $HMAC.ComputeHash([Text.Encoding]::ASCII.GetBytes($SignatureString))
                $Signature = [Convert]::ToBase64String($Signature)
                $SASToken = "sr=" + [System.Web.HttpUtility]::UrlEncode($URI) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($Signature) + "&se=" + $Expires + "&skn=" + $KeyName
                
                return $SASToken

            }

            class RestPartition
            {
                [ValidateNotNullOrEmpty()][int] $PartitionID
                [ValidateNotNullOrEmpty()][long] $SizeInBytes
                [ValidateNotNullOrEmpty()][long] $BeginSequenceNumber
                [ValidateNotNullOrEmpty()][long] $EndSequenceNumber
                [ValidateNotNullOrEmpty()][long] $IncomingBytesPerSecond
                [ValidateNotNullOrEmpty()][long] $OutgoingBytesPerSecond
                [ValidateNotNullOrEmpty()][long] $LastEnqueuedOffset
                [ValidateNotNullOrEmpty()][DateTime] $LastEnqueuedTimeUtc

                RestPartition([int] $partitionID, [long] $SizeInBytes, [long] $BeginSequenceNumber, [long] $EndSequenceNumber, [long] $IncomingBytesPerSecond, [long] $OutgoingBytesPerSecond, [long] $LastEnqueuedOffset, [DateTime] $LastEnqueuedTimeUtc)
                {
                    $this.PartitionID = $PartitionID
                    $this.SizeInBytes = $SizeInBytes
                    $this.BeginSequenceNumber = $BeginSequenceNumber
                    $this.EndSequenceNumber = $EndSequenceNumber
                    $this.IncomingBytesPerSecond = $IncomingBytesPerSecond
                    $this.OutgoingBytesPerSecond = $OutgoingBytesPerSecond
                    $this.LastEnqueuedOffset = $LastEnqueuedOffset
                    $this.LastEnqueuedTimeUtc = $LastEnqueuedTimeUtc
                }

            }

            class PartitionBlob
            {
                [ValidateNotNullOrEmpty()][int] $PartitionID
                [string] $Owner
                [ValidateNotNullOrEmpty()][long] $Epoch
                [ValidateNotNullOrEmpty()][long] $BlobSequenceNumber
                [ValidateNotNullOrEmpty()][DateTime] $LastModifiedBlobUTC

                PartitionBlob([int] $PartitionID, [string] $Owner, [long] $Epoch, [long] $BlobSequenceNumber, [DateTime] $LastModifiedBlobUTC)
                {
                    $this.PartitionID = $PartitionID
                    $this.Owner = $Owner
                    $this.Epoch = $Epoch
                    $this.BlobSequenceNumber = $BlobSequenceNumber
                    $this.LastModifiedBlobUTC = $LastModifiedBlobUTC
                }

            }

            class PartitionCompare
            {
                [ValidateNotNullOrEmpty()][long] $RunID
                [ValidateNotNullOrEmpty()][int] $PartitionID
                [ValidateNotNullOrEmpty()][long] $Difference
                [string] $Owner
                [ValidateNotNullOrEmpty()][long] $ProcessorSequence
                [ValidateNotNullOrEmpty()][long] $EventHubSequence
                [ValidateNotNullOrEmpty()][DateTime] $LastModifiedBlobUTC
                [ValidateNotNullOrEmpty()][DateTime] $EventHubLastEnqueuedUTC

                PartitionCompare([long] $RunID,[int] $PartitionID, [string] $Owner, [long] $ProcessorSequence, [long] $EventHubSequence, [DateTime] $LastModifiedBlobUTC, [DateTime] $EventHubLastEnqueuedUTC)
                {
                    $this.RunID = $RunID
                    $this.PartitionID = $PartitionID
                    $this.Owner = $Owner
                    $this.ProcessorSequence = $ProcessorSequence
                    $this.EventHubSequence = $EventHubSequence
                    $this.Difference = $EventHubSequence - $ProcessorSequence
                    $this.LastModifiedBlobUTC = $LastModifiedBlobUTC
                    $this.EventHubLastEnqueuedUTC = $EventHubLastEnqueuedUTC
                }

                PartitionCompare([long] $RunID, [PartitionBlob] $partitionBlob, [RestPartition] $restPartition)
                {
                    $this.RunID = $RunID
                    $this.PartitionID = $partitionBlob.PartitionID
                    $this.Owner = $partitionBlob.Owner
                    $this.ProcessorSequence = $partitionBlob.BlobSequenceNumber
                    $this.EventHubSequence = $restPartition.EndSequenceNumber
                    $this.Difference = $this.EventHubSequence - $this.ProcessorSequence
                    $this.LastModifiedBlobUTC = $partitionBlob.LastModifiedBlobUTC
                    $this.EventHubLastEnqueuedUTC = $restPartition.LastEnqueuedTimeUtc
                }
            }
            
            $EventHubConnectionString = $EventHubConnectionString.TrimEnd(";")

            $tempFolder = [System.IO.Path]::GetTempPath()
            $tempGUID = [System.Guid]::NewGuid().ToString("N")
            $consumerTempFolder = Join-Path -Path $tempFolder -ChildPath $tempGUID -AdditionalChildPath $ConsumerGroupFolder
            if(!(Test-path $consumerTempFolder)){
                New-Item -ItemType Directory -Path $consumerTempFolder | Out-Null
            }
                        
            $pattern = "Endpoint=sb://([^/]*)"
            $regex = [Regex]::new($pattern)
            $match = $regex.Match($EventHubConnectionString)

            $eventhubNamespace = $match.Groups[1].ToString()

            $pattern = "EntityPath=(.*)"
            $regex = [Regex]::new($pattern)
            $match = $regex.Match($EventHubConnectionString)

            $eventhubName = $match.Groups[1].ToString()

            if($eventhubNamespace.StartsWith("iothub-ns")){
                $FilePrefix = $eventhubName
            }
            else{
                $pattern = "([^\.]*)"
                $regex = [Regex]::new($pattern)
                $match = $regex.Match($eventhubNamespace)
            
                $FilePrefix = $match.Groups[1].ToString()
            }   

            $pattern = "SharedAccessKeyName=(\w+)"
            $regex = [Regex]::new($pattern)
            $match = $regex.Match($EventHubConnectionString)

            $keyName = $match.Groups[1].ToString()

            $pattern = "SharedAccessKey=([^;]*)"
            $regex = [Regex]::new($pattern)
            $match = $regex.Match($EventHubConnectionString)

            $key = $match.Groups[1].ToString()

            Write-Verbose "`tEventHub/IoTHub NameSpace: $eventhubNamespace"
            Write-Verbose "`tEventHub Name: $eventhubName"
            Write-Verbose "`tStorage: $StorageName"
            Write-Verbose "`tContainer: $ContainerName"
            Write-Verbose "`tConsumer Group: $ConsumerGroupFolder`n"

            if(!($EventHubConnectionString -and $eventhubNamespace -and $eventhubName -and $ConsumerGroupFolder -and $ContainerName -and $StorageName -and $StorageKey))
            {
                Write-Verbose "Parameters parse failed"
                throw ("Input parameters wrong format")
            }

            $REST_Uri = [String]::Format("https://{0}/{1}/consumergroups/{2}/partitions?api-version=2015-01", $eventhubNamespace, $eventhubName, '$Default')
            $SasToken = Get-SasToken -URI $REST_Uri -KeyName $keyName -Key $key

            $header = @{
                'Authorization'= "SharedAccessSignature $SasToken"
                'Content-Type' = 'application/atom+xml;type=entry;charset=utf-8'
            }

            $response = Invoke-RestMethod -Method Get -Uri $REST_Uri -Headers $header

            $StorageContext = New-AzStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey
            
            #ListBlobs can be skipped knowing the name of the partition
            #$ConsumerBlobs = Get-AzStorageBlob -Prefix $ConsumerGroupFolder -Container $ContainerName -Context $StorageContext 

            #Removing old temporary files
            Remove-Item -Path $consumerTempFolder\* -Force

            #Temporary Arrays
            $PartitionsBlobs = [System.Collections.ArrayList]::new()
            $RestPartitions = [System.Collections.ArrayList]::new()

            $partitionCount = $response.Count
            
            Write-Host "`nStart analysis $partitionCount partitions`n"

            for($i = 0; $i -lt $partitionCount;$i++){

                $startElaboration = Get-Date
                #Calculate percentage $i:$partitionCount=Percentage:100
                Write-Progress -Activity "Getting partition $($i+1) of $partitionCount" -Status "$([System.Math]::Floor((($i*100)/$partitionCount)))% Complete:" -PercentComplete ([System.Math]::Floor((($i*100)/$partitionCount)))

                #Retrieving Eventhub information
                Write-Host "`tQuerying partition: #$i"
                $EH_Rest_Uri_SinglePartition = [String]::Format("https://{0}/{1}/consumergroups/{2}/partitions/{3}?api-version=2015-01", $eventhubNamespace, $eventhubName, '$Default',$i)
                $SasToken = Get-SasToken -URI $EH_Rest_Uri_SinglePartition -KeyName $keyName -Key $key

                $header = @{
                    'Authorization'= "SharedAccessSignature $SasToken"
                    'Content-Type' = 'application/atom+xml;type=entry;charset=utf-8'
                }
        
                $response = Invoke-RestMethod -Method Get -Uri $EH_Rest_Uri_SinglePartition -Headers $header
                $Description = $response.entry.content.PartitionDescription
                $PartitionID = $response.entry.title.'#text'
                $BeginSequenceNumber = [long]::Parse($Description.BeginSequenceNumber)
                $EndSequenceNumber = [long]::Parse($Description.EndSequenceNumber)
                $IncomingBytesPerSecond = [long]::Parse($Description.IncomingBytesPerSecond)
                $OutgoingBytesPerSecond = [long]::Parse($Description.OutgoingBytesPerSecond)
                $LastEnqueuedOffSet = [long]::Parse($Description.LastEnqueuedOffset)
                $LastEnqueuedTimeUtc = ([Datetime]::Parse($Description.LastEnqueuedTimeUtc)).ToUniversalTime()
                $SizeInBytes = [long]::Parse($Description.SizeInBytes)

                $RestPartitionObj = [RestPartition]::new($PartitionID,$SizeInBytes, $BeginSequenceNumber,$EndSequenceNumber,$IncomingBytesPerSecond,$OutgoingBytesPerSecond,$LastEnqueuedOffSet,$LastEnqueuedTimeUtc)
                $RestPartitions.Add($RestPartitionObj) | Out-Null

                #Retrieving Blob information
                Write-Host "`tDownloading blob: $ConsumerGroupFolder/$i"

                do{
                    $Failed = $false
                    Try{
                        $blob = Get-AzStorageBlob -Blob "$ConsumerGroupFolder/$i" -Container $ContainerName -Context $StorageContext
                        #-EA Stop to catch Exception StorageException and retry to dowload blob failed
                        $BlobFullPath = Join-Path -Path $consumerTempFolder -ChildPath $i
                        Get-AzStorageBlobContent -Blob "$ConsumerGroupFolder/$i" -Container $ContainerName -Context $StorageContext -Force -Destination $BlobFullPath -EA Stop | Out-Null
                    } 
                    catch [System.Exception] { 
                        Write-Verbose "`tRetrying..."
                        $Failed = $true
                    }
                } while ($Failed)

                $blobContent = Get-Content -Path $BlobFullPath
                $blobJson = ConvertFrom-Json -InputObject $blobContent

                $PartitionsBlobObj = [PartitionBlob]::new([int]::Parse($blobJson.PartitionId),$blobJson.Owner,[long]::Parse($blobJson.Epoch),[long]::Parse($blobJson.SequenceNumber),$blob.LastModified.ToUniversalTime().UtcDateTime)
                $PartitionsBlobs.Add($PartitionsBlobObj) | Out-Null

                $endElaboration = Get-Date
                $ts = New-TimeSpan -Start $startElaboration -End $endElaboration
                $elapsedString = [string]::Format("The total elapsed time to analyze partition #$i is: {0:c}", $ts)

                Write-Verbose $elapsedString
                Write-Host "`tDifference partition #$i`: $($RestPartitionObj.EndSequenceNumber-$PartitionsBlobObj.BlobSequenceNumber)`n"

            }
            
            $PartitionsCompare = [System.Collections.Generic.List[PartitionCompare]]::new()
            $OutputFile = $FilePrefix + "_"+ (Get-date -Format "yyyyMMdd")
            $RunID = Get-date -Format "yyyyMMddhhmm"
            for ($ID = 0; $ID -lt $PartitionsBlobs.Count; $ID++) {

                $RestPart = $RestPartitions | Where-Object {$_.PartitionID -eq $ID }
                $BlobPart = $PartitionsBlobs | Where-Object {$_.PartitionID -eq $ID }
                $PartitionsCompare.add([PartitionCompare]::new([long]::Parse($RunID),$BlobPart,$RestPart)) | Out-Null
            }
            
            $OutputPath = $OutputPath.TrimEnd("/")

            If(!(Test-Path -Path $OutputPath)){
                New-Item -Path $OutputPath -ItemType Directory | Out-Null
            }

            if(!(Test-path (Join-Path -Path $OutputPath -ChildPath "$OutputFile.csv"))){
                New-item -ItemType File -Path $OutputPath -Name "$OutputFile.csv" | Out-Null
                "RunID,PartitionID,Difference,Owner,ProcessorSequence,EventHubSequence,LastModifiedBlobUTC,EventHubLastEnqueuedUTC" | Out-File -FilePath ((Join-Path -Path $OutputPath -ChildPath "$OutputFile,csv")) -Append
            }
            
            $PartitionsCompare | Export-Csv -Path (Join-Path -Path $OutputPath -ChildPath "$OutputFile,csv") -Append -NoTypeInformation
            
            if($Clipboard.IsPresent){
                ($PartitionsCompare | Sort-Object -Property PartitionID | ConvertTo-Csv -NoTypeInformation).Replace(",","`t") | clip
            }
            
            return $PartitionsCompare
        }
        
        end {
            #Removing temporary files
            Remove-Item -Path $consumerTempFolder\* -Force
        }
    }

Export-ModuleMember -Function Get-PartitionsReport