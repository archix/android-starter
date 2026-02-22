#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# bootstrap.sh — Set up this Android starter template for a new project
# =============================================================================

# --- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()    { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
error()   { printf "${RED}✗${NC} %s\n" "$1"; }
header()  { printf "\n${BOLD}${CYAN}── %s ──${NC}\n\n" "$1"; }

# --- Usage -------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}Usage:${NC} ./bootstrap.sh <PACKAGE_NAME> <APP_NAME>

${BOLD}Arguments:${NC}
  PACKAGE_NAME   New package name (e.g. com.company.appname)
                 Must be three dot-separated segments, lowercase letters only.
  APP_NAME       New app name in PascalCase (e.g. MyApp)

${BOLD}Example:${NC}
  ./bootstrap.sh com.acme.superapp SuperApp
EOF
    exit 1
}

# --- Args --------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
    error "Missing required arguments."
    echo
    usage
fi

PACKAGE_NAME="$1"
APP_NAME="$2"

# --- Validation --------------------------------------------------------------
if ! echo "$PACKAGE_NAME" | grep -qE '^[a-z]+\.[a-z]+\.[a-z]+$'; then
    error "Invalid PACKAGE_NAME: '${PACKAGE_NAME}'"
    echo "  Must match pattern: xx.xx.xx (three dot-separated segments, lowercase letters only)"
    echo "  Example: com.company.appname"
    exit 1
fi

if [[ -z "$APP_NAME" ]]; then
    error "APP_NAME cannot be empty."
    exit 1
fi

# --- Derived values ----------------------------------------------------------
OLD_PACKAGE="com.starter.app"
OLD_PACKAGE_PATH="com/starter/app"
OLD_APP_NAME="Starter"
OLD_APP_CLASS="StarterApplication"
OLD_DISPLAY_NAME_FULL="Android Starter"
OLD_DISPLAY_NAME="Starter"

NEW_PACKAGE_PATH="${PACKAGE_NAME//\.//}"
NEW_APP_CLASS="${APP_NAME}Application"

# Theme style names (no spaces, used in XML)
OLD_THEME_NAME="Theme.Starter"
NEW_THEME_NAME="Theme.${APP_NAME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Confirmation ------------------------------------------------------------
header "Bootstrap: Android Starter Template"

echo "This script will configure the project with the following settings:"
echo
printf "  ${BOLD}Package name:${NC}     %s → ${GREEN}%s${NC}\n" "$OLD_PACKAGE" "$PACKAGE_NAME"
printf "  ${BOLD}Package path:${NC}     %s → ${GREEN}%s${NC}\n" "$OLD_PACKAGE_PATH" "$NEW_PACKAGE_PATH"
printf "  ${BOLD}App name:${NC}         %s → ${GREEN}%s${NC}\n" "$OLD_APP_NAME" "$APP_NAME"
printf "  ${BOLD}Application class:${NC} %s → ${GREEN}%s${NC}\n" "$OLD_APP_CLASS" "$NEW_APP_CLASS"
printf "  ${BOLD}Theme name:${NC}       %s → ${GREEN}%s${NC}\n" "$OLD_THEME_NAME" "$NEW_THEME_NAME"
echo
echo "The following actions will be performed:"
echo "  1. Replace package name in all source files (Kotlin, Gradle, XML, YAML, MD, JSON)"
echo "  2. Replace app name references across the project"
echo "  3. Rename source directories to match the new package path"
echo "  4. Rename Application class file"
echo "  5. Update settings.gradle.kts rootProject name"
echo "  6. Update CLAUDE.md documentation"
echo "  7. Delete google-services.json (you must add your own)"
echo "  8. Reinitialize git history"
echo

printf "${YELLOW}Proceed? [y/N]${NC} "
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

echo

