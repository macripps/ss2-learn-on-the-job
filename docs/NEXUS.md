# Releasing on Nexus Mods

Researched 2026-10-17. Nexus blocks automated page fetches, so the page-form details below come from the
help centre plus what's visible in your existing downloads' metadata. Double-check field names on the
live upload form.

## Process

1. **Log in** and open *Upload mod* for Fallout 4 (anonymous uploads aren't possible). You can create the page,
   fill it in and add images before publishing; it stays unpublished until you publish it.
2. **Mod page details:** name, summary, description, category, version, author, language, tags, adult flag.
3. **Requirements tab:** link required Nexus mods and DLC (see below).
4. **Permissions and credits:** choose the permission options and list credits.
5. **Files:** upload the archive and give it a file name, version, category (*Main* / *Optional* / *Update* /
   *Old*) and description. Keep "allow mod manager download" on.
6. **Images:** at least a primary image. Images must be relevant and not misleading.
7. **Publish.** Every file goes through automated checks (archive preview + VirusTotal). If a check fails,
   the file is **quarantined** until a moderator reviews it.

## Rules that matter for this mod

From the [File Submission Guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines) and the
[quarantine article](https://help.nexusmods.com/article/117-why-has-my-mod-been-quarantined):

- **Archive:** ZIP or 7z (ours is ZIP). No nested archives, no passwords. Put alternative versions in separate
  files on the page, not as archives inside the archive.
- **Generative AI must be tagged.** There are three tags:
  - *AI-Generated Content*: AI-generated code, UI, voices, dialogue, translations, music or in-game assets.
  - *AI Media*: AI-made thumbnails, promo art, videos, **or mod page descriptions**.
  - *AI Assisted*: developer-led work with limited AI involvement. It "requires significant evidence of
    development and proven knowledge", e.g. version control history and being able to explain the code.

  Untagged or mis-tagged AI use "may be subject to moderation action".

  **Where this mod stands (updated 2026-10-17):** the shipped Papyrus is now hand-written by Mike in
  `source/scripts/` (the AI draft is in `reference/`, not shipped), so *AI-Generated Content* for code shouldn't apply.
  AI was still involved:
  - research into SS2 internals and these docs;
  - the build tooling and SS2 compile stubs (not shipped);
  - `tools/build_plugin.py`, which generates the shipped `.esp`. That's a tiny data record (one quest, plus globals
    later), and recreating it in the Creation Kit would remove even that.

  That pattern ("developer-led work with limited AI involvement") is what *AI Assisted* describes, so it's probably
  the honest tag. Its evidence requirement (version history, being able to explain the code) is easier to meet if the
  repo is committed regularly as you write. Caveats:
  - If the hand-written script is closely ported from the AI draft rather than written fresh, that weakens the case.
  - If the page description is AI-drafted (e.g. the draft below), *AI Media* applies too. Writing it yourself avoids that.

  Your call either way, but don't leave AI involvement untagged.
- **Claims must be accurate.** No unsubstantiated performance or compatibility claims; you're responsible for
  everything on the page, including AI-written text. Only claim what's been tested.
- **Permissions:** everything in the archive is original. No SS2/WSFW/Bethesda files are included; the SS2 stubs
  aren't shipped. Credit the SS2 team and Workshop Framework as requirements, not as included assets.
- **No soliciting** of endorsements or donations in the description (a thank-you is fine).

## Values for this mod

| Field | Value |
|---|---|
| Game | Fallout 4 |
| Category | **Sim Settlements 2** (Nexus category 68, where SS2 and its add-ons live. Workshop Framework is in *Player Settlement*, 48) |
| Name | SS2 Learn on the Job (or "Learn on the Job - SS2 Settler Job Training") |
| Version | 0.1.0. Keep the same number in the plugin description, `fomod/info.xml` and the Nexus file version |
| File category | Main |
| File name | `SS2 Learn on the Job` + version (Nexus appends the version) |
| Requirements | **Sim Settlements 2 - All Chapters Pack** (mod 73394)<br>**Workshop Framework** (mod 35004, a requirement of SS2)<br>*Mod Configuration Menu* (mod 21497), optional, once the MCM page exists. MCM itself needs F4SE; this mod doesn't. |
| DLC | None (masters: Fallout4.esm, WorkshopFramework.esm, SS2.esm) |
| Tags | Settlement, Gameplay, Sim Settlements 2. Plus the AI tag(s) above. |

The same IDs come from MO2's `.meta` files for your downloads: SS2 All Chapters Pack 73394 (category 68),
SS2 base page 47976, Workshop Framework 35004 (category 48), MCM 21497.

## What goes inside the archive

Already there:
- `SS2LearnOnTheJob.esp`: ESL-flagged plugin. Its header has author + description; add the version to the description.
- `Scripts/AISS2LearnOnTheJob/JobTrainingQuest.pex` plus `Scripts/Source/User/...psc` (shipping source is
  normal practice and helps compatibility patchers).

To add:
- `fomod/info.xml`: metadata MO2 and Vortex show in their UI, **without** an installer. SS2 and WSFW ship exactly
  this (UTF-16, `<Name>`, `<Author>`, `<Version>`, `<Website>`, `<Description>`, `<Groups><element>Player Settlement</element></Groups>`).
  Generate it in `tools/build.sh` from one version variable.
- `MCM/Config/SS2LearnOnTheJob/config.json` once the MCM page is built (see `docs/MCM-PLAN.md`).
- No readme in the data root (it would land in `Data/`). The Nexus description is the readme.

## What goes on the page (outside the archive)

- **Summary:** one sentence, e.g. "Sim Settlements 2 settlers slowly train the SPECIAL stat their job uses:
  farmers get tougher, shopkeepers more charming."
- **Description:** draft below.
- **Requirements**, **permissions and credits**, **AI tags** as above.
- **Images:** a primary image is expected. A screenshot of a settler's SS2 stats screen or the MCM page works.
  This needs a real in-game capture.
- **Changelog** per version, in the file description or the *Logs* tab.
- Optional *Docs* tab: the console commands and how the progress maths works.

## Description draft (BBCode)

```
[size=4][b]SS2 Learn on the Job[/b][/size]

In Sim Settlements 2, settlers only improve their SPECIAL stats on recreational training plots. With this mod,
their day job counts too: a little of that training happens at work.

[b]How it works[/b]
[list]
[*]Once a day, each employed settler gains training progress in the stat their job uses: farmers Endurance,
shopkeepers Charisma, industrial workers Strength, martial jobs Agility, power plants Intelligence, and water
and sanitation Perception. The job-to-stat table is read from SS2 itself, so add-on plot types are included.
[*]By default one day of work counts as a quarter of a day at a training plot. Work and recreation training add up.
[*]SS2 applies the stat increase itself, so caps and plot bonuses work exactly as in SS2.
[*]No SS2 or Workshop Framework scripts are replaced. It's a single small ESL-flagged plugin and one script.
[/list]

[b]Requirements[/b]: Sim Settlements 2 (All Chapters Pack) and Workshop Framework. F4SE not required.

[b]Settings[/b] (console):
[code]setpqv AISS2LOJ_JobTrainingQuest fJobTrainingRate 0.5
setpqv AISS2LOJ_JobTrainingQuest bEnabled 0[/code]

[b]Install / uninstall[/b]: install with a mod manager, load after SS2. Safe to add mid-game. To uninstall, set
bEnabled to 0, save, then remove (stats already gained stay).

[b]Credits[/b]: kinggath and the Sim Settlements team for SS2 and Workshop Framework.
```

The uninstall advice and "safe to add mid-game" are claims; confirm them in testing before publishing.
Update the settings section once MCM lands.
