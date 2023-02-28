Get-ADDomain | Select-Object DomainMode

Move-ADDirectoryServerOperationMasterRole -Identity dc2 -OperationMasterRole SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster -Confirm:$false

Invoke-Command -ComputerName dc.corp.awesome.com -ScriptBlock {Uninstall-ADDSDomainController -DemoteOperationMasterRole -RemoveApplicationPartition}

Set-ADForestMode -Identity corp.awesome.com -ForestMode Windows2016Forest -Confirm:$false
Set-ADDomainMode -identity corp.awesome.com -DomainMode Windows2016Domain -Confirm:$false

Get-ADDomain | Select-Object DomainMode
Get-ADForest | Select-Object ForestMode