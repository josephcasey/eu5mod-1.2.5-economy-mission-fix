# EU5 1.2.5 – "Establish a Trade" Rank-Index Bugfix: Research Notes

> **CORRECTION (2026-06-10, verified against vanilla game files).** An earlier version of
> these notes had the rank_index numbering INVERTED (`0=Rural…3=Megalopolis`) and so
> prescribed the wrong fix (`<= 1` → `>= 1`). That wrong fix actually let Rural Settlements
> through and blocked Megalopolis — confirmed in-game when a Rural location (Stranrawer) was
> selectable for the "Urban Location" task. The VERIFIED numbering is the opposite:
> **`0=Megalopolis, 1=City, 2=Town, 3=Rural Settlement`** (proof in §2). The correct fix is
> **`rank_index <= 1` → `rank_index <= 2`** at BOTH ~line 195 (`mission_setup_trade`
> `select_trigger.visible`) and ~line 285 (`mission_prepare_industry_focus` `enabled`).
> "Urban" = `rank_index <= 2` ≡ the game's own `location_is_urban = { rank_index < 3 }`.

## TL;DR for rebuilding after a patch

Run `./populate_mission_file.sh` on any machine with EU5 installed.
It copies the vanilla `generic_capital_economy_mission_pack.txt` and applies:
```
rank_index <= 1   →   rank_index <= 2
```
at lines ~195 and ~285 (the `mission_setup_trade` `select_trigger.visible` block and the
`mission_prepare_industry_focus` `enabled` block). "Urban" = `rank_index <= 2`.
Commit the result and re-publish via SteamCMD with the same Workshop ID.

---

## 1. Bug identification

### Confirmed facts (multiple independent sources, cross-verified)

| Item | Value | Source |
|------|-------|--------|
| File | `game/in_game/common/missions/generic_capital_economy_mission_pack.txt` | Paradox developer forum post |
| Line | ~195 | Paradox developer forum post |
| Wrong condition | `rank_index <= 1` (matches Megalopolis=0, City=1; rejects Town=2) | Verified from game files |
| Correct condition | `rank_index <= 2` (adds Town=2; still excludes Rural=3) | Verified from game files (2026-06-10) |
| Block context | `mission_setup_trade` `select_trigger.visible` (~L195) + `mission_prepare_industry_focus` `enabled` (~L285) | File inspection |
| Patch status | Still present in 1.2.5 (cf2f) | Checked 1.2.X wiki patch notes |

### Forum threads (Cloudflare-protected, not directly scrapeable)
- **Main report (confirmed):** https://forum.paradoxplaza.com/forum/threads/develop-a-capital-economy-mission-task-establish-a-trade-requires-a-rural-location-instead-of-town-or-city.1920958/
- **Rank-index details:** https://forum.paradoxplaza.com/forum/threads/location-rank-index-less-than-1.1920949/post-31275011

Developer quote (reconstructed from multiple search result snippets — **NOTE: the `>= 1`
here is WRONG; see the CORRECTION banner. The real fix is `<= 2`. Kept only as a record of
what the web search reconstructed**):
> "a content developer typed `rank_index <= 1` when they meant to type `rank_index >= 1`. This means you're meant to find a location with a town or city, but instead it requires that there be no town nor city."

---

## 2. Rank index values

Confirmed from vanilla 1.2.5 game files (this CORRECTS the earlier inverted guess):
- `events/situations/western_schism.txt`: dev comment "the location is a town (rank index 2)
  or a city (rank index 1)" — pins Town=2, City=1.
- `gui/filters/05_location.txt`: `location_is_urban = { rank_index < 3 }` and
  `location_is_not_urban = { rank_index > 2 }` — pins Rural=3, urban = 0..2.
- `common/location_ranks/00_default.txt` definition order (megalopolis, city, town,
  rural_settlement) — rank_index follows this order, 0..3.

| rank_index | Location type |
|-----------|--------------|
| 0 | Megalopolis (highest) |
| 1 | City |
| 2 | Town |
| 3 | Rural Settlement (lowest) |

With `rank_index <= 1`: Megalopolis (0 ✓) + City (1 ✓) pass; Town (2 ✗) + Rural (3 ✗) fail
  → the bug (Towns wrongly rejected).
