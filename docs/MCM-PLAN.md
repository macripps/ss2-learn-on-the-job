# MCM settings page: plan

Status: **plan only**, not implemented. Based on the MCM wiki (Neanka/MCM_0.1_AS3), the MCM 1.39 `MCM.psc`
API (from the MCM mod in the Fallout London MO2 instance), and SS2 3.8.0's own `MCM/Config/SS2/config.json`.

## Key decision: settings live in GlobalVariables, bound with `GlobalValue`

MCM can store settings three ways:

| Source type | Stored in | Notes |
|---|---|---|
| `GlobalValue` | a GLOB form, **saved with the save game** | SS2 uses this for 169 of its settings |
| `PropertyValueBool/Int/Float` | a script property on a form | needs MCM ≥ 1.10 (`minMcmVersion: 2`) |
| `ModSettingBool/Int/Float` | `MCM\Settings\<Mod>.ini`, per install, not per save | script must call `MCM.GetModSetting*`, i.e. depends on MCM being installed |

Use **GlobalValue**, because:
- It's the SS2 convention, and settings travel with the save like the rest of SS2's options.
- The script just reads `GlobalVariable.GetValue()`. It needs **no MCM or F4SE calls** to read settings, so the mod
  keeps working without MCM: defaults apply and `set <global> to <value>` works from the console.
- Being notified of a change would need `RegisterForExternalEvent`, which is an **F4SE** function. Reading the
  globals at each daily update means no notification is needed.

