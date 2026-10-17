# SS2 Learn on the Job

A small add-on for **Sim Settlements 2** (Fallout 4). Settlers slowly train the SPECIAL stat their
job uses: farmers gain Endurance, shopkeepers Charisma, industrial workers Strength, and so on.
In SS2 itself, stats only train on recreational training plots.

- Uses SS2's own training system and job → stat table, so stat increases and plot bonuses behave exactly
  as they do for SS2's training. Add-on job types are picked up automatically.
- Doesn't override any SS2 or Workshop Framework scripts. It's one ESL-flagged plugin with a single quest.
- Default pace: one day of work counts as a quarter of a day at a training plot.

**Requires:** Sim Settlements 2 (built against 3.8.0) and Workshop Framework. F4SE is not needed.

## Settings

To be documented once the hand-written script settles. The quest's editor ID is `AISS2LOJ_JobTrainingQuest`, so
script properties can be inspected with `sqv AISS2LOJ_JobTrainingQuest` and changed with `setpqv`.

## Naming

Forms and scripts use the author prefix `AI` (AgentIcarus), following Kinggath's SS2 Mod School convention:
script namespace `AISS2LearnOnTheJob`, editor IDs `AISS2LOJ_*`. The plugin file stays `SS2LearnOnTheJob.esp`.

## Repository layout

| Path | Committed | What |
|---|---|---|
| `source/scripts/` | yes | Papyrus source of the mod (hand-written) |
| `reference/` | yes | AI-written v0.1 draft of the script, kept for reference. Not compiled or shipped. |
| `source/stubs/` | yes | Signature-only SS2 stubs, used to compile without SS2's sources. Never shipped. |
| `tools/` | yes | Build, setup and research tools (see below) |
| `docs/FINDINGS.md` | yes | Research notes on SS2 internals, design decisions and the testing checklist |
| `docs/NEXUS.md` | yes | Nexus upload process, rules (incl. AI tagging), page and archive contents, description draft |
| `docs/MCM-PLAN.md` | yes | Plan for the MCM settings page |
| `extracted/` | **no** | Files extracted from the game and mod archives |
| `decompiled/` | **no** | Decompiled SS2 / Workshop Framework scripts (for research) |
| `build/`, `dist/` | **no** | Build output |

Nothing from Bethesda, SS2 or Workshop Framework is committed. `extracted/` and `decompiled/` are
recreated locally from your own copies.

## Building

Needs Windows with Fallout 4 and its Creation Kit (for `PapyrusCompiler.exe` and `Base.zip`),
7-Zip, Python 3 and Git Bash. Check `tools/paths.sh`, or override values in `tools/paths.local.sh`.

```bash
bash tools/setup.sh            # one-off: extract archives, unpack vanilla sources, decompile (research)
bash tools/build.sh            # compile + build plugin -> dist/SS2LearnOnTheJob.zip
```

`tools/build.sh` only needs the vanilla sources (`bash tools/setup.sh --base-only`) and does that itself if
they're missing. The full setup also needs the SS2 / Workshop Framework downloads and Champollion.

| Tool | Purpose |
|---|---|
| `tools/build_plugin.py` | Writes the `.esp` directly; the Creation Kit isn't needed |
| `tools/ba2_extract.py` | Minimal BA2 extractor |
| `tools/esp_inspect.py` | Reads plugins and decodes script properties (VMAD) |

## Releasing

Releases go on Nexus Mods. Run `bash tools/build.sh` and upload `dist/SS2LearnOnTheJob.zip`. It's laid out
for direct install by MO2/Vortex: the plugin plus `Scripts/` (compiled script and its source).
