# Install Requirements
Invoke-command -computername server1,server2 -scriptblock { (install-windowsfeature file-services), (install-windowsfeature Failover-Clustering -IncludeManagementTools)}

# Create the cluster
New-Cluster -name democluster -Node server1,server2 -StaticAddress 10.0.0.100 -NoStorage

# Setup Disks
diskmgmt.msc

# Add Disks to the cluster
Get-ClusterAvailableDisk | Add-ClusterDisk

# Setup file server role
Add-ClusterFileServerRole -Storage "Cluster Disk 1" -Name FS01 -StaticAddress 10.0.0.150 #IP OF THE ILB

# Creating a rule to allow other VMs on the network to connect to the cluster role
$ClusterNetworkName = “Cluster Network 1” 
# the cluster network name
$IPResourceName = “IP Address 10.0.0.150” 
# the IP Address resource name 
$ILBIP = “10.0.0.150” 
# the IP Address of the Internal Load Balancer (ILB)
Import-Module FailoverClusters
Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{Address=$ILBIP;ProbePort=59999;SubnetMask="255.255.255.255";Network=$ClusterNetworkName;EnableDhcp=0}

# Start and stop the cluster so the rule above takes effect
Stop-ClusterGroup FS01
Start-ClusterGroup FS01

# Moving the cluster role to server 1 (if its not already) so we can create the file shares 
Move-ClusterGroup -Name FS01 -Node server1

# Create a file share on the mapped drive. Double check the drive letter of the path below. Make sure to do this on the server where the role is currently hosted
$Path = "F:\PSCreatedShare\"
New-Item -Path $Path -ItemType Directory
New-SmbShare -Name PSCreatedShare -Path $Path -FullAccess CORP\awesomeadmin
