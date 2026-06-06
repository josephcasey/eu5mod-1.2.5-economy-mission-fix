# HANDOVER — local Claude Code session

**Branch:** `claude/upbeat-johnson-BzSEU`
**Last updated:** 2026-06-06 (web session → local session handover)
**Repo:** `josephcasey/eu5mod-1.2.5-economy-mission-fix`

---

## What this project is

A minimal EU5 (Europa Universalis V) 1.2.5 Steam Workshop mod that fixes ONE
confirmed bug: the **Develop a Capital Economy → Establish a Trade** mission task
rejects Town/City locations because of a backwards operator.

```
generic_capital_economy_mission_pack.txt  line ~195
WRONG:  rank_index <= 1     (accepts Rural=0, Town=1; rejects City=2, Megalopolis=3)
RIGHT:  rank_index >= 1     (accepts Town=1, City=2, Megalopolis=3; rejects Rural=0)
```

Rank index values (confirmed): `0=Rural, 1=Town, 2=City, 3=Megalopolis`.
Bug is developer-confirmed and still present in 1.2.5. Full research in `NOTES.md`.

**Player context (important constraints):**
- Plays EU5 ONLY on GeForce NOW (cloud). No local Windows machine.
- EU5 is **Windows-only** — no native Mac/Linux build (verified; Paradox broke
  from tradition this time).
- macOS machine (Josephs-MacBook-Air) is used for SteamCMD publishing —
  proven workflow from shipping Civ 7 Workshop items.
- No `-debug_mode`, no local test harness. Testing is black-box on GFN after publish.

---

## What is DONE (committed, pushed)

Commit `6ac5cec` on branch `claude/upbeat-johnson-BzSEU`:

```
.metadata/metadata.json          ← EU5 Jomini descriptor, format verified against
                                   community-mod-framework. id=bugfix_establish_trade_rank_index
.metadata/thumbnail.png          ← 256×256 Workshop preview (placeholder art)
eu5_bugfix_item.vdf              ← SteamCMD workshop_build_item manifest.
                                   Has TWO __REPLACE_WITH_ABSOLUTE_PATH__ placeholders.
                                   visibility=2 (private) for first test publish.
populate_mission_file.sh         ← copies vanilla mission file + applies sed fix.
                                   Auto-detects install paths; accepts a path arg.
NOTES.md                         ← complete research log, sources, publish workflow.
.gitignore
in_game/common/missions/         ← directory exists, mission file NOT yet present.
```

---

## What is NOT done — the blocking gap

The vanilla `generic_capital_economy_mission_pack.txt` is Paradox copyright and is
NOT publicly available anywhere (checked: GitHub, SteamDB file browser, community
dumps, all mod repos). It must be obtained from a licensed EU5 download.

**The web session could not do this** — SteamCMD needs network sockets that the
cloud sandbox blocks (`CreateBoundSocket: failed EAFNOSUPPORT`). That's why this
is being handed to a LOCAL session on the player's Mac.

---

## YOUR JOB, local session — step by step

### Step 0 — Confirm state
```bash
git branch --show-current      # must be: claude/upbeat-johnson-BzSEU
git log --oneline              # should show 6ac5cec
```
If not on the branch: `git checkout claude/upbeat-johnson-BzSEU`

### Step 1 — Download EU5 Windows files via SteamCMD on the Mac
SteamCMD was already installed at `~/steamcmd` and is running. The cross-platform
trick (download Windows depot on macOS) is verified to work:

```bash
~/steamcmd/steamcmd.sh \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$HOME/eu5-files" \
  +login <STEAM_USERNAME> \
  +app_update 3450310 validate \
  +quit
```
- Will prompt for password + Steam Guard code (email / mobile app).
- Use the ABSOLUTE path `$HOME/eu5-files` — SteamCMD mishandles `~`.
- ~8 GB download. The account owns EU5, so this is authorized.
- App ID 3450310 = Europa Universalis V.

Target file lands at:
```
$HOME/eu5-files/game/in_game/common/missions/generic_capital_economy_mission_pack.txt
```

### Step 2 — Populate + patch the mod file
```bash
cd /path/to/eu5mod-1.2.5-economy-mission-fix
./populate_mission_file.sh "$HOME/eu5-files"
```
This copies the vanilla file into `in_game/common/missions/` and runs
`sed 's/rank_index <= 1/rank_index >= 1/g'`. It prints the fixed line numbers
for verification — confirm they land around line 195 inside the
`establish_a_trade` task's `select_trigger.enabled` block.

