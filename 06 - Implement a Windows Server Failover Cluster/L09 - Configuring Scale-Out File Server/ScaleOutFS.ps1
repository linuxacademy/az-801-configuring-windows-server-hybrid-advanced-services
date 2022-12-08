# Install Requirements
Invoke-command -computername server1,server2 -scriptblock { (install-windowsfeature file-services), (install-windowsfeature Failover-Clustering -IncludeManagementTools)}

# Create the cluster
New-Cluster -name democluster -Node server1,server2 -StaticAddress 10.0.0.100 -NoStorage

# Setup Disks
diskmgmt.msc

# Add Disks to the cluster
Get-ClusterAvailableDisk | Add-ClusterDisk

# Convert to a cluster shared volume
Add-ClusterSharedVolume “Cluster Disk 1”

# Setup scale-out file server role
Add-ClusterScaleOutFileServerRole -Name SOFS01 -Cluster democluster

# Create a file share
$Path = "C:\ClusterStorage\Volume1\Shared"
New-Item -Path $Path -ItemType Directory
New-SmbShare -Name Shared -Path $Path -FullAccess CORP\awesomeadmin