# --- Helper: find and replace in files ---------------------------------------
# Uses find + sed to replace strings across the project.
# Skips .git, build dirs, and binary files.
replace_in_files() {
    local old="$1"
    local new="$2"
    local description="$3"

    # Escape special characters for sed
    local old_escaped new_escaped
    old_escaped=$(printf '%s\n' "$old" | sed 's/[&/\]/\\&/g')
    new_escaped=$(printf '%s\n' "$new" | sed 's/[&/\]/\\&/g')

    local count=0
    while IFS= read -r -d '' file; do
        if grep -q "$old" "$file" 2>/dev/null; then
            sed -i '' "s|${old_escaped}|${new_escaped}|g" "$file"
            count=$((count + 1))
        fi
    done < <(find "$SCRIPT_DIR" \
        -type f \
        \( -name "*.kt" -o -name "*.kts" -o -name "*.xml" -o -name "*.yml" \
           -o -name "*.yaml" -o -name "*.md" -o -name "*.json" -o -name "*.properties" \) \
        ! -path "*/.git/*" \
        ! -path "*/build/*" \
        ! -path "*/bootstrap.sh" \
        -print0)

    if [[ $count -gt 0 ]]; then
        info "${description} — updated ${count} file(s)"
    else
        warn "${description} — no files matched"
    fi
}

# --- Step 1: Replace package name --------------------------------------------
header "Step 1: Replacing package name"

replace_in_files "$OLD_PACKAGE" "$PACKAGE_NAME" "Replace '${OLD_PACKAGE}' → '${PACKAGE_NAME}'"
# Also replace the path form (com/starter/app) used in documentation
replace_in_files "$OLD_PACKAGE_PATH" "$NEW_PACKAGE_PATH" "Replace '${OLD_PACKAGE_PATH}' → '${NEW_PACKAGE_PATH}' (path form)"

# --- Step 2: Replace app name ------------------------------------------------
header "Step 2: Replacing app name"

# Order matters: replace longer/more specific strings first to avoid partial matches
replace_in_files "$OLD_APP_CLASS" "$NEW_APP_CLASS" "Replace '${OLD_APP_CLASS}' → '${NEW_APP_CLASS}' (Application class)"
replace_in_files "$OLD_THEME_NAME" "$NEW_THEME_NAME" "Replace '${OLD_THEME_NAME}' → '${NEW_THEME_NAME}' (theme)"
replace_in_files "$OLD_APP_NAME" "$APP_NAME" "Replace '${OLD_APP_NAME}' → '${APP_NAME}' (app name)"
replace_in_files "$OLD_DISPLAY_NAME_FULL" "$APP_NAME" "Replace '${OLD_DISPLAY_NAME_FULL}' → '${APP_NAME}' (display name)"

# Replace standalone "Starter" last (only in non-package contexts — the package
# replacement already handled com.starter.app). We target remaining occurrences
# like placeholder text and README titles.
# Use a targeted approach: only files that still contain "Starter" after previous steps.
while IFS= read -r -d '' file; do
    if grep -q "Starter" "$file" 2>/dev/null; then
        sed -i '' "s|Starter|${APP_NAME}|g" "$file"
    fi
done < <(find "$SCRIPT_DIR" \
    -type f \
    \( -name "*.kt" -o -name "*.kts" -o -name "*.xml" -o -name "*.yml" \
       -o -name "*.yaml" -o -name "*.md" -o -name "*.json" -o -name "*.properties" \) \
    ! -path "*/.git/*" \
    ! -path "*/build/*" \
    ! -path "*/bootstrap.sh" \
    -print0)
info "Replace remaining 'Starter' → '${APP_NAME}' (standalone references)"

# --- Step 3: Rename source directories ---------------------------------------
header "Step 3: Renaming source directories"

