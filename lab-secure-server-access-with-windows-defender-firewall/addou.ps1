New-ADOrganizationalUnit -Name servermembers `
    -Path "DC=corp,DC=awesome,DC=com" `
    -Description "windows server members" `
    -PassThru

New-ADOrganizationalUnit -Name clients `
    -Path "DC=corp,DC=awesome,DC=com" `
    -Description "user clients" `
    -PassThru 
