Add-ClusterScaleOutFileServerRole -Name SOFS01 -Cluster democluster

# Create a file share
$Path = "C:\ClusterStorage\Volume1\Shared"
New-Item -Path $Path -ItemType Directory
New-SmbShare -Name Shared -Path $Path -FullAccess CORP\awesomeadmin