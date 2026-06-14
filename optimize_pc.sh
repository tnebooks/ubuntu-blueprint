#!/bin/bash

# Exit immediately if a command fails
set -e

# Core Configuration
BASE_PURGE="./purge.properties"
BASE_INSTALL="./install.properties"
LOG_FILE="./pc_management.log"

# Catch ALL profile arguments passed via the command line
PROFILES=("$@")

echo "==========================================="
echo " Starting System Optimization & Setup Script"
echo "==========================================="

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script using sudo!"
  exit 1
fi

# Verify core system configuration files exist
if [ ! -f "$BASE_PURGE" ] || [ ! -f "$BASE_INSTALL" ]; then
  echo "Error: Missing baseline configuration files (purge.properties or install.properties)"
  exit 1
fi

# Initialize the log file with a clean header
echo "=== System Management Log: $(date) ===" > "$LOG_FILE"
if [ ${#PROFILES[@]} -gt 0 ]; then
  echo "Target Profiles Selected: ${PROFILES[*]}" | tee -a "$LOG_FILE"
else
  echo "Target Profile Selected: Baseline Only (No subject profile specified)" | tee -a "$LOG_FILE"
fi

# Prevent interactive prompts from blocking the script execution
export DEBIAN_FRONTEND=noninteractive

# Global associative arrays to track package meta data (Labels)
declare -A APP_LABELS

# Global indexed arrays to accumulate targets
RAW_INSTALL_LIST=()
RAW_PURGE_LIST=()

# Helper function to parse a properties file into memory lists
collect_packages() {
    local target_file=$1
    local type=$2 # "install" or "purge"
    [ ! -f "$target_file" ] && return 0
    
    while IFS='=' read -r package label || [ -n "$package" ]; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        package=$(echo "$package" | xargs)
        label=$(echo "$label" | xargs)

        # Store the human-readable label
        APP_LABELS["$package"]="$label"

        if [ "$type" == "install" ]; then
            RAW_INSTALL_LIST+=("$package")
        else
            RAW_PURGE_LIST+=("$package")
        fi
    done < "$target_file"
}

# ==========================================
# PHASE 0: PRE-FLIGHT REPAIR & COLLECTION
# ==========================================
echo "Checking and repairing system dependencies..."
apt-get update -y > /dev/null
apt-get --fix-broken install -y > /dev/null || true
dpkg --configure -a > /dev/null || true

echo "Parsing configuration and building deployment map..."

# 1. Collect Baseline configurations
collect_packages "$BASE_INSTALL" "install"
collect_packages "$BASE_PURGE" "purge"

# 2. Collect Profile configurations iteratively 
for PROFILE in "${PROFILES[@]}"; do
    if [ -d "./$PROFILE" ]; then
        collect_packages "./$PROFILE/install.properties" "install"
        collect_packages "./$PROFILE/purge.properties" "purge"
    else
        echo "Warning: Profile directory './$PROFILE' not found. Skipping profile parsing." | tee -a "$LOG_FILE"
    fi
done

# ==========================================
# COMPOSITE COMPILATION (Deduplicate & Resolve)
# ==========================================

# Unique de-duplication using bash associative arrays
declare -A uniq_install uniq_purge

for pkg in "${RAW_INSTALL_LIST[@]}"; do uniq_install["$pkg"]=1; done
for pkg in "${RAW_PURGE_LIST[@]}"; do uniq_purge["$pkg"]=1; done

# RULE: If a package is marked for installation anywhere, it CANNOT be purged.
for pkg in "${!uniq_install[@]}"; do
    if [ -n "${uniq_purge[$pkg]}" ]; then
        echo "  -> Conflict Alert: '$pkg' requested by module but marked for purge. Retaining package."
        unset uniq_purge["$pkg"]
    fi
done

# Generate final execution arrays
FINAL_INSTALL=("${!uniq_install[@]}")
FINAL_PURGE=("${!uniq_purge[@]}")

# ==========================================
# PHASE 1: PURGING UNWANTED SOFTWARE
# ==========================================
echo "-------------------------------------------"
echo " Phase 1: Removing Unwanted Software"
echo "-------------------------------------------"
echo -e "\n### REMOVED SOFTWARE ###" >> "$LOG_FILE"

PACKAGES_TO_PURGE=()

for package in "${FINAL_PURGE[@]}"; do
    label=${APP_LABELS["$package"]:-$package}
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
        echo "  -> Queueing for Purge: $label ($package)"
        echo "- Removed: $label ($package)" >> "$LOG_FILE"
        PACKAGES_TO_PURGE+=("$package")
    fi
done

if [ ${#PACKAGES_TO_PURGE[@]} -gt 0 ]; then
    echo "Executing composite purge operation..."
    apt-get purge -y "${PACKAGES_TO_PURGE[@]}" > /dev/null 2>&1 || echo "     (Warning: Some packages failed to purge)"
fi

# Clean Snap Packages (Specific wrapper for Thunderbird remains)
echo "Checking for targeted Snap applications slated for removal..."
if snap list thunderbird >/dev/null 2>&1; then
    echo "  -> Removing Thunderbird (Snap)..."
    echo "- Removed: Thunderbird Mail (Snap)" >> "$LOG_FILE"
    snap remove --purge thunderbird > /dev/null 2>&1 || echo "     (Failed to remove Thunderbird snap)"
fi

# Clean up leftovers immediately after all purges finish
echo "Cleaning up leftover files and dependencies..."
apt-get autoremove -y > /dev/null
apt-get clean -y

# ==========================================
# PHASE 2: INSTALLING REQUIRED SOFTWARE
# ==========================================
echo "-------------------------------------------"
echo " Phase 2: Installing Target Apps"
echo "-------------------------------------------"
echo -e "\n### INSTALLED SOFTWARE ###" >> "$LOG_FILE"

PACKAGES_TO_INSTALL=()

for package in "${FINAL_INSTALL[@]}"; do
    label=${APP_LABELS["$package"]:-$package}
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
        echo "  -> Skipping: $label ($package) - Already installed."
    else
        echo "  -> Queueing for Installation: $label ($package)"
        PACKAGES_TO_INSTALL+=("$package")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "Executing composite installation operation..."
    
    # Try bulk installation first for speed
    if apt-get install -y "${PACKAGES_TO_INSTALL[@]}" > /dev/null 2>&1; then
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            echo "- Installed: ${APP_LABELS["$pkg"]:-$pkg} ($pkg)" >> "$LOG_FILE"
        done
        echo "  -> Bulk installation successful!"
    else
        echo "     [Warning] Bulk installation failed. Falling back to individual installation mode..." >> "$LOG_FILE"
        echo "     Bulk block failed. Retrying packages individually to isolate the broken one..."
        
        # Fallback loop: Install one by one
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            label=${APP_LABELS["$pkg"]:-$pkg}
            echo "     -> Attempting isolated install for: $label ($pkg)..."
            
            # Capture standard error into a variable instead of discarding it
            ERR_MSG=$(apt-get install -y "$pkg" 2>&1 >/dev/null)
            
            if [ $? -eq 0 ]; then
                echo "        Success!"
                echo "- Installed: $label ($pkg)" >> "$LOG_FILE"
            else
                echo "        FAILED! (Skipping $pkg)"
                # Extract just the last relevant line of the apt error for the terminal
                REASON=$(echo "$ERR_MSG" | tail -n 2)
                echo "        Reason: $REASON"
                echo "     !! Error: Could not install $label ($pkg) !!" | tee -a "$LOG_FILE"
                echo "- FAILED: $label ($pkg) | Reason: $REASON" >> "$LOG_FILE"
            fi
        done
    fi
fi

echo "===========================================" >> "$LOG_FILE"
echo "Process completed successfully." >> "$LOG_FILE"

echo "==========================================="
echo " Execution Complete! "
echo " Detailed summary saved to: $LOG_FILE"
echo "==========================================="