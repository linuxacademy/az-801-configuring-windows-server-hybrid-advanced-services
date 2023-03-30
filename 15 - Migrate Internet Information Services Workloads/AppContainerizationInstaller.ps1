# -------------------------------------------------------------------------------------------------
#  <copyright file="AppContainerizationInstaller.ps1" company="Microsoft">
#      Copyright (c) Microsoft Corporation. All rights reserved.
#  </copyright>
#
#  Description: This script prepares the host machine for various AppContainerization Scenarios.#
#  Version: 0.2.0.0
#  Requirements: Refer to the preview guide for machine requirements.
# -------------------------------------------------------------------------------------------------

## This routine writes the output string to the console and also to a log file.
function Log-Info([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor White
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

function Log-Success([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Green
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

## This routine writes the output string to the console and also to a log file.
function Log-Warning([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Yellow
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII"  }
}

## This routine writes the output string to the console and also to a log file.
function Log-Error([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Red
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

## Initializations
$machineHostName          = (Get-WmiObject win32_computersystem).DNSHostName
$DefaultURL               = "https://" + $machineHostName + ":44369"
$TimeStamp                = [DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss")
$LogFileDir               = "$env:ProgramData`\Microsoft Azure Migrate App Containerization\Logs"
$MSIDownloadURL           = "https://download.microsoft.com/download/d/e/d/dedce2ef-6651-4b3d-9eb5-457b64d421e9/AzureMigrateAppContainerization.msi"
$WebAppMSI                = "AzureMigrateAppContainerization.msi"
$WebAppMSILog             = "$LogFileDir\AppContainerizationMSIInstaller-$TimeStamp.log"

## Creating the logfile
New-Item -ItemType Directory -Force -Path $LogFileDir | Out-Null
$InstallerLog = "$LogFileDir\AppContainerizationInstaller-$TimeStamp.log"
Log-Success "Log file created `"$InstallerLog`" for troubleshooting purpose.`n"

<#
.SYNOPSIS
Download MSI
Usage:
    DownloadMSI -MSIFilePath $MSIFilePath -DownloadURL $DownloadURL
#>

function DownloadMSI
{ 
    param(
        [string] $MSIFilePath,
        [string] $DownloadURL
        )

    Log-Info "Downloading $DownloadURL to $MSIFilePath..."
    Invoke-WebRequest $DownloadURL -OutFile $MSIFilePath;

    if (-Not (Test-Path -Path $MSIFilePath -PathType Any))
    {
        Log-Error "Failed to download the MSI at: $MSIFilePath. Aborting..."
        Log-Warning "Please ensure you are able to access the url: $DownloadURL"
        exit -9
    }

    Log-Success "[OK]`n"
}

<#
.SYNOPSIS
Install MSI
Usage:
    InstallMSI -MSIFilePath $MSIFilePath -MSIInstallLogName $MSIInstallLogName
#>

function InstallMSI
{ 
    param(
        [string] $MSIFilePath,
        [string] $MSIInstallLogName
        )

    Log-Info "Installing $MSIFilePath..."

    if (-Not (Test-Path -Path $MSIFilePath -PathType Any))
    {
        Log-Error "MSI not found: $MSIFilePath. Aborting..."
        Log-Warning "Please ensure the MSI is available at the $MSIFilePath."
        exit -3
    }

    $process = (Start-Process -Wait -Passthru -FilePath msiexec -ArgumentList `
        "/i `"$MSIFilePath`" /quiet /lv `"$MSIInstallLogName`"")

    $returnCode = $process.ExitCode;    
    if ($returnCode -eq 0 -or $returnCode -eq 3010) 
    {
        Log-Success "[OK]`n"
    }
    else
    {
        Log-Error "$MSIFilePath installation failed. More logs available at $MSIInstallLogName. Aborting..."
        Log-Warning "Please refer to http://www.msierrors.com/ to get details about the error code: $returnCode. Please share the installation log file $MSIInstallLogName while contacting Microsoft Support."
        exit -3
    }
}

<#
.SYNOPSIS
Enables IIS modules.
Usage:
    EnableIIS 
#>

function EnableIIS
{
    Log-Info "Enabling IIS Role and dependent features..."
    $OS = Get-WmiObject Win32_OperatingSystem
    if ($OS.Caption.contains("Server"))
    {
        Install-WindowsFeature PowerShell, WAS, WAS-Process-Model, WAS-Config-APIs, Web-Server, `
        Web-WebServer, Web-Mgmt-Service, Web-Request-Monitor, Web-Common-Http, Web-Static-Content, `
        Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-App-Dev, Web-CGI, Web-Health, `
        Web-Http-Logging, Web-Log-Libraries, Web-Security, Web-Filtering, Web-Performance, `
        Web-Stat-Compression, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Scripting-Tools, `
        Web-Asp-Net45, Web-Net-Ext45, Web-Http-Redirect, Web-Windows-Auth, Web-Url-Auth
    }
    else
    {
        Enable-WindowsOptionalFeature -Online -Feature IIS-WebServerRole, IIS-WebServer, `
		IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpRedirect, IIS-ApplicationDevelopment, `
		IIS-Security, IIS-RequestFiltering, IIS-ASPNET, IIS-NetFxExtensibility , IIS-NetFxExtensibility45, `
		IIS-HealthAndDiagnostics, IIS-HttpLogging, IIS-Performance, IIS-WebServerManagementTools, `
		IIS-DirectoryBrowsing, IIS-ASPNET45, IIS-WindowsAuthentication, `
		IIS-URLAuthorization, IIS-CertProvider, IIS-StaticContent, IIS-DefaultDocument, IIS-ISAPIExtensions, `
		IIS-ISAPIFilter, IIS-HttpCompressionStatic, IIS-ManagementConsole -All
    }
    if ($?)
    {
        Log-Success "[OK]`n"
    }
    else
    {
        Log-Error "Failure to enable the required IIS roles and features with error: $Errors. Aborting..."        
        exit -5
    }
}

<#
.SYNOPSIS
Validate OS version
Usage:
    ValidateOSVersion
#>
function ValidateOSVersion
{
    [System.Version]$ver = "0.0"
    [System.Version]$minVer = "10.0"

    Log-Info "Verifying supported Operating System version..."

    $OS = Get-WmiObject Win32_OperatingSystem
    $ver = $OS.Version

    If ($ver -lt $minVer)
    {
        Log-Error "The os version is $ver, minimum supported version is Windows Server 2016 ($minVer). Aborting..."
        exit -7
    }
    else
    {
        Log-Success "[OK]`n"
    }
}

<#
.SYNOPSIS
Validate and exit if minimum defined PowerShell version is not available.
Usage:
    ValidatePSVersion
#>

function ValidatePSVersion
{
    [System.Version]$minVer = "5.1"

    Log-Info "Verifying the PowerShell version to run the script..."

    if ($PSVersionTable.PSVersion)
    {
        $global:PsVer = $PSVersionTable.PSVersion
    }
    
    If ($global:PsVer -lt $minVer)
    {
        Log-Error "PowerShell version $minVer, or higher is required. Current PowerShell version is $global:PsVer. Aborting..."
        exit -11;
    }
    else
    {
        Log-Success "[OK]`n"
    }
}

<#
.SYNOPSIS
Validate and exit if PS process in not 64-bit as few cmdlets like install-windowsfeature is not available in 32-bit.
Usage:
    ValidateIsPowerShell64BitProcess
#>

function ValidateIsPowerShell64BitProcess
{
    Log-Info "Verifying the PowerShell is running in 64-bit mode..."

	# This check is valid for PowerShell 3.0 and higher only.
    if ([Environment]::Is64BitProcess)
    {
        Log-Success "[OK]`n"
    }
    else
    {
        Log-Warning "PowerShell process is found to be 32-bit. While launching PowerShell do not select Windows PowerShell (x86) and rerun the script. Aborting..."        
        Log-Error "[Failed]`n"
        exit -11;
    }
}

<#
.SYNOPSIS
Ensure IIS backend services are in running state. During IISReset they can remain in stop state as well.
Usage:
    StartIISServices
#>

function StartIISServices
{
    Log-Info "Ensuring critical services for Azure Migrate App Containerization are running..."

    Start-service -Name WAS
    Start-service -Name W3SVC

    if ($?)
    {
        Log-Success "[OK]`n"
    } else 
    {
        Log-Error "Failed to start services WAS/W3SVC. Aborting..."
        Log-Warning "Manually start the services WAS and W3SVC"
        exit -12
    }
}

try
{
    $Error.Clear()

    # Validate PowerShell, OS version and user role.
    ValidatePSVersion
	ValidateIsPowerShell64BitProcess
    ValidateOSVersion

    # Enable IIS.
    EnableIIS

    # Download and Install App Containerization WebApp
    DownloadMSI -MSIFilePath "$PSScriptRoot\$WebAppMSI" -DownloadURL $MSIDownloadURL
    InstallMSI -MSIFilePath "$PSScriptRoot\$WebAppMSI" -MSIInstallLogName $WebAppMSILog
 
    # Ensure critical services for WebApp are in running state.
    StartIISServices

    Log-Info "Installation completed successfully. Launching Azure Migrate App Containerization..."
    Start $DefaultURL
}
catch
{
    Log-Error "Script execution failed with error $_.Exception.Message"
    Log-Error "Error Record: $_.Exception.ErrorRecord"
    Log-Error "Exception caught:  $_.Exception"
    Log-Warning "Retry the script after resolving the issue(s) or contact Microsoft Support."
    exit -1
}
# SIG # Begin signature block
# MIIjkgYJKoZIhvcNAQcCoIIjgzCCI38CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBp5tR4FwGAADhz
# C0h60NLtIOqjg6o3Ma5Pk5Oq3fFExaCCDYEwggX/MIID56ADAgECAhMzAAABh3IX
# chVZQMcJAAAAAAGHMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjAwMzA0MTgzOTQ3WhcNMjEwMzAzMTgzOTQ3WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOt8kLc7P3T7MKIhouYHewMFmnq8Ayu7FOhZCQabVwBp2VS4WyB2Qe4TQBT8aB
# znANDEPjHKNdPT8Xz5cNali6XHefS8i/WXtF0vSsP8NEv6mBHuA2p1fw2wB/F0dH
# sJ3GfZ5c0sPJjklsiYqPw59xJ54kM91IOgiO2OUzjNAljPibjCWfH7UzQ1TPHc4d
# weils8GEIrbBRb7IWwiObL12jWT4Yh71NQgvJ9Fn6+UhD9x2uk3dLj84vwt1NuFQ
# itKJxIV0fVsRNR3abQVOLqpDugbr0SzNL6o8xzOHL5OXiGGwg6ekiXA1/2XXY7yV
# Fc39tledDtZjSjNbex1zzwSXAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhov4ZyO96axkJdMjpzu2zVXOJcsw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDU4Mzg1MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAixmy
# S6E6vprWD9KFNIB9G5zyMuIjZAOuUJ1EK/Vlg6Fb3ZHXjjUwATKIcXbFuFC6Wr4K
# NrU4DY/sBVqmab5AC/je3bpUpjtxpEyqUqtPc30wEg/rO9vmKmqKoLPT37svc2NV
# BmGNl+85qO4fV/w7Cx7J0Bbqk19KcRNdjt6eKoTnTPHBHlVHQIHZpMxacbFOAkJr
# qAVkYZdz7ikNXTxV+GRb36tC4ByMNxE2DF7vFdvaiZP0CVZ5ByJ2gAhXMdK9+usx
# zVk913qKde1OAuWdv+rndqkAIm8fUlRnr4saSCg7cIbUwCCf116wUJ7EuJDg0vHe
# yhnCeHnBbyH3RZkHEi2ofmfgnFISJZDdMAeVZGVOh20Jp50XBzqokpPzeZ6zc1/g
# yILNyiVgE+RPkjnUQshd1f1PMgn3tns2Cz7bJiVUaqEO3n9qRFgy5JuLae6UweGf
# AeOo3dgLZxikKzYs3hDMaEtJq8IP71cX7QXe6lnMmXU/Hdfz2p897Zd+kU+vZvKI
# 3cwLfuVQgK2RZ2z+Kc3K3dRPz2rXycK5XCuRZmvGab/WbrZiC7wJQapgBodltMI5
# GMdFrBg9IeF7/rP4EqVQXeKtevTlZXjpuNhhjuR+2DMt/dWufjXpiW91bo3aH6Ea
# jOALXmoxgltCp1K7hrS6gmsvj94cLRf50QQ4U8Qwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIVZzCCFWMCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAYdyF3IVWUDHCQAAAAABhzAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgEskp6DXr
# YWFEiUh4FetYJenm2n9Gc39itERpF9AHkGcwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQCox+6uBLEKRCjIlsQEjZS1jHwv5b4m85vLXl91+Jyz
# T9+c2s5mopwDYlDHW+cFi/a+LttgfHvDDnO82b+Aa7s+/X7q4S62oF6uJxwm6MbF
# r6ekDPGbgWyySsehnjpPE6SwpIblHPkNWH+LPZmBMwX0FLKVJj0VMAiHqJ8gmwjR
# tDtyTDyJa3fK6BxnTChQrdOVnt82be+KqWFAY7FB0V6yRr+ijiqVHj2exWKMQAX8
# kGx0SAJPwWo99LFqg5vbzgnzPKQxrbW/yxm8j2Ick2j6DE92R3AM0MAOZkbyvCQG
# E6oi90NUgpvhxzMYTevN6q2ou8H4YKsV5MVTj62H1BN/oYIS8TCCEu0GCisGAQQB
# gjcDAwExghLdMIIS2QYJKoZIhvcNAQcCoIISyjCCEsYCAQMxDzANBglghkgBZQME
# AgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIFy4ca5FVGIioyy1fk0m+ymGBsyVkT+7MMLZ4mPO
# oDFtAgZgGeQeMHIYEzIwMjEwMjA5MDY0MzU4Ljk1NVowBIACAfSggdSkgdEwgc4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1p
# Y3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpGNzdGLUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCDkQwggT1MIID3aADAgECAhMzAAABKugXlviGp++jAAAA
# AAEqMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTE5MTIxOTAxMTUwMloXDTIxMDMxNzAxMTUwMlowgc4xCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVy
# YXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpGNzdG
# LUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ/flYGkhdJtxSsHBu9l
# mXF/UXxPF7L45nEhmtd01KDosWbY8y54BN7+k9DMvzqToP39v8/Z+NtEzKj8Bf5E
# QoG1/pJfpzCJe80HZqyqMo0oQ9EugVY6YNVNa2T1u51d96q1hFmu1dgxt8uD2g7I
# pBQdhS2tpc3j3HEzKvV/vwEr7/BcTuwqUHqrrBgHc971epVR4o5bNKsjikawmMw9
# D/tyrTciy3F9Gq9pEgk8EqJfOdAabkanuAWTjlmBhZtRiO9W1qFpwnu9G5qVvdNK
# RKxQdtxMC04pWGfnxzDac7+jIql532IEC5QSnvY84szEpxw31QW/LafSiDmAtYWH
# pm8CAwEAAaOCARswggEXMB0GA1UdDgQWBBRw9MUtdCs/rhN2y9EkE6ZI9O8TaTAf
# BgNVHSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBH
# hkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNU
# aW1TdGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUF
# BzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0
# YVBDQV8yMDEwLTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMA0GCSqGSIb3DQEBCwUAA4IBAQCKwDT0CnHVo46OWyUbrPIj8QIcf+PT
# jBVYpKg1K2D15Z6xEuvmf+is6N8gj9f1nkFIALvh+iGkx8GgGa/oA9IhXNEFYPNF
# aHwHan/UEw1P6Tjdaqy3cvLC8f8zE1CR1LhXNofq6xfoT9HLGFSg9skPLM1TQ+RA
# QX9MigEm8FFlhhsQ1iGB1399x8d92h9KspqGDnO96Z9Aj7ObDtdU6RoZrsZkiRQN
# nXmnX1I+RuwtLu8MN8XhJLSl5wqqHM3rqaaMvSAISVtKySpzJC5Zh+5kJlqFdSiI
# HW8Q+8R6EWG8ILb9Pf+w/PydyK3ZTkVXUpFA+JhWjcyzphVGw9ffj0YKMIIGcTCC
# BFmgAwIBAgIKYQmBKgAAAAAAAjANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTAwNzAxMjEzNjU1WhcN
# MjUwNzAxMjE0NjU1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKkdDbx3EYo6IOz8E5f1+n9plGt0
# VBDVpQoAgoX77XxoSyxfxcPlYcJ2tz5mK1vwFVMnBDEfQRsalR3OCROOfGEwWbEw
# RA/xYIiEVEMM1024OAizQt2TrNZzMFcmgqNFDdDq9UeBzb8kYDJYYEbyWEeGMoQe
# dGFnkV+BVLHPk0ySwcSmXdFhE24oxhr5hoC732H8RsEnHSRnEnIaIYqvS2SJUGKx
# Xf13Hz3wV3WsvYpCTUBR0Q+cBj5nf/VmwAOWRH7v0Ev9buWayrGo8noqCjHw2k4G
# kbaICDXoeByw6ZnNPOcvRLqn9NxkvaQBwSAJk3jN/LzAyURdXhacAQVPIk0CAwEA
# AaOCAeYwggHiMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBTVYzpcijGQ80N7
# fEYbxTNoWoVtVTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDCBoAYDVR0g
# AQH/BIGVMIGSMIGPBgkrBgEEAYI3LgMwgYEwPQYIKwYBBQUHAgEWMWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9QS0kvZG9jcy9DUFMvZGVmYXVsdC5odG0wQAYIKwYB
# BQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AUABvAGwAaQBjAHkAXwBTAHQAYQB0AGUA
# bQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAAfmiFEN4sbgmD+BcQM9naOh
# IW+z66bM9TG+zwXiqf76V20ZMLPCxWbJat/15/B4vceoniXj+bzta1RXCCtRgkQS
# +7lTjMz0YBKKdsxAQEGb3FwX/1z5Xhc1mCRWS3TvQhDIr79/xn/yN31aPxzymXlK
# kVIArzgPF/UveYFl2am1a+THzvbKegBvSzBEJCI8z+0DpZaPWSm8tv0E4XCfMkon
# /VWvL/625Y4zu2JfmttXQOnxzplmkIz/amJ/3cVKC5Em4jnsGUpxY517IW3DnKOi
# PPp/fZZqkHimbdLhnPkd/DjYlPTGpQqWhqS9nhquBEKDuLWAmyI4ILUl5WTs9/S/
# fmNZJQ96LjlXdqJxqgaKD4kWumGnEcua2A5HmoDF0M2n0O99g/DhO3EJ3110mCII
# YdqwUB5vvfHhAN/nMQekkzr3ZUd46PioSKv33nJ+YWtvd6mBy6cJrDm77MbL2IK0
# cs0d9LiFAR6A+xuJKlQ5slvayA1VmXqHczsI5pgt6o3gMy4SKfXAL1QnIffIrE7a
# KLixqduWsqdCosnPGUFN4Ib5KpqjEWYw07t0MkvfY3v1mYovG8chr1m1rtxEPJdQ
# cdeh0sVV42neV8HR3jDA/czmTfsNv11P6Z0eGTgvvM9YBS7vDaBQNdrvCScc1bN+
# NR4Iuto229Nfj950iEkSoYIC0jCCAjsCAQEwgfyhgdSkgdEwgc4xCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpG
# NzdGLUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUA6rLmrKHyIMP76ePl321xKUJ3YX+ggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOPMSxEwIhgPMjAyMTAyMDkwMzQzMTNaGA8yMDIxMDIxMDAzNDMxM1owdzA9Bgor
# BgEEAYRZCgQBMS8wLTAKAgUA48xLEQIBADAKAgEAAgIHDQIB/zAHAgEAAgIRNTAK
# AgUA482ckQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIB
# AAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAJQc8tZWiASJsxZQ
# 9UuwknpsZ9Kqjj21sWySIcij24iAfavMiqMPJXomx+27LRlpZWpt8ZxNQZPORwk7
# II3sQodZYXH//XgDkvUpWt6m3WEGglVpni7NjzxofR5nu2oaK72+Mh0Sx9+CMtZ/
# Z6MoV3Zx5Bc++21zhw93Kh+oCShpMYIDDTCCAwkCAQEwgZMwfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAEq6BeW+Ian76MAAAAAASowDQYJYIZIAWUD
# BAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0B
# CQQxIgQgbrNzkdLMbtrYw5Y5qI1lYTCjCz0uE04sm8p3xV8XqrgwgfoGCyqGSIb3
# DQEJEAIvMYHqMIHnMIHkMIG9BCBDmDWEWvc6fhs5t4Woo5Q+FMFCcaIgV4yUP4Cp
# uBmLmTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
# KugXlviGp++jAAAAAAEqMCIEIPjZKdYBROOm+IsZElL/LfoAzhpybGioNmOobtQa
# qg4vMA0GCSqGSIb3DQEBCwUABIIBAFdQrOvVXViPNhQHorOtSYLxorYmKG+Xc7dW
# Osl+Uz4EtH2P01uMMxfTaNbjuT60amrl/RwCOrkbT8B0n4QLWKH6oNPetfvbAD9o
# yQuk96m9//AT41+Ci7nxPb1g3jUZgLurYIpO5VK8oAO1pF4ZZ/j9yiWKqW7adX2M
# VIVQ4xPwp7WqkVcPGl8tty2GWjk3cNdnVNaKcZKPafEoJvHeduehRC9uAYaHcwcW
# EKTejLsV5p9v41diw9MeUbvWjnpGUM3AMkqMP937Qj11NTFz6Gq9fTO7mSfHxORW
# /Zjt6AGb3GSkH6oHCd7P0oyQM+yWgr3HWwOZST77LHDhpJuMES0=
# SIG # End signature block
