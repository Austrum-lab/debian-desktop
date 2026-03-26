#!/bin/bash
# repo-sync.sh - Sync config files between repo and system
# Usage: ./repo-sync.sh [--merge|--merge repo|--include-new|--show-config|--help]
# Blacklist/whitelist respected, new files need --include-new, backups in /tmp/repo-sync/

set -euo pipefail
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
CYAN='\033[0;36m' MAGENTA='\033[0;35m' BOLD='\033[1m' NC='\033[0m'
BACKUP_DIR="/tmp/repo-sync"
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============== CONFIG ==============
declare -A DIR_MAPPINGS=(
    ["etc/default"]="/etc/default"
    ["etc/sysctl.d"]="/etc/sysctl.d"
    ["etc/modprobe.d"]="/etc/modprobe.d"
    ["etc/apt"]="/etc/apt"
    ["etc/environment.d"]="/etc/environment.d"
    ["etc/modules-load.d"]="/etc/modules-load.d"
    [".config/MangoHud"]="$HOME/.config/MangoHud"
    [".config/pipewire"]="$HOME/.config/pipewire"
    [".config/autostart"]="$HOME/.config/autostart"
)
declare -A FILE_MAPPINGS=(
    ["etc/fstab"]="/etc/fstab"
    [".bashrc"]="$HOME/.bashrc"
)

# Blacklist: ["dir"]="*" for all, ["dir"]="file1 file2" for specific
declare -A BLACKLIST=(
    ["etc/apt/sources.list.d"]="*"
    ["etc/apt/trusted.gpg.d"]="*"
    ["etc/modprobe.d"]="amd64-microcode-blacklist.conf dkms.conf supergfxd.conf"
    ["etc/sysctl.d"]="99-ipforward.conf README.sysctl 50-cursor.conf"
)
# Whitelist: only these files synced per directory (empty = all allowed)
declare -A WHITELIST=(
    ["etc/default"]="grub zramswap"
    ["etc/apt"]="sources.list unstable"
    [".config/autostart"]="slack.desktop rog-control-center.desktop"
)
declare -a IGNORE_PATTERNS=("*.swp" "*.bak" "*~" "*.orig" "*.rej")
INCLUDE_NEW=false MERGE_SOURCE="local"

