#!/usr/bin/env bash
# =============================================================================
# populate_mission_file.sh
# Copies the vanilla EU5 mission file into this mod and applies the
# one-line rank_index fix for "Establish a Trade".
#
# Run this on any machine where EU5 is installed, then commit the result.
# The script is idempotent: safe to re-run after a game patch.
#
# Usage:
#   ./populate_mission_file.sh [EU5_GAME_DIR]
#
# If EU5_GAME_DIR is not given, the script tries common Steam install paths.
# =============================================================================
set -euo pipefail

VANILLA_REL="game/in_game/common/missions/generic_capital_economy_mission_pack.txt"
MOD_REL="in_game/common/missions/generic_capital_economy_mission_pack.txt"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_FILE="$SCRIPT_DIR/$MOD_REL"

# --- Locate EU5 game directory -------------------------------------------------
find_eu5() {
    # macOS (Steam default)
    MAC="$HOME/Library/Application Support/Steam/steamapps/common/Europa Universalis V"
    # Linux (Steam default)
    LIN="$HOME/.steam/steam/steamapps/common/Europa Universalis V"
    LIN2="$HOME/.local/share/Steam/steamapps/common/Europa Universalis V"
    # Windows WSL common paths
    WIN1="/mnt/c/Program Files (x86)/Steam/steamapps/common/Europa Universalis V"
    WIN2="/mnt/c/Program Files/Steam/steamapps/common/Europa Universalis V"
    for d in "$MAC" "$LIN" "$LIN2" "$WIN1" "$WIN2"; do
        if [ -d "$d" ]; then echo "$d"; return 0; fi
    done
    return 1
}

if [ $# -ge 1 ]; then
    EU5_DIR="$1"
else
    EU5_DIR="$(find_eu5)" || {
        echo ""
        echo "ERROR: Could not auto-detect EU5 installation."
        echo "  Please pass the EU5 game directory as argument:"
        echo "  ./populate_mission_file.sh /path/to/Europa Universalis V"
        echo ""
        echo "Typical paths:"
        echo "  macOS: ~/Library/Application Support/Steam/steamapps/common/Europa Universalis V"
        echo "  Linux: ~/.steam/steam/steamapps/common/Europa Universalis V"
        echo "  Win:   C:\\Program Files (x86)\\Steam\\steamapps\\common\\Europa Universalis V"
        exit 1
    }
fi

VANILLA_FILE="$EU5_DIR/$VANILLA_REL"

if [ ! -f "$VANILLA_FILE" ]; then
    echo "ERROR: Vanilla file not found at:"
    echo "  $VANILLA_FILE"
    echo "Make sure EU5 is installed and the path is correct."
    exit 1
fi

echo "Found vanilla file at: $VANILLA_FILE"

# --- Copy to mod directory ----------------------------------------------------
mkdir -p "$(dirname "$MOD_FILE")"
cp "$VANILLA_FILE" "$MOD_FILE"
echo "Copied vanilla file -> $MOD_FILE"

# --- Apply the fix -------------------------------------------------------------
# Bug (still present in 1.2.5). VERIFIED rank_index numbering from vanilla game files:
#   0=Megalopolis, 1=City, 2=Town, 3=Rural Settlement
#   (proof: western_schism.txt "town (rank index 2) or a city (rank index 1)";
#    gui/filters/05_location.txt  location_is_urban = { rank_index < 3 })
#   File: generic_capital_economy_mission_pack.txt, lines ~195 and ~285
#   Wrong: rank_index <= 1  (matches Megalopolis=0 + City=1; WRONGLY rejects Town=2)
#   Fixed: rank_index <= 2  (matches Megalopolis=0 + City=1 + Town=2; excludes Rural=3)
#
# "Urban Location" = rank_index <= 2 == the game's own location_is_urban (rank_index < 3).
# NOTE: an earlier attempt used >= 1 based on an INVERTED rank table — that let Rural
# Settlements through and blocked Megalopolis. Do not revert to >= 1.

sed -i.bak 's/rank_index\s*<=\s*1/rank_index <= 2/g' "$MOD_FILE"
echo "Applied rank_index fix (rank_index <= 1  ->  rank_index <= 2)."

# Remove sed backup
rm -f "$MOD_FILE.bak"

# --- Verify -------------------------------------------------------------------
if grep -n "rank_index <= 2" "$MOD_FILE" | head -5; then
    echo ""
    echo "SUCCESS: Fix applied. Verify line numbers above match ~195 in the vanilla file."
    echo ""
    echo "Next steps:"
    echo "  1. Review the change: git diff in_game/"
    echo "  2. Commit: git add in_game/ && git commit -m 'chore: populate mission file from vanilla 1.2.5 + apply rank_index fix'"
    echo "  3. Push:   git push -u origin claude/upbeat-johnson-BzSEU"
    echo "  4. Publish via SteamCMD using eu5_bugfix_item.vdf"
else
    echo ""
    echo "WARNING: Could not verify fix. The condition 'rank_index <= 1' may use"
    echo "different whitespace. Please check line ~195 of:"
    echo "  $MOD_FILE"
    echo "and change '<=' to '>=' manually."
    exit 1
fi
