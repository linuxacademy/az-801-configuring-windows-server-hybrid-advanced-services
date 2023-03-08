# Define variables
$shareName = "TestShare"
$directoryPath = "C:\$shareName"
$fullAccessUsers = "awesomeadmin"
$readAccessUsers = "Everyone"
$numFiles = 3  # Change this to the number of files you want to create
$maxFileSize = 10MB  # Change this to the maximum file size you want to create

# Create directory
New-Item -ItemType Directory -Path $directoryPath

# Set up SMB share
New-SmbShare -Name $shareName -Path $directoryPath -FullAccess $fullAccessUsers -ReadAccess $readAccessUsers

# Create random files
$random = New-Object System.Random
for ($i = 1; $i -le $numFiles; $i++) {
    $fileName = "File$i.txt"
    $filePath = Join-Path $directoryPath $fileName
    $fileSize = $random.Next(1, $maxFileSize)
    $fileStream = New-Object IO.FileStream($filePath, [IO.FileMode]::Create)
    $fileStream.SetLength($fileSize)
    $fileStream.Close()
}
