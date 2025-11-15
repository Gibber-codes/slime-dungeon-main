$docxPath = 'docs/Slime Dungeon MVP 2025.docx'
$outputPath = 'docs/_mvp_document.xml'

Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($docxPath)
$entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }

if ($entry) {
    $stream = $entry.Open()
    $reader = New-Object System.IO.StreamReader($stream)
    $content = $reader.ReadToEnd()
    $reader.Close()
    $stream.Close()
    $zip.Dispose()
    
    $content | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Host "Extracted document.xml successfully"
} else {
    $zip.Dispose()
    Write-Host "Could not find word/document.xml in the archive"
}

