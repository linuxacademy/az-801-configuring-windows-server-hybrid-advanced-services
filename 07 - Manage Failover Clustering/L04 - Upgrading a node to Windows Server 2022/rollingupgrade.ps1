Get-Cluster | Select ClusterFunctionalLevel

Suspend-ClusterNode -Name server2

Remove-ClusterNode -Name server2

Install-WindowsFeature Failover-Clustering -IncludeManagementTools
Install-windowsfeature file-services

Add-ClusterNode -Name server2 -Cluster democluster

Get-Cluster | Select ClusterFunctionalLevel

Update-ClusterFunctionalLevel

Get-Cluster | Select ClusterFunctionalLevel