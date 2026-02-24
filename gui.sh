#!/bin/bash

# --- Cron-Editor Pro by Giorgich11 ---
# Dependency: sudo apt install yad

STORAGE_DIR="$HOME/.cron-factory/scripts"
mkdir -p "$STORAGE_DIR"

while true; do
    # 1. Fetch current jobs
    CURRENT_JOBS=$(crontab -l 2>/dev/null | grep -v '^#' | sed 's/ /|/1; s/ /|/1; s/ /|/1; s/ /|/1; s/ /|/1')

    # 2. Main Dashboard
    CHOICE=$(yad --list --title="Cron-Editor Pro 2026" --width=1000 --height=600 \
        --column="Min" --column="Hr" --column="Dom" --column="Mon" --column="Dow" --column="Command/Script" \
        --button="Write New Script:2" --button="Delete Selected:3" --button="Edit Selected:4" --button="Exit:1" \
        $CURRENT_JOBS)

    ACTION=$?

    # Exit
    [[ $ACTION -eq 1 ]] && break

    # 3. Create or Edit a Script
    if [[ $ACTION -eq 2 ]] || [[ $ACTION -eq 4 ]]; then
        
        # If editing, try to extract the script path or code
        EXISTING_CMD=""
        SCRIPT_NAME="new_task_$(date +%s).sh"
        
        if [[ $ACTION -eq 4 ]]; then
             EXISTING_CMD=$(echo "$CHOICE" | cut -d'|' -f6-)
             # If it's a file path, load the content
             [[ -f "$EXISTING_CMD" ]] && SCRIPT_CONTENT=$(cat "$EXISTING_CMD") || SCRIPT_CONTENT="$EXISTING_CMD"
        else
             SCRIPT_CONTENT="#!/bin/bash\n\n# Type your code here, bro\necho 'Hello World'"
        fi

        # The Code Editor Window
        # This is where they type the actual Bash code
        DATA=$(yad --form --title="Script Editor" --width=600 --height=500 \
            --field="Script Filename" "$SCRIPT_NAME" \
            --field="Schedule (e.g. * * * * *)" "* * * * *" \
            --field="Your Code:TXT" "$SCRIPT_CONTENT" \
            --button="Save & Schedule:0" --button="Cancel:1")

        if [[ $? -eq 0 ]]; then
            FILENAME=$(echo "$DATA" | cut -d'|' -f1)
            SCHEDULE=$(echo "$DATA" | cut -d'|' -f2)
            CODE=$(echo "$DATA" | cut -d'|' -f3)

            # Save the file
            FULL_PATH="$STORAGE_DIR/$FILENAME"
            echo -e "$CODE" > "$FULL_PATH"
            chmod +x "$FULL_PATH"

            # Add to Crontab (avoiding duplicates)
            (crontab -l 2>/dev/null | grep -vF "$FULL_PATH"; echo "$SCHEDULE $FULL_PATH") | crontab -
            yad --info --text="Script saved and scheduled at $FULL_PATH" --timeout=2
        fi

    # 4. Delete Logic
    elif [[ $ACTION -eq 3 ]]; then
        CLEAN_ROW=$(echo "$CHOICE" | tr '|' ' ')
        crontab -l | grep -vF "$CLEAN_ROW" | crontab -
    fi
done