# ============== HELPERS ==============
is_blacklisted() {
    local file="$1" bn dir; bn=$(basename "$file"); dir=$(dirname "$file")
    for bdir in "${!BLACKLIST[@]}"; do
        [[ "$dir" == "$bdir" || "$dir" == "$bdir/"* ]] || continue
        [[ "${BLACKLIST[$bdir]}" == "*" ]] && return 0
        for bf in ${BLACKLIST[$bdir]}; do [[ "$bn" == "$bf" ]] && return 0; done
    done
    return 1
}
is_ignored() {
    local bn; bn=$(basename "$1")
    for p in "${IGNORE_PATTERNS[@]}"; do [[ "$bn" == $p ]] && return 0; done
    return 1
}
is_whitelisted() {
    local file="$1" bn dir; bn=$(basename "$file"); dir=$(dirname "$file")
    [[ ${#WHITELIST[@]} -eq 0 ]] && return 0
    for wd in "${!WHITELIST[@]}"; do
        [[ "$dir" == "$wd" || "$dir" == "$wd/"* ]] || continue
        for wf in ${WHITELIST[$wd]}; do [[ "$bn" == "$wf" ]] && return 0; done
        return 1
    done
    return 0
}
get_category() {
    case "$1" in
        etc/default/*) echo "grub";; etc/sysctl.d/*) echo "sysctl";;
        etc/modprobe.d/*) echo "modprobe";; etc/apt/*) echo "apt";;
        etc/environment.d/*) echo "environment";; etc/modules-load.d/*) echo "modules";;
        etc/fstab) echo "fstab";; .config/MangoHud/*) echo "mangohud";;
        .config/pipewire/*) echo "pipewire";; .config/autostart/*) echo "autostart";;
        .bashrc) echo "shell";; *) echo "other";;
    esac
}
get_system_path() {
    local f="$1"
    [[ -v FILE_MAPPINGS["$f"] ]] && { echo "${FILE_MAPPINGS[$f]}"; return; }
    for d in "${!DIR_MAPPINGS[@]}"; do
        [[ "$f" == "$d/"* ]] && { echo "${DIR_MAPPINGS[$d]}/${f#$d/}"; return; }
    done
}
compare_files() {
    local rf="$1" sf="$2"
    [[ ! -f "$rf" && ! -f "$sf" ]] && echo "both-missing" && return
    [[ ! -f "$rf" ]] && echo "system-only" && return
    [[ ! -f "$sf" ]] && echo "repo-only" && return
    diff -q "$rf" "$sf" >/dev/null 2>&1 && echo "identical" || echo "different"
}
get_files() {
    local src="$1" files=()
    for rd in "${!DIR_MAPPINGS[@]}"; do
        local sd; [[ "$src" == "repo" ]] && sd="$rd" || sd="${DIR_MAPPINGS[$rd]}"
        [[ -d "$sd" ]] || continue
        while IFS= read -r -d '' file; do
            [[ "$src" == "repo" ]] && file="${file#./}" || file="$rd/${file#$sd/}"
            is_whitelisted "$file" || continue
            is_blacklisted "$file" && continue
            is_ignored "$file" && continue
            files+=("$file")
        done < <(find "$sd" -type f -print0 2>/dev/null)
    done
    for f in "${!FILE_MAPPINGS[@]}"; do
        [[ "$src" == "repo" ]] && { [[ -f "$f" ]] || continue; } || { [[ -f "${FILE_MAPPINGS[$f]}" ]] || continue; }
        is_whitelisted "$f" || continue
        is_blacklisted "$f" && continue
        is_ignored "$f" && continue
        files+=("$f")
    done
    printf '%s\n' "${files[@]}" | sort -u
}

# ============== DISPLAY ==============
show_diff_summary() {
    local rf="$1" sf="$2" adds=0 dels=0 lines=() i=0
    [[ -f "$rf" && -f "$sf" ]] || return 0
    while IFS= read -r line; do
        [[ "$line" =~ ^\+[^+] ]] && { adds=$((adds+1)); lines+=("${GREEN}+${NC} ${line:1}"); }
        [[ "$line" =~ ^-[^-] ]] && { dels=$((dels+1)); lines+=("${RED}-${NC} ${line:1}"); }
    done < <(diff -u "$rf" "$sf" 2>/dev/null || true)
    echo -e "      ${GREEN}+$adds${NC} ${RED}-$dels${NC}"
    for line in "${lines[@]}"; do
        echo -e "      $line"; i=$((i+1))
        [[ $i -ge 10 ]] && { [[ ${#lines[@]} -gt 10 ]] && echo -e "      ${CYAN}... and $((${#lines[@]}-10)) more${NC}"; break; }
    done
}
print_header() { echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}\n${CYAN}║     $1${NC}\n${CYAN}╚════════════════════════════════════════════════════╝${NC}"; }
print_box() { echo -e "${1}╭────────────────────────────────────────────────────╮${NC}\n${1}│  $2${NC}\n${1}╰────────────────────────────────────────────────────╯${NC}"; }

show_config() {
    print_header "Configuration"
    echo -e "\n${BOLD}Mappings:${NC}"
    for d in "${!DIR_MAPPINGS[@]}"; do echo "  $d → ${DIR_MAPPINGS[$d]}"; done
    for f in "${!FILE_MAPPINGS[@]}"; do echo "  $f → ${FILE_MAPPINGS[$f]}"; done
    echo -e "\n${BOLD}Blacklist:${NC}"
    for d in "${!BLACKLIST[@]}"; do echo "  $d: ${BLACKLIST[$d]}"; done
    echo -e "\n${BOLD}Whitelist:${NC}"
    [[ ${#WHITELIST[@]} -eq 0 ]] && echo "  (none)" || { for d in "${!WHITELIST[@]}"; do echo "  $d: ${WHITELIST[$d]}"; done; }
}

show_status() {
    print_header "System ↔ Repo Sync"
    declare -A seen=()
    local -a ok=() diff=() warn=() new=()
    local id=0 df=0 ro=0 so=0

    while IFS= read -r f; do [[ -n "$f" ]] && { [[ ! -v seen["$f"] ]] && seen["$f"]=1; }; done < <(get_files "repo"; get_files "system")

    for rf in "${!seen[@]}"; do
        local sf st cat; sf=$(get_system_path "$rf"); [[ -z "$sf" ]] && continue
        st=$(compare_files "$rf" "$sf"); cat=$(get_category "$rf")
        case "$st" in
            identical) id=$((id+1)); ok+=("$rf|$cat");;
            different) df=$((df+1)); diff+=("$rf|$cat|$sf");;
            repo-only) [[ "$INCLUDE_NEW" == true ]] && { ro=$((ro+1)); warn+=("$rf|$cat|repo-only|$sf"); } || new+=("$rf|$cat");;
            system-only) so=$((so+1)); warn+=("$rf|$cat|system-only|$sf");;
        esac
    done

    [[ ${#ok[@]} -gt 0 ]] && { print_box "$GREEN" "✓ SYNCED"
        for i in "${ok[@]}"; do IFS='|' read -r f c <<< "$i"; echo -e "  ✓ $f ${CYAN}[$c]${NC}"; done; echo ""; }
    [[ ${#diff[@]} -gt 0 ]] && { print_box "$YELLOW" "⚠ DIFFERENT"
        for i in "${diff[@]}"; do IFS='|' read -r f c s <<< "$i"
            echo -e "  ✗ $f\n      ${BLUE}System:${NC} $s"; show_diff_summary "$f" "$s" || true; echo ""; done; echo ""; }
    [[ "$INCLUDE_NEW" == true && ${#warn[@]} -gt 0 ]] && { print_box "$MAGENTA" "New files"
        for i in "${warn[@]}"; do IFS='|' read -r f c cond s <<< "$i"
            [[ "$cond" == "system-only" ]] && echo -e "  ← $f (system → repo)" || echo -e "  → $f (repo → system)"; done; echo ""; }
    [[ "$INCLUDE_NEW" == false && ${#warn[@]} -gt 0 ]] && { print_box "$BLUE" "Skipped (use --include-new)"
        echo -e "  ${GREEN}$so local${NC} files (system → repo)"; echo -e "  ${YELLOW}${#new[@]} new${NC} files (repo → system)"; echo ""; }

    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC}  ${GREEN}✓ Synced:${NC} %-6d ${YELLOW}✗ Different:${NC} %-6d${NC}\n" "$id" "$df"
    printf "${CYAN}║${NC}  ${GREEN}← Local:${NC} %-7d ${CYAN}○ New:${NC} %-6d${NC}\n" "$so" "${#new[@]}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"

    local t=$((df+so)); [[ "$INCLUDE_NEW" == true ]] && t=$((t+ro))
    if [[ $t -gt 0 ]]; then
        echo -e "  ${GREEN}./repo-sync.sh --merge${NC} — merge (local preferred)"
        echo -e "  ${GREEN}./repo-sync.sh --merge repo${NC} — merge (repo preferred)"
        [[ "$INCLUDE_NEW" == false ]] && echo -e "  ${GREEN}./repo-sync.sh --include-new${NC} — include new files"
    else
        echo -e "  ${GREEN}All synchronized! ✓${NC}"
    fi
}

backup_file() {
    local f="$1" loc="$2"; [[ -f "$f" ]] || return
    mkdir -p "$BACKUP_DIR/$loc"
    local bn ts; bn=$(basename "$f"); ts=$(date +%Y%m%d_%H%M%S)
    cp "$f" "$BACKUP_DIR/$loc/${ts}_${bn}"
    echo -e "      ${CYAN}Backup:${NC} $BACKUP_DIR/$loc/${ts}_${bn}"
}

auto_merge() {
    local source="$1"
    print_header "Auto Merge"
    [[ "$source" == "local" ]] && { echo -e "\n${GREEN}Mode: LOCAL (system → repo)${NC}\n${CYAN}Backup: /tmp/repo-sync/REPO/${NC}"; } || { echo -e "\n${YELLOW}Mode: REPO (repo → system)${NC}\n${CYAN}Backup: /tmp/repo-sync/LOCAL/${NC}"; }
    echo -e "${CYAN}Include new: ${NC}$([[ "$INCLUDE_NEW" == true ]] && echo YES || echo NO)\n"

    declare -A seen=()
    local -a changes=()
    while IFS= read -r f; do [[ -n "$f" ]] && { [[ ! -v seen["$f"] ]] && seen["$f"]=1; }; done < <(get_files "repo"; get_files "system")

    for rf in "${!seen[@]}"; do
        local sf st; sf=$(get_system_path "$rf"); [[ -z "$sf" ]] && continue
        st=$(compare_files "$rf" "$sf")
        [[ "$st" == "identical" ]] && continue
        # Skip new files without --include-new
        [[ "$st" == "repo-only" || "$st" == "system-only" ]] && [[ "$INCLUDE_NEW" == false ]] && continue
        changes+=("$rf|$sf|$st")
    done

    [[ ${#changes[@]} -eq 0 ]] && { echo -e "${GREEN}✓ All synchronized!${NC}"; return; }
    echo -e "${BOLD}Files to change (${#changes[@]}):\n"
    for i in "${changes[@]}"; do
        IFS='|' read -r rf sf st <<< "$i"
        case "$st" in
            different) [[ "$source" == "local" ]] && echo -e "  ← $sf → $rf" || echo -e "  → $rf → $sf";;
            repo-only) echo -e "  → $rf → $sf (new)";;
            system-only) echo -e "  ← $sf → $rf (missing)";;
        esac
    done
    echo ""
    read -p "Proceed? (y/N): " c; [[ "$c" != "y" && "$c" != "Y" ]] && { echo -e "${RED}Aborted.${NC}"; return; }
    echo ""

    local applied=0
    for i in "${changes[@]}"; do
        IFS='|' read -r rf sf st <<< "$i"
        case "$st" in
            different) [[ "$source" == "local" ]] && { backup_file "$rf" "REPO"; cp "$sf" "$rf"; } || { backup_file "$sf" "LOCAL"; sudo cp "$rf" "$sf"; };;
            repo-only) [[ "$INCLUDE_NEW" == true ]] && { sudo mkdir -p "$(dirname "$sf")"; sudo cp "$rf" "$sf"; };;
            system-only) mkdir -p "$(dirname "$rf")"; cp "$sf" "$rf";;
        esac
        echo -e "  ${GREEN}✓${NC} ${sf} → ${rf}"; applied=$((applied+1))
    done
    echo -e "\n${CYAN}════════════════════════════════════════════════════${NC}\n${GREEN}Complete! Applied: $applied${NC}"
}

show_help() { cat << 'EOF'
Usage: repo-sync.sh [COMMAND] [OPTIONS]

Commands:
  (none)              Show status
  --status, -s        Show synchronization status
  --merge, -m         Auto merge (local preferred, asks for confirmation)
  --merge local       Auto merge using local files as base
  --merge repo        Auto merge using repo files as base
  --show-config, -c   Show configuration
  --help, -h          Show this help

Options:
  --include-new       Include new files in merge

Examples:
  ./repo-sync.sh                    # Show status
  ./repo-sync.sh --merge            # Merge (local → repo, asks first)
  ./repo-sync.sh --merge repo       # Merge (repo → system)
  ./repo-sync.sh --merge --include-new  # Merge including new files
  ./repo-sync.sh --show-config      # Show mappings

Notes:
  - Blacklist/whitelist ALWAYS respected
  - New files need --include-new
  - Backups: /tmp/repo-sync/[LOCAL|REPO]/
EOF
}
error_exit() { echo -e "${RED}Error: $1${NC}" >&2; echo -e "${YELLOW}Run './repo-sync.sh --help'${NC}" >&2; exit 1; }

# ============== MAIN ==============
main() {
[[ $# -eq 0 ]] && { show_status; exit 0; }
COMMAND=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --status|-s) COMMAND="status"; shift;;
        --merge|-m) COMMAND="merge"; shift;;
        --show-config|-c) COMMAND="config"; shift;;
        --help|-h) show_help; exit 0;;
        --include-new) INCLUDE_NEW=true; shift;;
        local) MERGE_SOURCE="local"; shift;;
        repo) MERGE_SOURCE="repo"; shift;;
        -*) error_exit "Unknown option: $1";;
        *) error_exit "Unknown argument: $1";;
    esac
done
[[ -z "$COMMAND" ]] && COMMAND="status"
case "$COMMAND" in
    status) show_status;;
    merge) auto_merge "$MERGE_SOURCE";;
    config) show_config;;
    *) error_exit "Unknown command: $COMMAND";;
esac
}
main "$@"
