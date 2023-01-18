Invoke-command -computername server1,server2 -scriptblock { (install-windowsfeature file-services, RSAT-Clustering-PowerShell), (install-windowsfeature Failover-Clustering -IncludeManagementTools)}

New-Cluster -name democluster -Node server1,server2 -StaticAddress 10.0.0.100 -NoStorage

Invoke-command -computername server1,server2 -scriptblock { (Initialize-Disk -Number 2 -PartitionStyle GPT) }

Enable-ClusterStorageSpacesDirect -CimSession democluster

New-Volume -FriendlyName "volume1" -FileSystem CSVFS_ReFS -StoragePoolFriendlyName S2D* -Size 6GB