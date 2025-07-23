#!/usr/bin/env bash
set -uo pipefail  # No -e to support write to canary file after cancel

. "$EXTENSION_PATH/shared.sh"

# Read LSP references from the temporary file created by the TypeScript extension
REFERENCES_FILE="$TEMP_DIR/lsp_references"

if [[ ! -f "$REFERENCES_FILE" ]]; then
    echo "No LSP references file found" > "$CANARY_FILE"
    exit 1
fi

# Check if we have any references
if [[ ! -s "$REFERENCES_FILE" ]]; then
    echo "No references found" > "$CANARY_FILE"
    exit 1
fi

# Run fzf on the references file
# The format is: file:line:char:text
PREVIEW_ENABLED=${FIND_LSP_REFERENCES_PREVIEW_ENABLED:-1}
PREVIEW_COMMAND=${FIND_LSP_REFERENCES_PREVIEW_COMMAND:-'bat --decorations=always --color=always {1} --highlight-line {2} --style=header,grid'}
PREVIEW_WINDOW=${FIND_LSP_REFERENCES_PREVIEW_WINDOW_CONFIG:-'right:border-left:50%:+{2}+3/3:~3'}

PREVIEW_STR=()
if [[ "$PREVIEW_ENABLED" -eq 1 ]]; then
    PREVIEW_STR=(--preview "$PREVIEW_COMMAND" --preview-window "$PREVIEW_WINDOW")
fi

# IFS sets the delimiter
# -r: raw
# -a: array
IFS=: read -ra VAL < <(
    cat "$REFERENCES_FILE" | fzf --ansi \
        --keep-right \
        --cycle \
        --delimiter : \
        ${PREVIEW_STR[@]+"${PREVIEW_STR[@]}"} \
)

# Output is filename, line number, character, contents
if [[ ${#VAL[@]} -eq 0 ]]; then
    echo canceled
    echo "1" > "$CANARY_FILE"
    exit 1
else
    FILENAME=${VAL[0]}:${VAL[1]}:${VAL[2]}
    echo "$FILENAME" > "$CANARY_FILE"
fi 
