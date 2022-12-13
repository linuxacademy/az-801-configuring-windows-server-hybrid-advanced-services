# Install Requirements
Invoke-command -computername server1,server2 -scriptblock {(install-windowsfeature Failover-Clustering -IncludeManagementTools)}

# Create the cluster
New-Cluster -name democluster -Node server1,server2 -StaticAddress 10.0.0.100 -NoStorage

# Set the witness
Set-ClusterQuorum -CloudWitness -AccountName "NAME" -AccessKey "ACCESSKEY"