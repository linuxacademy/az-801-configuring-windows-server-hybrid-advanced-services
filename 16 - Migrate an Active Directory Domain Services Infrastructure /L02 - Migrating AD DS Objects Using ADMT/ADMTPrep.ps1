function Install-SQLServerExpress2019 {
    Write-Host "Downloading SQL Server Express 2019..."
    $Path = $env:TEMP
    $Installer = "SQL2019-SSEI-Expr.exe"
    $URL = "https://go.microsoft.com/fwlink/?linkid=866658"
    Invoke-WebRequest $URL -OutFile $Path\$Installer

    Write-Host "Installing SQL Server Express..."
    Start-Process -FilePath $Path\$Installer -Args "/ACTION=INSTALL /IACCEPTSQLSERVERLICENSETERMS /QUIET" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
}
Install-SQLServerExpress2019

# Download the Active Directory Migration Tool
Invoke-WebRequest -uri "https://download.microsoft.com/download/9/1/5/9156937F-1DF7-4734-9BEB-5F0A4400B29E/admtsetup32.exe" -outfile C:\users\awesomeadmin\desktop\ADMT.exe

$User = "corp.awesome.com\awesomeadmin"
$PWord = ConvertTo-SecureString -String "p@55w0rd" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

# Add newcorp.awesome.local's admin into DC1's local admin group
Invoke-Command -Credential $Credential -ComputerName dc.corp.awesome.com -ScriptBlock {($newdomainuser = get-aduser -identity awesomeadmin -server dc2),(Add-ADGroupMember -Identity Administrators -Members $newdomainuser)}
