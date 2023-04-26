try {
    Get-Service | Where-Object {$_.Status -eq "Running"}   
}
catch {
    Write-Host "Script Failed to Run"
    Write-Host "$_"
}