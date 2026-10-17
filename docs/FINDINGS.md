# SS2 "Learn on the Job" — research notes

Running log of findings while building a mod that gives SS2 settlers SPECIAL
training progress for working their job (not just for recreation/training plots).
Target: Sim Settlements 2 All Chapters Pack **3.8.0** + Workshop Framework **2.6.1**.

## Folder layout (this project)

Repo layout and the build/release flow are in `README.md`. Local, gitignored working data
(recreate with `bash tools/setup.sh`):

| Path | What |
|---|---|
| `extracted/ss2-3.8.0/` | SS2 .esm/.esp, Main .ba2 archives, MCM config (textures skipped) |
| `extracted/scripts/Scripts/` | SS2 compiled `.pex` pulled out of the BA2s (1872 files) |
| `extracted/wsfw-2.6.1/` | Workshop Framework esm, BA2, `.pex` |
| `extracted/papyrus-base/` | Vanilla FO4 Papyrus sources (from the game install's `Base.zip`) |
| `decompiled/` | **Decompiled** `.psc` for SS2 + WSFW (Champollion 1.3.2) — search here |

Research tools: `tools/ba2_extract.py <ba2> <out> [regex]` (minimal BA2 GNRL extractor) and
`tools/esp_inspect.py <plugin> find-script <Script> | edid <hex>... | dump-record <hex>` (decodes VMAD script properties).

Other useful locations on this PC (all configurable in `tools/paths.sh`):
- Game install, the one actually played (with F4SE, CK, compiler): `E:\SteamLibrary\steamapps\common\Fallout 4 377160`.
  Its `Data\Scripts\Source\` has the **F4SE** sources loose at the top level and the vanilla sources in `Base\Base.zip`.
  The build uses only vanilla (+ stubs) on purpose, so the mod can't come to depend on F4SE.
- `...\common\Fallout 4` is a separate CK-only folder. Its `Base.zip` and `PapyrusCompiler.exe` differ from the
  game install's copies (same size, different hash). Use the game install's.
- Champollion: `C:\Users\Mike\Downloads\Champollion.v1.3.2\Champollion.exe` (`<dir> -r -s -t -p <out>`)
- Archive2 is installed but its CLI is unreliable (crashes on bad args) — use `tools/ba2_extract.py`.
- `D:\ModOrganizer\Unpacked\SS2 3.2.0 Scripts\Scripts\` is **also decompiled** (has `#DEBUG_LINE_NO` markers),
  not original source; no author comments there. Only useful for diffing against older versions.
- The 7.8 GB SS2 zip is zip64; Info-ZIP `unzip` fails on it, use 7-Zip.

## How SS2 settler "experience" actually works

There is no generic settler XP. Settlers have SPECIAL stats; recreation
"training" plots raise one stat over time. All of it lives in
`SimSettlementsV2:Quests:NPC_RPGManager` (`decompiled/SimSettlementsV2/Quests/npc_rpgmanager.psc`).

- Quest **SS2_NPC_RPGManager** = `SS2.esm` local FormID **0x00EB6E**
  (load-order ID shown as 0200EB6E; SS2 masters are Fallout4.esm, WorkshopFramework.esm).
- `TrainingMaps` (struct `StatTraining`): per stat — `StatAV`, `TrainingProgressAV`,
  `TrainingTimestampAV`, `IsTrainingKeyword`, `BuildingPlanClassKeyword` (the recreation class that trains it).
  8 entries: S,P,E,C,I,A,L + `SoldierXP` (0x04D4C5, soldier ranks — different math).
- `TrainingTimes` = `[1, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55]` — **cumulative in-game days** of
  training needed to *reach* stat N. e.g. 4→5 needs progress ≥ 15, i.e. 5 more days from 10.
  1→10 takes 54 days of dedicated training.
- `TrainingProgressAV` stores cumulative days. `StartTraining()` initialises a 0 value to
  `GetStatTrainingTimeNeeded(currentStat)` so progress starts at the current level's threshold.
  **Anything that adds progress must do the same initialisation first.**
- `ProcessTraining(actor, abCalledFromStopTraining)`: for each stat with a non-zero timestamp,
  adds elapsed days to progress; then for every stat (training or not) raises base value by **1**
  if `progress >= TrainingTimes[base+1]`. Max stat is 10 (`iMaxStatValue`). Only one point per call.
  Returns true if any stat changed → caller runs `UpdateSettlerPlotBonuses(actor)`.
- Daily driver: `OnTimerGameTime` (timer 101, every 24 game hours) → `TrainSettlementSettlers` for
  every workshop; also runs on entering a settlement (`HandlePlayerEnteredSettlement`).
- Training starts/stops from `UpdateSettlerTrainingStatus` on WorkshopParent's
  assigned/unassigned events — only for plots whose config has `AssignmentType_Leisure`.
- `GetSettlers(workshop, abIncludePermanent)` delegates to `SimSettlementsV2:Quests:MI:GrabNPCs`
  (sends a story event and waits — not free, so call it at most daily per settlement).

## Which stat a job uses (data-driven)

`SimSettlementsV2:Quests:PlotManager` (quest **0x00EB47**) property `PlotSpecialStatAdjustments`
(struct `PlotSpecialStatAdjustment`: `BuildingClassKeyword`, `SpecialStatAV`, `ResourceAV`, ...).
A plot's class is `simplot.GetParentBuildingPlan().ClassKeyword`. Decoded from 3.8.0:

| Job classes (SS2_PlotTypeSubClass_*) | Stat |
|---|---|
| Agricultural_* | Endurance |
| Commercial_* (all shops, bar, clinic…) | Charisma |
| Industrial_* | Strength |
| Martial_* | Agility |
| Municipal_PowerPlant_* | Intelligence |
| Municipal_WaterPlant_*, Municipal_Sanitation | Perception |

(Luck has no job.) Reading this list at runtime means add-on classes work automatically.
Settings can also add `BehaviorModifiers` (type 8) per settlement — ignored for now.

## Useful SS2 member signatures (verified against 3.8.0 decompile)

- `NPC_RPGManager`: props `WorkshopParent`, `PlotManager`, `AssignmentType_Job`, `AssignmentType_Leisure`,
  `WorkshopItemKeyword`, `SecondaryAssignmentMarkerLinkKeyword`, `TrainingMaps`, `iMaxStatValue` (AutoReadOnly 10);
  functions `Actor[] GetSettlers(workshopscript, Bool)`, `Float GetStatTrainingTimeNeeded(Int, workshopscript)`,
  `Bool ProcessTraining(Actor, Bool)`, `UpdateSettlerPlotBonuses(Actor)`.
- `SimSettlementsV2:ObjectReferences:SimPlot` (extends WorkshopObjectScript): `GetPlotConfig()`, `GetParentBuildingPlan()`.
- `SimSettlementsV2:MiscObjects:PlotConfiguration` (extends Form Const): `Keyword[] AssignmentTypeKeywords`.
- `SimSettlementsV2:Weapons:BuildingPlan` (extends Form Const): `Keyword ClassKeyword`.
- `SimSettlementsV2:UtilityFunctions.GetLinkedPlot(ObjectReference, Keyword)` Global — resolves secondary assignment markers to their plot.
- `ObjectReference.GetWorkshopOwnedObjects(Actor)` is a vanilla native.

## Design decisions

- **Do not override SS2 scripts.** Replacing `npc_rpgmanager.pex` would break on every SS2 update
  and recompiling decompiled code is risky. Instead: a standalone quest + script that *calls* SS2's
  public functions and adds job progress to the same `TrainingProgressAV`s SS2 already uses.
- Get SS2 objects at runtime via `Game.GetFormFromFile(0x00EB6E, "SS2.esm")`, so the plugin needs no
  filled properties.
- Compile against small **stub** `.psc` files for SS2 types (only the members used), not the full
  decompiled tree. Papyrus resolves members by name at runtime, so stubs only need matching signatures.

## WSFW / SS2 conventions for loading and startup

**WSFW quest hierarchy** (`decompiled/WorkshopFramework/Library/`):
`ControllerQuest` → `LockableQuest` → `VersionedLockableQuest` → `SlaveQuest` / `MasterQuest`.
- `ControllerQuest.OnQuestInit`: waits for PlayerRef, registers `OnPlayerLoadGame`, calls
  `HandleQuestInit()` then `HandleGameLoaded()`. Subclasses override the `Handle*` hooks and call `Parent.`.
- `VersionedLockableQuest`: `iInstalledVersion` vs `gCurrentVersion` global → `HandleInstallModChanges()` on upgrade.
- `MasterQuest` (SS2's is `SS2_Main`, 0x00EB49, script `SimSettlementsV2:Quests:SS2Main`): its own quests are
  **not** start-game-enabled. It starts `FrameworkStartQuests` (47 quests, incl. NPC_RPGManager and PlotManager)
  only after `CheckQuest` (WSFW MainQuest 0x000F99) reaches stage 10, so they don't compete with other mods at
  startup. Game-load and location-change events go out to `SlaveQuest`s through `ThreadManager.QueueRemoteFunctionThread`.
- `LockableQuest` provides `GetLock`/`ReleaseLock` for shared state.

**Official third-party add-on template**: `SimSettlementsV2:Quests:AddonPack` (`Quests/AddonPack.psc`,
template quest 0x00EB1F; SS2Extended's `SS2E_AddonQuest` uses it). The pattern for external mods:
1. Start-game-enabled quest; **no hard property links to SS2**. `UpdateVars()` caches forms via
   `Game.GetFormFromFile` (SS2Main 0x00EB49, SS2 version global 0x0149CC, PlayerRef 0x14, WorkshopParent 0x02058E).
2. `OnQuestInit` and `Actor.OnPlayerLoadGame` → `UpdateVars()` → `TryToHandleGameLoaded()`, which
   re-checks every 2 s until `SS2Main.IsRunning()`.
3. Version check (`iInstalledVersion`) → `InstallModChanges()`.
4. Heavy registration work runs after a **random 1–15 s delay** so many add-ons don't spike the VM at once on load.
Our quest can't extend AddonPack (it requires an AddonPackConfiguration MiscObject and does content registration),
so it copies steps 1–3. Step 4 doesn't apply: our work runs from a game-time timer, not at load.

**Other checks:**
- No SS2/WSFW "daily tick" custom event exists (all `SendCustomEvent` names were checked). SS2's own training uses a
  plain 24h `StartTimerGameTime` loop that calls `GetSettlers` per workshop inline, the same shape as ours.
- `GetSettlers` is safe to call concurrently with SS2: it uses a pool of `Event_NPCGrabberQuests`
  matched by a random caller ID. If the story event fails and the settlement isn't loaded, it returns an empty array.
- `Settings_SPECIALStats_RolledForSettlers` = 0 only skips *rolling*; settlers keep their default stats and
  SS2 still trains them. No setting disables training, so we don't gate on one.
- Logging: SS2 uses `WorkshopFramework:Library:UtilityFunctions.ModTraceCustom(log, msg, severity, bNormalTraceAlso)`,
  which is just `Debug.TraceUser`. Ours is equivalent behind `bDebugLogging`.
- Papyrus gotcha: values of `Auto` properties are saved with the game, so changing a default in a new release
  doesn't reach existing saves. Hence the `iModVersion` / `InstallModChanges` hook.

## Authorship decision (2026-10-17)

The mod's Papyrus is **hand-written by Mike** in `source/scripts/AISS2LearnOnTheJob/JobTrainingQuest.psc`
(script `AISS2LearnOnTheJob:JobTrainingQuest`; started blank).
Naming: `AI` = Mike's author prefix (AgentIcarus on Nexus), per Kinggath's SS2 Mod School convention of prefixing
your forms and scripts. Quest editor ID is `AISS2LOJ_JobTrainingQuest`; the planned globals are `AISS2LOJ_*`.
The plugin file stays `SS2LearnOnTheJob.esp`. Earlier sections and the first-test notes use the old v0.1 names
(`SS2LOJ_*`, `SS2LearnOnTheJob:`). Claude does research, docs, tooling and builds, but
**does not write mod script code**. The AI-written v0.1 script is kept as `reference/JobTrainingQuest.ai-draft.psc`.
It isn't compiled (not on the import path) or shipped. The v0.1 description below refers to that draft.
For the Nexus AI tags this implies, see `docs/NEXUS.md`.

## Implementation (v0.1 AI draft, 2026-10-17)

| Path | What |
|---|---|
| `reference/JobTrainingQuest.ai-draft.psc` | The v0.1 script (AI draft, reference only) |
| `source/stubs/SimSettlementsV2/...` | Compile-only SS2 signatures (never shipped) |
| `tools/build_plugin.py` | Writes the ESL-flagged `.esp` (no CK needed) |
| `tools/build.sh` | `bash tools/build.sh` → compile + plugin + `dist/SS2LearnOnTheJob.zip` |

Release decision (2026-10-17): **release on Nexus Mods** by uploading `dist/SS2LearnOnTheJob.zip` built locally.
A GitHub release workflow was built and then dropped. CI can't compile Papyrus anyway (the CK compiler is
Windows-only and not redistributable, and the vanilla sources can't be committed). If CI is wanted later, the
options are Caprica + signature stubs, a self-hosted runner, or committing a locally built zip and checking it
against source hashes.

How it works: start-game-enabled quest `SS2LOJ_JobTrainingQuest` (FormID 0x800 in the plugin) runs a
24 game-hour timer. Each tick, for every player-owned workshop: `GetSettlers` → settlers with
`AssignmentType_Job` → their owned SimPlots (or plots linked via secondary assignment markers) whose
PlotConfiguration has `AssignmentType_Job` → class keyword → stat(s) from `PlotSpecialStatAdjustments`.
Adds `elapsedDays (capped at 3) * fJobTrainingRate (0.25)` to that stat's `TrainingProgressAV`
(initialised to the current level's threshold if 0), then calls SS2's `ProcessTraining(actor, False)` and,
if a stat rose, `UpdateSettlerPlotBonuses`. SS2 does the actual stat increase, so its
`SendSpecialStatImprovedEvent`, max-stat handling and plot output updates all apply.
**Correction:** SS2 shows *no* on-screen notification for stat increases. `SendSpecialStatImprovedEvent` only fires
the custom event `npc_rpgmanager_SpecialStatImproved`, and nothing in SS2 listens to it (grep of the 3.8.0 decompile).
An earlier summary wrongly said SS2's notifications apply. See `docs/MCM-PLAN.md` for the planned notify option.

Release/MCM research: `docs/NEXUS.md` (upload process, rules incl. AI tagging, page/archive contents) and
`docs/MCM-PLAN.md` (GlobalValue-based settings plan). MCM Papyrus API source: `D:\ModOrganizer\Instances\Fallout 4 (GOG)\mods\Mod Configuration Menu\Scripts\Source\User\MCM.psc`
(MCM 1.39). Its change event needs F4SE's `RegisterForExternalEvent`, which is why the plan uses GlobalValue.

Pace at the default 0.25: 1 job day = 6 hours at a gym. Going 1→10 by work alone ≈ 216 days;
3→4 ≈ 16 days, 7→8 ≈ 28 days. Job + leisure training of the same stat stack.

Plugin format notes: masters Fallout4.esm, WorkshopFramework.esm, SS2.esm → own forms use index 03.
Record form version 0x83, HEDR 1.0, VMAD v6 / object format 2. A quest VMAD with no fragments has
no trailing data (checked against SS2E_AddonQuest). The compiled .pex was decompiled again to check:
all SS2 accesses are by-name property/function calls.

Gotcha: in this shell, backticks *anywhere* in a Bash tool command (quoted heredocs, single-quoted
sed expressions) get mangled by the tool's eval wrapper and *execute*. This bit twice. Never put backticks
in Bash commands here; use the Edit/Write tools for any text containing them.

## First in-game test of the v0.1 draft (2026-10-17, 20:35–20:45+)

Setup: user's "Sim Settlements 2" MO2 profile (uses the Documents INIs, which already have Papyrus logging and
trace on). `setpqv SS2LOJ_JobTrainingQuest bDebugLogging 1`, then waited 24h. Logs:
`Documents\My Games\Fallout4\Logs\Script\User\SS2LearnOnTheJob.0.log`, SS2's `SS2RPGManager.0.log`, and `Papyrus.0.log`.

Worked:
- Startup gating, timer, job → stat lookup and progress maths are all correct. 1.027 days elapsed × 0.25 = 0.2567
  per worker; farmers → Endurance, guards → Agility; fresh stats initialised to `TrainingTimes[base]`
  (Endurance 1 → 1.0). SS2's log shows the same progress values immediately after.
- No errors from the mod in `Papyrus.0.log`.

Problems:
1. **Too slow.** 60 settlers credited in 9m43s and still running when the user quit. The largest gaps between log
   lines were 207s, 63s and 49s: the per-settlement `GetSettlers` lookup and plot scan.
2. **Pointless `ProcessTraining` calls.** It was called for all 60; **none** of our additions crossed a threshold.
   `ProcessTraining` also processes active *recreation* training (it reports "any stat changed"). 11 calls
   returned true purely from recreation progress, and each then triggered the expensive
   `UpdateSettlerPlotBonuses`. So the "improved a stat through work" log lines were **misattributed**.
   Fix idea: compute the crossing ourselves (`newProgress >= GetStatTrainingTimeNeeded(base + 1)`) and only call
   `ProcessTraining` when work crosses it.
3. **No completion signal.** Nothing logged when the loop finished. Log a summary (duration, settlements, settlers).
4. `UpdateSettlerPlotBonuses` paths hit an **existing SS2 error**: `Cannot GetValue/SetValue with None ActorValue` in
   `ResourceManager.AdjustSettlementVirtualResource` from `SimPlot.ApplyPlotResource` (plot FF04A30C). The same error
   via the same path is in Papyrus logs from 2026-10-16 and 2026-10-17 11:49, before the mod existed, so it's not ours.
   Fix 2 avoids triggering it more often.
5. Idea: skip workshops with no population before `GetSettlers`. First verify that the population value is
   maintained for unloaded settlements (vanilla `WorkshopRatingPopulation`; SS2's `NPC_RPGManager.PopulationAV` 0x12723E).
6. Robustness idea: `bUpdateInProgress` is saved with the game. Papyrus normally resumes saved stacks, but resetting
   it on game load (or using a timestamp) would stop a stuck flag from blocking updates forever.
7. Noise, not a bug: `UnassignFromTrainingPlot … was not assigned` lines come from SS2's own handling of stats at 10.
   SS2's daily loop produces the same lines.

## Testing checklist

1. Install `dist/SS2LearnOnTheJob.zip` in MO2 and enable it after SS2. Load a save with SS2 settlements.
2. Console: `sqv SS2LOJ_JobTrainingQuest` → should be running, with `fJobTrainingRate` 0.25.
3. Speed up for testing: `setpqv SS2LOJ_JobTrainingQuest fJobTrainingRate 20` and
   `setpqv SS2LOJ_JobTrainingQuest bDebugLogging 1`, then wait 24h (the first tick fires 24 game hours
   after install and credits the time since install). A farmer's Endurance should rise. Log:
   `Documents\My Games\Fallout4\Logs\Script\User\SS2LearnOnTheJob.0.log`
   (needs `bEnableLogging=1` and `bEnableTrace=1` under `[Papyrus]` in Fallout4Custom.ini).
4. Set the rate back to 0.25 afterwards.

## Ideas / open questions

- MCM page for the rate (MCM can bind to quest script properties directly).
- Jobs with no stat mapping (some add-on classes, HQ departments, caravans) get nothing; could fall back on plot type.
- SoldierXP for Martial jobs (guards) would use `GetXPEarnedTraining` / `TryToRankUpSoldier`: different math, not done.
- After each SS2 update, re-check the training functions in `npc_rpgmanager.psc` and the `TrainingTimes` values.
