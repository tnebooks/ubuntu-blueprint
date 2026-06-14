#!/bin/bash

# Exit immediately if a command fails
set -e

# Core Configuration
BASE_PURGE="./purge.properties"
BASE_INSTALL="./install.properties"
LOG_FILE="./pc_cleanup.log"

# Catch ALL profile arguments passed via the command line
PROFILES=("$@")

echo "==========================================="
echo " Factory Reset & System Cleanup Script"
echo "==========================================="

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script using sudo!"
  exit 1
fi

# Verify core system configuration files exist
if [ ! -f "$BASE_PURGE" ] || [ ! -f "$BASE_INSTALL" ]; then
  echo "Error: Missing configuration files (purge.properties or install.properties)"
  exit 1
fi

# Initialize the log file
echo "=== Factory Reset Log: $(date) ===" > "$LOG_FILE"

# Prevent interactive prompts from blocking execution
export DEBIAN_FRONTEND=noninteractive

declare -A APP_LABELS
RAW_REMOVE_LIST=()
RAW_REINSTALL_LIST=()

# Helper function to parse properties files
parse_properties() {
    local target_file=$1
    local mode=$2 # "remove" or "reinstall"
    [ ! -f "$target_file" ] && return 0
    
    while IFS='=' read -r package label || [ -n "$package" ]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        package=$(echo "$package" | xargs)
        label=$(echo "$label" | xargs)

        APP_LABELS["$package"]="$label"
        if [ "$mode" == "remove" ]; then
            RAW_REMOVE_LIST+=("$package")
        else
            RAW_REINSTALL_LIST+=("$package")
        fi
    done < "$target_file"
}

# ==========================================
# PHASE 1: COLLECTING BLUEPRINTS
# ==========================================
echo "Analyzing blueprints for total system rollback..."

if [ ${#PROFILES[@]} -eq 0 ]; then
    echo "No profiles specified. Full System Reset triggered (Base + All Profiles)."
    # Collect baseline items
    parse_properties "$BASE_INSTALL" "remove"
    parse_properties "$BASE_PURGE" "reinstall"
    
    # Automatically scan and rollback all existing profile folders for a true factory reset
    for dir in ./*/; do
        [ -d "$dir" ] || continue
        profile_name=$(basename "$dir")
        
        parse_properties "./$profile_name/install.properties" "remove"
        parse_properties "./$profile_name/purge.properties" "reinstall"
    done
else
    # Targeted rollback for specific profiles only
    for PROFILE in "${PROFILES[@]}"; do
        if [ -d "./$PROFILE" ]; then
            echo "Queuing profile [$PROFILE] for rollback..."
            parse_properties "./$PROFILE/install.properties" "remove"
            parse_properties "./$PROFILE/purge.properties" "reinstall"
        else
            echo "Warning: Profile directory './$PROFILE' not found. Skipping."
        fi
    done
fi

# ==========================================
# PHASE 2: DEDUPLICATE & RESOLVE CONFLICTS
# ==========================================
declare -A uniq_remove uniq_reinstall
for pkg in "${RAW_REMOVE_LIST[@]}"; do uniq_remove["$pkg"]=1; done
for pkg in "${RAW_REINSTALL_LIST[@]}"; do uniq_reinstall["$pkg"]=1; done

# Safety Rule: If something is marked to be put back (reinstalled), 
# make sure it isn't also on the removal list.
for pkg in "${!uniq_reinstall[@]}"; do
    unset uniq_remove["$pkg"]
done

FINAL_REMOVE=("${!uniq_remove[@]}")
FINAL_REINSTALL=("${!uniq_reinstall[@]}")

# ==========================================
# PHASE 3: THE UNINSTALL STEP
# ==========================================
echo "-------------------------------------------"
echo " Step 1: Removing Installed Packages"
echo "-------------------------------------------"
PACKAGES_TO_PURGE=()
for package in "${FINAL_REMOVE[@]}"; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
        PACKAGES_TO_PURGE+=("$package")
    fi
done

if [ ${#PACKAGES_TO_PURGE[@]} -gt 0 ]; then
    echo "Purging custom installed apps..."
    apt-get purge -y "${PACKAGES_TO_PURGE[@]}" > /dev/null 2>&1 || true
    for pkg in "${PACKAGES_TO_PURGE[@]}"; do
        echo "- Uninstalled: ${APP_LABELS["$pkg"]:-$pkg} ($pkg)" >> "$LOG_FILE"
    done
else
    echo "No custom packages found on the system to remove."
fi

# ==========================================
# PHASE 4: THE RE-INSTALL (RESTORE) STEP
# ==========================================
echo "-------------------------------------------"
echo " Step 2: Restoring Factory Default Packages"
echo "-------------------------------------------"
PACKAGES_TO_RESTORE=()
for package in "${FINAL_REINSTALL[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
        PACKAGES_TO_RESTORE+=("$package")
    fi
done

if [ ${#PACKAGES_TO_RESTORE[@]} -gt 0 ]; then
    echo "Re-installing original baseline applications..."
    apt-get update -y > /dev/null
    apt-get install -y "${PACKAGES_TO_RESTORE[@]}" > /dev/null 2>&1 || true
    for pkg in "${PACKAGES_TO_RESTORE[@]}"; do
        echo "- Restored Baseline: ${APP_LABELS["$pkg"]:-$pkg} ($pkg)" >> "$LOG_FILE"
    done
else
    echo "System baseline apps are already intact."
fi

# ==========================================
# PHASE 5: DEEP CLEAN OPERATING SYSTEM
# ==========================================
echo "-------------------------------------------"
echo " Step 3: Final System Polishing"
echo "-------------------------------------------"
apt-get autoremove --purge -y > /dev/null
apt-get clean -y > /dev/null

# ==========================================
# PHASE 6: WIPING PROPERTY BLUEPRINTS
# ==========================================
echo "-------------------------------------------"
echo " Step 4: Truncating Installation Properties"
echo "-------------------------------------------"

if [ ${#PROFILES[@]} -eq 0 ]; then
    echo "Wiping baseline install.properties file..."
    echo "# Baseline Installation Properties (Reset to Blank)" > "$BASE_INSTALL"
    
    # Safely scan for profile directories and clear their files
    for dir in ./*/; do
        [ -d "$dir" ] || continue
        profile_name=$(basename "$dir")
        
        if [ -f "./$profile_name/install.properties" ]; then
            echo "Wiping ./$profile_name/install.properties..."
            echo "# Profile $profile_name Installation Properties (Reset to Blank)" > "./$profile_name/install.properties"
        fi
    done
else
    # Only wipe the files for the specific profiles passed as arguments
    for PROFILE in "${PROFILES[@]}"; do
        if [ -f "./$PROFILE/install.properties" ]; then
            echo "Wiping ./$PROFILE/install.properties..."
            echo "# Profile $PROFILE Installation Properties (Reset to Blank)" > "./$PROFILE/install.properties"
        fi
    done
fi

echo "===========================================" >> "$LOG_FILE"
echo "Cleanup and blueprint reset completed successfully." >> "$LOG_FILE"

echo "==========================================="
echo " Factory Reset Complete! Blueprints & OS are back to zero."
echo "==========================================="