MCM becomes an *optional* requirement (MCM itself needs F4SE; this mod still doesn't).

## Settings

New GLOB forms in `SS2LearnOnTheJob.esp` (light plugin object IDs 0x801+; the quest is 0x800).

| Global (EDID) | ID | Type | Default | Control | Range |
|---|---|---|---|---|---|
| `AISS2LOJ_Enabled` | 801 | short | 1 | switcher | |
| `AISS2LOJ_TrainingRate` | 802 | float | 0.25 | slider | 0.05–2.0, step 0.05 |
| `AISS2LOJ_MaxStatFromWork` | 803 | short | 10 | slider | 1–10, step 1 |
| `AISS2LOJ_NotifyOnImprove` | 804 | short | 1 | switcher | |
| `AISS2LOJ_MaxCatchUpDays` | 805 | float | 3 | slider | 1–7, step 1 |
| `AISS2LOJ_UpdateIntervalHours` | 806 | float | 24 | stepper (6/12/24) | |
| `AISS2LOJ_DebugLogging` | 807 | short | 0 | switcher | |

New behaviour behind two of them:
- **Max stat from work** (realism option): work only trains a stat up to this value; beyond it settlers need dedicated
  recreation training. 10 means no cap (current behaviour).
- **Notify on improve**: SS2 itself shows **nothing** when a stat improves; it only fires
  `NPC_RPGManager_SpecialStatImproved`, and nothing in SS2 listens to it. Getting an actor's or stat's name in a
  notification needs F4SE (`GetDisplayName`, `ActorValue.GetName`). The F4SE-free option is seven Message forms
  (`AISS2LOJ_ImprovedStrength` … `Luck`: "A settler's Endurance improved on the job.") picked by stat.
  Named messages ("Sturges' …") would need a quest reference alias plus `<Alias=Settler>` text replacement. That's
  more plugin work, so it can come later.

Notes:
- The update interval only changes granularity, not the total: gains are based on elapsed game time.
- A stepper stores the *option index* (0/1/2), not the hours, so the script would have to map it to 6/12/24. A slider
  (6–48, step 6) stores the hours directly and is simpler. Decide when implementing.

## Menu layout (`MCM/Config/SS2LearnOnTheJob/config.json`)

`modName` must equal the folder name. Sketch (the Advanced entries are abbreviated: `"...": "805"` means
"same shape as the General entries, bound to global 805"):

```json
{
  "modName": "SS2LearnOnTheJob",
  "displayName": "SS2 Learn on the Job",
  "minMcmVersion": 2,
  "pluginRequirements": ["SS2LearnOnTheJob.esp", "SS2.esm"],
  "content": [
    { "type": "text", "html": true, "text": "<p align='center'><font size='24'>SS2 Learn on the Job</font></p>" },
    { "type": "text", "text": "Settlers slowly train the SPECIAL stat their job uses." },

    { "type": "section", "text": "General" },
    { "id": "bEnabled:General", "type": "switcher", "text": "Enabled",
      "help": "Turn job training on or off. Progress already gained is kept.",
      "valueOptions": { "sourceType": "GlobalValue", "sourceForm": "SS2LearnOnTheJob.esp|801" } },
    { "id": "fTrainingRate:General", "type": "slider", "text": "Training Rate",
      "help": "Training days gained per day worked. 1.0 = same as a recreation training plot. Default 0.25.",
      "valueOptions": { "min": 0.05, "max": 2.0, "step": 0.05,
        "sourceType": "GlobalValue", "sourceForm": "SS2LearnOnTheJob.esp|802" } },
    { "id": "iMaxStatFromWork:General", "type": "slider", "text": "Max Stat From Work",
      "help": "Work only trains a stat up to this level; beyond it settlers need a training plot. 10 = no limit.",
      "valueOptions": { "min": 1, "max": 10, "step": 1,
        "sourceType": "GlobalValue", "sourceForm": "SS2LearnOnTheJob.esp|803" } },
    { "id": "bNotify:General", "type": "switcher", "text": "Notify When a Settler Improves",
      "valueOptions": { "sourceType": "GlobalValue", "sourceForm": "SS2LearnOnTheJob.esp|804" } },

    { "type": "section", "text": "Advanced" },
    { "id": "fMaxCatchUp:Advanced", "type": "slider", "text": "Max Days Credited Per Update", "...": "805" },
    { "id": "fInterval:Advanced", "type": "slider", "text": "Update Interval (hours)", "...": "806" },
    { "id": "bDebug:Advanced", "type": "switcher", "text": "Debug Logging", "...": "807" },
    { "type": "button", "text": "Run Update Now",
      "help": "Credits the time since the last update immediately (for testing).",
      "action": { "type": "CallFunction", "form": "SS2LearnOnTheJob.esp|800",
                  "function": "MCM_RunUpdateNow", "params": [] } }
  ]
}
```

One page with sections is enough (SS2 uses `pages`; we don't need them). No `settings.ini` is needed, since that
file only holds `ModSetting*` defaults; GLOB defaults live in the plugin.

## Implementation steps

1. **`tools/build_plugin.py`**
   - Write GLOB records (EDID, FNAM type `s`/`f`, FLTV float) in their own `GRUP` before the QUST group,
     and update the HEDR record count and next object ID.
   - Write VMAD **object properties** pointing at the globals (property type 1, format 2: formID + alias -1). The
     VMAD reader in `esp_inspect.py` already decodes this layout, so it can verify the result.
   - Optional: 7 MESG records for the notifications.
   - Check record layout against an SS2 GLOB (e.g. `SS2.esm` 0x020F58, the tax-rate global) with `dump-record`
     before trusting it.
2. **Script**
   - Replace the `fJobTrainingRate`/`bEnabled`/… Auto properties with `GlobalVariable Property ... Auto Const mandatory`
     and read them at each update.
   - Add `MaxStatFromWork` to the eligibility check (`fBaseValue < min(iMaxStatValue, MaxStatFromWork)`).
   - Add `Function MCM_RunUpdateNow()` → `UpdateAllSettlements()`.
   - Notifications: after `ProcessTraining` returns true, compare base values before/after to find which stat rose
     and show its message.
   - Bump `iModVersion` to 2. No migration is needed as long as 0.1 never shipped publicly (the old Auto property
     values just become orphaned in testers' saves, which is harmless).
3. **Build:** copy `source/mcm/config.json` → `MCM/Config/SS2LearnOnTheJob/config.json` in the package.
4. **Docs:** replace the `setpqv` console lines with `set AISS2LOJ_TrainingRate to 0.5` etc.
5. **Test:** with MCM installed (sliders move the globals, `getglobalvalue AISS2LOJ_TrainingRate` matches, Run Update
   Now credits progress) **and without** MCM (defaults work, no errors in the Papyrus log).

## Open questions for you

- Keep the per-stat notifications without names, or go straight to named ones (needs a quest alias)?
- Is "Max Stat From Work" wanted? It's a balance/realism choice.
- Per-job-type multipliers (e.g. farming trains faster than shopkeeping)? Easy to add later as more globals.