### Step 3 — VERIFY the fix carefully (do not skip)
Open the now-populated file and check:
1. The change is exactly `rank_index <= 1` → `rank_index >= 1`, nothing else altered.
   `git diff` should show this is a fresh file; diff it against
   `$HOME/eu5-files/game/.../generic_capital_economy_mission_pack.txt` to prove
   ONLY the operator differs:
   ```bash
   diff "$HOME/eu5-files/game/in_game/common/missions/generic_capital_economy_mission_pack.txt" \
        in_game/common/missions/generic_capital_economy_mission_pack.txt
   ```
   Expected: only the `rank_index` line(s) differ. If MORE differs, stop and report.
2. **Investigate the second gate.** The player reported TWO failing gates in-game:
   "Invalid Target" AND "Requirements not met". The rank_index fix addresses the
   confirmed one. Now that you have the real file, READ the full `establish_a_trade`
   task block and its `select_trigger` (both `visible` and `enabled`, plus any
   `source`/market-scope conditions). Determine whether a second condition also
   blocks completion. See NOTES.md §3. If a second genuine bug exists, fix it too —
   but ONLY if clearly broken; do not change intended design. If unsure, ask Joseph.
3. Confirm the file is saved **UTF-8 with BOM** (EU5 requirement). Check/convert:
   ```bash
   file in_game/common/missions/generic_capital_economy_mission_pack.txt
   # if no BOM, add one:
   # printf '\xEF\xBB\xBF' | cat - file > tmp && mv tmp file
   ```

### Step 4 — Commit + push
```bash
git add in_game/common/missions/generic_capital_economy_mission_pack.txt
git commit -m "feat: add vanilla mission file with rank_index fix applied"
git push -u origin claude/upbeat-johnson-BzSEU
```
NOTE: the file is Paradox copyright. It's committed only so the Workshop build has
it; this is a private bugfix mod, standard practice for override mods. Joseph is fine
with this (it's his licensed content, his repo).

### Step 5 — Publish to Workshop (private first)
1. Edit `eu5_bugfix_item.vdf`: replace BOTH `__REPLACE_WITH_ABSOLUTE_PATH__` with
   the absolute path to this repo (the mod root containing `.metadata/` and `in_game/`).
   - `contentfolder` = repo root
   - `previewfile`   = `<repo root>/.metadata/thumbnail.png`
   - Keep `visibility 2` (private) and `publishedfileid 0` for the FIRST publish.
2. Publish:
   ```bash
   ~/steamcmd/steamcmd.sh +login <STEAM_USERNAME> \
     +workshop_build_item /absolute/path/to/eu5_bugfix_item.vdf \
     +quit
   ```
3. SteamCMD prints a new `publishedfileid`. Write it back into
   `eu5_bugfix_item.vdf` (replace the `0`) so future updates patch in place.
   Also consider adding it to `game_custom_data` in `.metadata/metadata.json`
   so the Paradox launcher associates the download (confirm field name against a
   known-good EU5 Workshop mod's metadata before relying on it).
4. Commit the VDF id write-back.

### Step 6 — Test on GFN (Joseph does this manually)
Subscribe to the new private Workshop item → launch EU5 on GFN → enable mod in a
playset → take Develop a Capital Economy → reach Establish a Trade → confirm a
Town (e.g. Aberdeen) is now selectable and the task completes → confirm following
tasks proceed. If it doesn't appear: log out/in of Steam in the GFN session,
re-subscribe, adjust Steam download region, relaunch.

### Step 7 (parallel) — Escalate to Paradox
Post "still present in 1.2.5" follow-up on the confirmed thread (link in NOTES.md
§8) so a vanilla patch eventually retires this mod. Draft text is in NOTES.md.

---

## Gotchas / things the web session learned

- SteamCMD `~` paths break → always absolute.
- `@sSteamCmdForcePlatformType` has TWO s's at the start. Order matters: set it
  BEFORE `app_update`.
- EU5 override = whole-file replacement. There IS a `REPLACE:`/`TRY_REPLACE:`
  database mechanism but the wiki marks task-level applicability "Unknown", so we
  use the safe whole-file override. (If you want to try shrinking the footprint to
  a REPLACE: block later, test it live first — risky without debug mode.)
- Do NOT publish the stub/placeholder — an empty or partial mission file would
  DELETE all capital-economy missions from the game. Only publish the real vanilla
  file + the one-line fix.
- Enabling any mod changes checksum → disables achievements + blocks MP with
  vanilla clients. Expected; note it in the Workshop description (already done).

## Open questions for Joseph (ask if they come up)
- Steam username for SteamCMD login (only Joseph has it).
- If a second gate ("Invalid Target") turns out to be intended market-scoping
  rather than a bug, confirm whether to leave it (task still completable with an
  in-market urban location) or widen it.
