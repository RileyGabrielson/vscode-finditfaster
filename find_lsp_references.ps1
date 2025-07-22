trap
{
    # If we except, lets report it visually. Can help with debugging if there IS a problem
    # in here.
    Write-Host "EXCEPTION: $($PSItem.ToString())" -ForegroundColor Red
    Write-Host "$($PSItem.ScriptStackTrace)"
    Start-Sleep 10
}

# Get an environment variable with default value if not present
function VGet($varname, $default) {
    if (Test-Path "$varname") {
        $val = (Get-Item $varname).Value
        if ("$val".Length -gt 0) {
            return $val
        }
    } 
    return $default
}

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

$PREVIEW_ENABLED=VGet "env:FIND_WITHIN_FILES_PREVIEW_ENABLED" 1
$PREVIEW_COMMAND=VGet "env:FIND_WITHIN_FILES_PREVIEW_COMMAND"  'bat --decorations=always --color=always {1} --highlight-line {2} --style=header,grid'
$PREVIEW_WINDOW=VGet "env:FIND_WITHIN_FILES_PREVIEW_WINDOW_CONFIG" 'right:border-left:50%:+{2}+3/3:~3'

$fzf_command = "fzf --cycle --delimiter :"
if ( $PREVIEW_ENABLED -eq 1){
    $fzf_command+=" --preview '$PREVIEW_COMMAND' --preview-window $PREVIEW_WINDOW"
} 

$expression = "Get-Content '$REFERENCES_FILE' | $fzf_command"
$result = Invoke-Expression( $expression )

# Output is filename, line number, character, contents
if ("$result".Length -lt 1) {
    Write-Host canceled
    "1" | Out-File -FilePath "$Env:CANARY_FILE" -Encoding UTF8
    exit 1
} else {
    $parts = $result -split ':'
    if ($parts.Length -ge 3) {
        "$($parts[0]):$($parts[1]):$($parts[2])" | Out-File -FilePath "$Env:CANARY_FILE" -Encoding UTF8
    } else {
        "1" | Out-File -FilePath "$Env:CANARY_FILE" -Encoding UTF8
        exit 1
    }
} 