rename_package_dir() {
    local source_set="$1" # main, test, or androidTest
    local base_dir="${SCRIPT_DIR}/app/src/${source_set}/java"
    local old_dir="${base_dir}/${OLD_PACKAGE_PATH}"
    local new_dir="${base_dir}/${NEW_PACKAGE_PATH}"

    if [[ ! -d "$old_dir" ]]; then
        warn "Directory not found: ${old_dir} — skipping"
        return
    fi

    # Create new directory structure
    mkdir -p "$new_dir"

    # Move all contents from old to new
    # Using find to handle both files and subdirectories
    for item in "$old_dir"/*; do
        if [[ -e "$item" ]]; then
            mv "$item" "$new_dir/"
        fi
    done

    # Remove old empty directory tree (walk up from deepest)
    # Remove the old package directories if they're empty
    local old_seg1 old_seg2 old_seg3
    old_seg1=$(echo "$OLD_PACKAGE" | cut -d. -f1)
    old_seg2=$(echo "$OLD_PACKAGE" | cut -d. -f2)
    old_seg3=$(echo "$OLD_PACKAGE" | cut -d. -f3)

    rmdir "${base_dir}/${old_seg1}/${old_seg2}/${old_seg3}" 2>/dev/null || true
    rmdir "${base_dir}/${old_seg1}/${old_seg2}" 2>/dev/null || true
    rmdir "${base_dir}/${old_seg1}" 2>/dev/null || true

    info "Renamed: app/src/${source_set}/java/${OLD_PACKAGE_PATH} → ${NEW_PACKAGE_PATH}"
}

rename_package_dir "main"
rename_package_dir "test"
rename_package_dir "androidTest"

# --- Step 4: Rename Application class file -----------------------------------
header "Step 4: Renaming Application class file"

OLD_APP_FILE="${SCRIPT_DIR}/app/src/main/java/${NEW_PACKAGE_PATH}/${OLD_APP_CLASS}.kt"
NEW_APP_FILE="${SCRIPT_DIR}/app/src/main/java/${NEW_PACKAGE_PATH}/${NEW_APP_CLASS}.kt"

if [[ -f "$OLD_APP_FILE" ]]; then
    mv "$OLD_APP_FILE" "$NEW_APP_FILE"
    info "Renamed: ${OLD_APP_CLASS}.kt → ${NEW_APP_CLASS}.kt"
elif [[ -f "$NEW_APP_FILE" ]]; then
    info "${NEW_APP_CLASS}.kt already exists — skipping rename"
else
    warn "${OLD_APP_CLASS}.kt not found at expected location — skipping"
fi

# --- Step 5: Update settings.gradle.kts rootProject name --------------------
header "Step 5: Verifying settings.gradle.kts"

SETTINGS_FILE="${SCRIPT_DIR}/settings.gradle.kts"
if grep -q "rootProject.name" "$SETTINGS_FILE"; then
    # This was already handled by the replace_in_files step, but verify
    if grep -q "rootProject.name = \"${APP_NAME}\"" "$SETTINGS_FILE"; then
        info "rootProject.name is set to '${APP_NAME}'"
    else
        sed -i '' "s|rootProject.name = .*|rootProject.name = \"${APP_NAME}\"|" "$SETTINGS_FILE"
        info "Updated rootProject.name to '${APP_NAME}'"
    fi
else
    warn "rootProject.name not found in settings.gradle.kts"
fi

# --- Step 6: Delete google-services.json ------------------------------------
header "Step 6: Cleaning up Firebase config"

GOOGLE_SERVICES="${SCRIPT_DIR}/app/google-services.json"
if [[ -f "$GOOGLE_SERVICES" ]]; then
    rm "$GOOGLE_SERVICES"
    info "Deleted google-services.json"
else
    info "google-services.json already removed"
fi
warn "You must add a new google-services.json from your Firebase console"

# --- Step 7: Reinitialize git ------------------------------------------------
header "Step 7: Reinitializing git history"

if [[ -d "${SCRIPT_DIR}/.git" ]]; then
    rm -rf "${SCRIPT_DIR}/.git"
    info "Removed old .git directory"
fi

(
    cd "$SCRIPT_DIR"
    git init -q
    git add .
    git commit -q -m "chore: initial project setup"
)
info "Initialized fresh git repository with initial commit"

# --- Done: Print summary checklist -------------------------------------------
header "Bootstrap complete!"

printf "${GREEN}${BOLD}Project '${APP_NAME}' is ready.${NC}\n\n"

echo "Manual steps remaining:"
echo
printf "  ${YELLOW}□${NC} Add ${BOLD}google-services.json${NC} from Firebase console to app/\n"
printf "  ${YELLOW}□${NC} Create GitHub repository secrets:\n"
printf "      • ${BOLD}FIREBASE_APP_ID${NC}\n"
printf "      • ${BOLD}FIREBASE_SERVICE_ACCOUNT_JSON${NC}\n"
printf "      • ${BOLD}NVD_API_KEY${NC}\n"
printf "  ${YELLOW}□${NC} Run ${BOLD}./scripts/install-hooks.sh${NC} to set up pre-commit hooks\n"
printf "  ${YELLOW}□${NC} Create a ${BOLD}designers${NC} tester group in Firebase App Distribution\n"
printf "  ${YELLOW}□${NC} Update app icons and splash screen for your brand\n"
echo
printf "${GREEN}Happy coding!${NC}\n"
