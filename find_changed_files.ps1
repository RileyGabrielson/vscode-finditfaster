# PowerShell script for finding changed files with git diff preview
param(
    [string[]]$Paths = @()
)

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

$PREVIEW_ENABLED = VGet "env:FIND_CHANGED_FILES_PREVIEW_ENABLED" 1
$PREVIEW_COMMAND = VGet "env:FIND_CHANGED_FILES_PREVIEW_COMMAND" 'git diff --color=always {}'
$PREVIEW_WINDOW = VGet "env:FIND_CHANGED_FILES_PREVIEW_WINDOW_CONFIG" 'right:50%:border-left'
$HAS_SELECTION = VGet "env:HAS_SELECTION" 0
$RESUME_SEARCH = VGet "env:RESUME_SEARCH" 0
$CANARY_FILE = VGet "env:CANARY_FILE" '/tmp/canaryFile'
$QUERY = ''

# If we only have one directory to search, invoke commands relative to that directory
$PATHS = $args
$SINGLE_DIR_ROOT = ""
if ($PATHS.Count -eq 1) {
    $SINGLE_DIR_ROOT = $PATHS[0]
    if ( -not (Test-Path "$SINGLE_DIR_ROOT")) {
        Write-Host "Failed to push into: $SINGLE_DIR_ROOT" -ForegroundColor Red
        exit 1
    }
    Push-Location "$SINGLE_DIR_ROOT"
    $PATHS = ""
}

$QUERY = ""
if ($HAS_SELECTION -eq 1 -and (VGet "env:SELECTION_FILE" "").Length -gt 0) {
    $QUERY = "`"$(Get-Content (VGet "env:SELECTION_FILE" "") -Raw)`""
}

$fzf_command = "fzf --cycle --multi"
if ("$QUERY".Length -gt 0) {
    $fzf_command += " --query"
    $fzf_command += " "
    $fzf_command += "${QUERY}"
}

if ($PREVIEW_ENABLED -eq 1) {
    $fzf_command += " --preview '$PREVIEW_COMMAND' --preview-window $PREVIEW_WINDOW"
}

# Get changed files from git and pipe to fzf
$expression = "git status --porcelain | ForEach-Object { `$parts = `$_ -split '\s+'; if (`$parts[0] -match '^R') { `$parts[2] } else { `$parts[1] } } | Where-Object { `$_ -ne '' } | Sort-Object -Unique | $fzf_command"
$result = Invoke-Expression($expression)

# Output is filename
if ("$result".Length -lt 1) {
    Write-Host canceled
    "1" | Out-File -FilePath "$CANARY_FILE" -Encoding UTF8
    exit 1
} else {
    if ("$SINGLE_DIR_ROOT".Length -gt 0) {
        Join-Path -Path "$SINGLE_DIR_ROOT" -ChildPath "$result" | Out-File -FilePath "$CANARY_FILE" -Encoding UTF8
    } else {
        $result | Out-File -FilePath "$CANARY_FILE" -Encoding UTF8
    }
} 