With `rank_index <= 2`: Megalopolis (0 ✓) + City (1 ✓) + Town (2 ✓) pass; Rural (3 ✗) fails
  → correct "urban only" (matches the game's own `location_is_urban`).

---

## 3. The second gate ("Invalid Target")

The player also reported a second failing gate ("Invalid Target") alongside "Requirements not met".

Hypothesis (not confirmed without vanilla file):
- The `select_trigger` block scopes location selection to the **mission market** chosen at mission start
- "Invalid Target" may appear when hovering locations outside that market scope, or locations already occupied by another trade
- This is likely a SEPARATE condition in the `enabled` block or in the `visible` block of the `select_trigger`

**What this means for the fix:** Fixing rank_index is the developer-confirmed primary bug. If rural locations *in the market scope* still fail after the fix, there is a second broken condition. This needs live testing; the fix iteration path is:
1. Publish this mod
2. Test on GFN with a Town-rank location in the capital market
3. If Towns now work but Cities don't → mod is missing something (rank system different from assumed)
4. If all locations still fail → there IS a second broken gate; open the file and inspect

---

## 4. EU5 modding structure

### metadata.json (confirmed from Europa-Universalis-5-Modding-Co-op/community-mod-framework)
```json
{
    "name": "...",
    "id": "unique_string_id",
    "version": "1.0",
    "game_id": "eu5",
    "supported_game_version": "1.2.*",
    "short_description": "...",
    "tags": ["Fixes"],
    "relationships": [],
    "game_custom_data": {}
}
```

### Directory structure
```
<mod-root>/
  .metadata/
    metadata.json
    thumbnail.png        ← used as launcher icon + Workshop preview
  in_game/
    common/
      missions/
        generic_capital_economy_mission_pack.txt   ← vanilla file + fix applied
  eu5_bugfix_item.vdf   ← SteamCMD publish manifest
  populate_mission_file.sh
```

### Override mechanism
EU5 uses WHOLE-FILE override: a mod file with the same path as a vanilla file
completely replaces it. There is a `REPLACE:key` / `TRY_REPLACE:key` database-entry
mechanism, but whether it applies to individual mission TASKS is documented as
"Unknown" in the EU5 wiki action modding page. The safe approach is the whole-file
override, requiring the complete vanilla content.

---

## 5. Why the vanilla file is not included here

The vanilla `generic_capital_economy_mission_pack.txt` is copyrighted Paradox Interactive
content. No public dump, GitHub mirror, or CDN-accessible copy was found during research.
SteamCMD requires game ownership (anonymous access denied for EU5).

Run `./populate_mission_file.sh` to extract and patch it from a licensed EU5 installation.

---

## 6. Workshop publishing workflow

### Prerequisites
- SteamCMD installed (macOS: `brew install steamcmd`)
- Steam account with EU5 in library (owns game = can publish mods)
- Mod folder populated (run `./populate_mission_file.sh`)
- Edit `eu5_bugfix_item.vdf`: replace both `__REPLACE_WITH_ABSOLUTE_PATH__` placeholders

### First publish (creates the Workshop item)
```bash
steamcmd +login <your_steam_username> \
         +workshop_build_item /abs/path/to/eu5_bugfix_item.vdf \
         +quit
```
SteamCMD will print the new `publishedfileid`. Update `eu5_bugfix_item.vdf`
with that ID (replacing `"0"`). Also consider writing it to `game_custom_data`
in `metadata.json` so Paradox Launcher associates the download with the mod.

### Subsequent updates (same Workshop item)
Set `"publishedfileid"` in the VDF to the existing ID and re-run. Change
`"changenote"` each time.

### Alternative: pdx-workshop-manager
Go-based tool that handles the id write-back automatically.
Config: `{"game": 3450310, "mods": [{"id": 0, "directory": "...", ...}]}`
See: https://eu5.paradoxwikis.com/PDX_Workshop_Manager

---

## 7. Existing-fix status (as of 2026-06-06)

- Steam Workshop search: **no dedicated fix mod found**
- Paradox Mods: **no fix found**
- Skymods catalogue: **not checked individually**
- Taj's EU5 Vanilla++ (id=3617720785): does not list this fix; description is vague
- Patch 1.2.X (up to 1.2.5): **mission file not touched** (confirmed from wiki)

---

## 8. Parallel escalation track

Post a "still present in 1.2.5" follow-up on the confirmed bug thread:
https://forum.paradoxplaza.com/forum/threads/develop-a-capital-economy-mission-task-establish-a-trade-requires-a-rural-location-instead-of-town-or-city.1920958/

Key points to include:
- Version 1.2.5 (checksum cf2f), dated 2026-05-20
- Both City-rank and Rural-rank locations are unselectable (two failing gates)
- Tooltip on City-rank location: "Location Rank Index of 'Location' is less or equal to 1" (X)
- A vanilla patch is the cleanest fix for GFN players
