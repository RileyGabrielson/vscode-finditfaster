# Read LSP references from the temporary file created by the TypeScript extension
$REFERENCES_FILE = Join-Path $env:TEMP_DIR "lsp_references"

if (-not (Test-Path $REFERENCES_FILE)) {
    "No LSP references file found" | Out-File -FilePath $env:CANARY_FILE -Encoding UTF8
    exit 1
}

# Check if we have any references
if ((Get-Item $REFERENCES_FILE).Length -eq 0) {
    "No references found" | Out-File -FilePath $env:CANARY_FILE -Encoding UTF8
    exit 1
}

# For now, just write the first reference to the canary file
# PowerShell doesn't have fzf, so we'll just take the first line
$firstLine = Get-Content $REFERENCES_FILE -TotalCount 1
if ($firstLine) {
    $parts = $firstLine -split ':'
    if ($parts.Length -ge 3) {
        "$($parts[0]):$($parts[1]):$($parts[2])" | Out-File -FilePath $env:CANARY_FILE -Encoding UTF8
    } else {
        "1" | Out-File -FilePath $env:CANARY_FILE -Encoding UTF8
        exit 1
    }
} else {
    "1" | Out-File -FilePath $env:CANARY_FILE -Encoding UTF8
    exit 1
} 
