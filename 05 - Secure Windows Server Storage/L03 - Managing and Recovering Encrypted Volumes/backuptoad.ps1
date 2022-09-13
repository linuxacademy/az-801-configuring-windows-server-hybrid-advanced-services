Install-WindowsFeature BitLocker -IncludeManagementTools

Add-BitLockerKeyProtector -MountPoint D: -RecoveryPasswordProtector

manage-bde -protectors -get D:

Backup-BitLockerKeyProtector D: -KeyProtectorId ''

manage-bde -on D: