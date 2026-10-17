; AI-WRITTEN DRAFT (Claude, 2026-10-17). Reference only: not compiled, not shipped.
; The mod's real script is source/scripts/SS2LearnOnTheJob/JobTrainingQuest.psc, written by hand.
; Known issues found in the first in-game test are listed in docs/FINDINGS.md ("First in-game test").
ScriptName SS2LearnOnTheJob:JobTrainingQuest Extends Quest
{ Gives Sim Settlements 2 settlers SPECIAL training progress for working their job.

  SS2 only trains SPECIAL stats on recreational training plots. This script adds a fraction of
  that progress to the stat each settler's job uses (farmers -> Endurance, shopkeepers -> Charisma,
  etc., read from SS2's own PlotSpecialStatAdjustments table), then lets SS2's NPC_RPGManager
  apply any stat increases exactly as it does for its own training.

  Tuning from the console (quest editor ID SS2LOJ_JobTrainingQuest):
    setpqv SS2LOJ_JobTrainingQuest fJobTrainingRate 0.5
    setpqv SS2LOJ_JobTrainingQuest bDebugLogging 1 }

;-- Settings ----------------------------------------

Float Property fJobTrainingRate = 0.25 Auto
{ Training days gained per in-game day worked. SS2 recreation training is 1.0, so 0.25 means four
  days of work count as one day at a training plot. }

Float Property fMaxCatchUpDays = 3.0 Auto
{ Cap on the elapsed time credited in a single update, so long gaps (e.g. first run after
  installing, or a very long wait) can't hand out a burst of stats. }

Float Property fUpdateIntervalHours = 24.0 Auto
{ Game hours between updates. }

Bool Property bEnabled = True Auto
Bool Property bDebugLogging = False Auto

;-- Constants ---------------------------------------

; Bump when a release needs to migrate existing saves (see InstallModChanges)
Int iModVersion = 1 Const

Int iTimerID_WaitForSS2Main = 100 Const
Int iTimerID_JobTraining = 101 Const
Float fWaitForSS2MainSeconds = 2.0 Const

; Form IDs within SS2.esm / Fallout4.esm, looked up at runtime the way SS2's AddonPack template does
Int iFormID_SS2Main = 0x0000EB49 Const
Int iFormID_SS2_NPC_RPGManager = 0x0000EB6E Const
Int iFormID_PlayerRef = 0x00000014 Const
String sSS2Plugin = "SS2.esm" Const
String sFallout4Plugin = "Fallout4.esm" Const
String sLogName = "SS2LearnOnTheJob" Const

;-- Variables ---------------------------------------

Quest SS2Main
SimSettlementsV2:Quests:NPC_RPGManager RPGManager
Actor PlayerRef
Int iInstalledVersion = 0
Bool bTrainingTimerStarted = False
Float fLastUpdateTime = 0.0
Bool bUpdateInProgress = False

;-- Events ------------------------------------------

Event OnQuestInit()
  UpdateVars()
  RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
  TryToHandleGameLoaded()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akActorRef)
  UpdateVars()
  TryToHandleGameLoaded()
EndEvent

Event OnTimer(Int aiTimerID)
  If aiTimerID == iTimerID_WaitForSS2Main
    TryToHandleGameLoaded()
  EndIf
EndEvent

Event OnTimerGameTime(Int aiTimerID)
  If aiTimerID == iTimerID_JobTraining
    If bEnabled
      UpdateAllSettlements()
    Else
      fLastUpdateTime = Utility.GetCurrentGameTime()
    EndIf
    StartTimerGameTime(fUpdateIntervalHours, iTimerID_JobTraining)
  EndIf
EndEvent

;-- Functions ---------------------------------------

Function UpdateVars()
  If SS2Main == None
    SS2Main = Game.GetFormFromFile(iFormID_SS2Main, sSS2Plugin) as Quest
  EndIf
  If RPGManager == None
    RPGManager = Game.GetFormFromFile(iFormID_SS2_NPC_RPGManager, sSS2Plugin) as SimSettlementsV2:Quests:NPC_RPGManager
  EndIf
  If PlayerRef == None
    PlayerRef = Game.GetFormFromFile(iFormID_PlayerRef, sFallout4Plugin) as Actor
  EndIf
EndFunction

; Don't start until SS2 has finished starting its own quests (new games, or SS2 installed mid-save)
Function TryToHandleGameLoaded()
  If SS2Main == None || !SS2Main.IsRunning()
    StartTimer(fWaitForSS2MainSeconds, iTimerID_WaitForSS2Main)
  Else
    HandleGameLoaded()
  EndIf
EndFunction

Function HandleGameLoaded()
  Debug.OpenUserLog(sLogName)

  If iInstalledVersion < iModVersion
    If iInstalledVersion > 0
      InstallModChanges()
    EndIf
    iInstalledVersion = iModVersion
  EndIf

  ; Game-time timers persist in the save, so this only needs to happen once
  If !bTrainingTimerStarted
    bTrainingTimerStarted = True
    ; No retroactive credit for time before the mod was running
    fLastUpdateTime = Utility.GetCurrentGameTime()
    StartTimerGameTime(fUpdateIntervalHours, iTimerID_JobTraining)
    Log("Started; first update in " + fUpdateIntervalHours + " game hours.")
  EndIf
EndFunction

; Migration hook for saves made with an older version. Auto property values are stored in the save,
; so changed defaults (e.g. fJobTrainingRate) must be re-applied here if a release changes them.
Function InstallModChanges()
  Log("Upgrading from version " + iInstalledVersion + " to " + iModVersion)
EndFunction

Function UpdateAllSettlements()
  If bUpdateInProgress
    Return
  EndIf

  If RPGManager == None || !RPGManager.IsRunning()
    Log("SS2 NPC_RPGManager not available yet, skipping update.")
    Return
  EndIf

  bUpdateInProgress = True

  Float fNow = Utility.GetCurrentGameTime()
  Float fElapsedDays = Math.Min(fNow - fLastUpdateTime, fMaxCatchUpDays)
  fLastUpdateTime = fNow

  If fElapsedDays > 0.0
    Float fTrainingDays = fElapsedDays * fJobTrainingRate
    Log("Update: " + fElapsedDays + " days elapsed, granting " + fTrainingDays + " training days per job.")

    WorkshopScript[] kWorkshopRefs = RPGManager.WorkshopParent.Workshops
    Int i = 0
    While i < kWorkshopRefs.Length
      If kWorkshopRefs[i] != None && kWorkshopRefs[i].OwnedByPlayer
        UpdateSettlement(kWorkshopRefs[i], fTrainingDays)
      EndIf
      i += 1
    EndWhile
  EndIf

  bUpdateInProgress = False
EndFunction

Function UpdateSettlement(WorkshopScript akWorkshopRef, Float afTrainingDays)
  Actor[] kSettlerRefs = RPGManager.GetSettlers(akWorkshopRef, True)
  Int i = 0
  While i < kSettlerRefs.Length
    Actor kSettlerRef = kSettlerRefs[i]
    If kSettlerRef != None && !kSettlerRef.IsDead() && kSettlerRef.HasKeyword(RPGManager.AssignmentType_Job)
      TrainSettlerFromJob(kSettlerRef, akWorkshopRef, afTrainingDays)
    EndIf
    i += 1
  EndWhile
EndFunction

Function TrainSettlerFromJob(Actor akActorRef, WorkshopScript akWorkshopRef, Float afTrainingDays)
  ActorValue[] JobStats = GetJobStats(akActorRef, akWorkshopRef)
  If JobStats.Length == 0
    Return
  EndIf

  SimSettlementsV2:DataStructures:StatTraining[] TrainingMaps = RPGManager.TrainingMaps
  Bool bProgressAdded = False
  Int i = 0
  While i < JobStats.Length
    Int iTrainingIndex = TrainingMaps.FindStruct("StatAV", JobStats[i])
    Float fBaseValue = akActorRef.GetBaseValue(JobStats[i])
    ; Base value 0 means SS2 hasn't rolled this settler's stats yet; SS2 won't train those either
    If iTrainingIndex >= 0 && fBaseValue > 0.0 && fBaseValue < RPGManager.iMaxStatValue as Float
      ActorValue ProgressAV = TrainingMaps[iTrainingIndex].TrainingProgressAV
      Float fProgress = akActorRef.GetValue(ProgressAV)
      If fProgress == 0.0
        ; Progress is cumulative days; start from the current level's threshold like SS2's StartTraining does
        fProgress = RPGManager.GetStatTrainingTimeNeeded(fBaseValue as Int, akWorkshopRef)
      EndIf
      akActorRef.SetValue(ProgressAV, fProgress + afTrainingDays)
      bProgressAdded = True
      Log("  " + akActorRef + " " + JobStats[i] + " (" + fBaseValue + ") progress " + fProgress + " -> " + (fProgress + afTrainingDays))
    EndIf
    i += 1
  EndWhile

  If bProgressAdded && RPGManager.ProcessTraining(akActorRef, False)
    Log("  " + akActorRef + " improved a stat through work.")
    RPGManager.UpdateSettlerPlotBonuses(akActorRef)
  EndIf
EndFunction

ActorValue[] Function GetJobStats(Actor akActorRef, WorkshopScript akWorkshopRef)
  ActorValue[] JobStats = new ActorValue[0]
  SimSettlementsV2:DataStructures:PlotSpecialStatAdjustment[] StatAdjustments = RPGManager.PlotManager.PlotSpecialStatAdjustments

  ObjectReference[] kOwnedRefs = akWorkshopRef.GetWorkshopOwnedObjects(akActorRef)
  Int i = 0
  While i < kOwnedRefs.Length
    SimSettlementsV2:ObjectReferences:SimPlot asPlot = kOwnedRefs[i] as SimSettlementsV2:ObjectReferences:SimPlot
    If asPlot == None
      asPlot = SimSettlementsV2:UtilityFunctions.GetLinkedPlot(kOwnedRefs[i], RPGManager.SecondaryAssignmentMarkerLinkKeyword)
    EndIf

    If asPlot != None && IsJobPlot(asPlot)
      SimSettlementsV2:Weapons:BuildingPlan thisPlan = asPlot.GetParentBuildingPlan()
      If thisPlan != None && thisPlan.ClassKeyword != None
        Int j = 0
        While j < StatAdjustments.Length
          If StatAdjustments[j].BuildingClassKeyword == thisPlan.ClassKeyword && StatAdjustments[j].SpecialStatAV != None && JobStats.Find(StatAdjustments[j].SpecialStatAV) < 0
            JobStats.Add(StatAdjustments[j].SpecialStatAV)
          EndIf
          j += 1
        EndWhile
      EndIf
    EndIf
    i += 1
  EndWhile

  Return JobStats
EndFunction

Bool Function IsJobPlot(SimSettlementsV2:ObjectReferences:SimPlot akPlot)
  SimSettlementsV2:MiscObjects:PlotConfiguration thisPlotConfig = akPlot.GetPlotConfig()
  Return thisPlotConfig != None && thisPlotConfig.AssignmentTypeKeywords != None && thisPlotConfig.AssignmentTypeKeywords.Find(RPGManager.AssignmentType_Job) >= 0
EndFunction

Function Log(String asMessage)
  If bDebugLogging
    Debug.TraceUser(sLogName, asMessage)
  EndIf
EndFunction
