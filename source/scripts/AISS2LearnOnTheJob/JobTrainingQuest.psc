ScriptName AISS2LearnOnTheJob:JobTrainingQuest Extends Quest
{ A simple quest that gives Settlers on-the-job experience every 24 hours. }

Bool Property bLoggingEnabled = False Auto
Float Property fDailyProgress = 0.25 Auto
Int Property iMaxLevel = 10 Auto
Int Property iInstalledVersion = 0 Auto hidden

Bool bUpdateInProcess = False
String sLogName = "LearningOnTheJob"
Int iMyVersion = 1 Const
Int iTimerID_Recalculate = 102 Const

Event OnQuestInit()
  InstallModChanges()
  StartTimerGameTime(24, iTimerID_Recalculate)
  RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
  Log("LearningOnTheJob init")
  if iMyVersion > iInstalledVersion
    InstallModChanges()
  EndIf
EndEvent

Function InstallModChanges()
  Log("Updating LearnOnTheJob to version " + iMyVersion)
  iInstalledVersion = iMyVersion
  bUpdateInProcess = False
EndFunction

Event OnTimerGameTime(Int aiTimerID)
  If aiTimerID == iTimerID_Recalculate
    Self.HandleRecalculation()
  EndIf
EndEvent

Function HandleRecalculation()
  ; Re-set timer for update
  StartTimerGameTime(24, iTimerID_Recalculate)
  Log("Tick Started")
  SimSettlementsV2:Quests:NPC_RPGManager SS2RPGManager = Game.GetFormFromFile(0x00EB6E, "SS2.esm") as SimSettlementsV2:Quests:NPC_RPGManager
  If SS2RPGManager == None
    Log("Unable to find SS2 RPG Manager")
    return
  EndIf
  If ! SS2RPGManager.IsRunning()
    Log("SS2 RPG Manager is not running")
    return
  EndIf
  If bUpdateInProcess
    Log("Update already in process")
    return
  EndIf
  ; SS2 is Ready
  bUpdateInProcess = True
  Keyword linkKeyword = SS2RPGManager.SecondaryAssignmentMarkerLinkKeyword
  Keyword jobAssignmentKeyword = SS2RPGManager.AssignmentType_Job
  SimSettlementsV2:Quests:PlotManager SS2PlotManager = SS2RPGManager.PlotManager
  WorkshopParentScript workshopParent = SS2RPGManager.WorkshopParent
  WorkshopScript[] allWorkshops = workshopParent.Workshops
  ; Fetch Plot Class -> Special
  SimSettlementsV2:DataStructures:PlotSpecialStatAdjustment[] PlotSpecialStatAdjustments = SS2PlotManager.PlotSpecialStatAdjustments
  ; Fetch TrainingMaps
  SimSettlementsV2:DataStructures:StatTraining[] statTraining = SS2RPGManager.TrainingMaps
  ; Loop over all settlements
  int currentWorkshop = 0
  While currentWorkshop < allWorkshops.Length
    HandleWorkshop(allWorkshops[currentWorkshop], SS2RPGManager, linkKeyword, jobAssignmentKeyword, PlotSpecialStatAdjustments, statTraining)
    currentWorkshop += 1
  EndWhile
  Log("Tick Finished")
  bUpdateInProcess = False
EndFunction

Int Settler_Updated = 1 Const
Int Settler_ReachedCap = 0 Const
Int Settler_NoJob = -1 Const
Int Settler_JobUnknown = -3 Const

Function HandleWorkshop(WorkshopScript akCurrentWorkshop, SimSettlementsV2:Quests:NPC_RPGManager akSS2RPGManager, Keyword akLinkKeyword, Keyword akJobAssignmentKeyword, SimSettlementsV2:DataStructures:PlotSpecialStatAdjustment[] akPlotSpecialStatAdjustments, SimSettlementsV2:DataStructures:StatTraining[] akStatTraining)
  Actor[] allSettlers = akSS2RPGManager.GetSettlers(akCurrentWorkshop, True)
  if allSettlers.Length == 0
    Return
  EndIf

  Log("Started Workshop " + akCurrentWorkshop + " - " + allSettlers.Length + " settlers.")
  Float maxProgress = akSS2RPGManager.GetStatTrainingTimeNeeded(iMaxLevel, akCurrentWorkshop)

  int currentSettler = 0
  Int settlersUpdated = 0
  int settlersNoJob = 0
  int settlersJobUnknown = 0
  int settlersReachedCap = 0
  ; loop over all settlers in settlement
  While currentSettler < allSettlers.Length
    Int settlerHandled = HandleSettler(allSettlers[currentSettler], akCurrentWorkshop, akSS2RPGManager, akLinkKeyword, akJobAssignmentKeyword, akPlotSpecialStatAdjustments, akStatTraining, maxProgress)
    If settlerHandled == Settler_NoJob
      settlersNoJob += 1
    ElseIf settlerHandled == Settler_JobUnknown
      settlersJobUnknown += 1
    ElseIf settlerHandled == Settler_ReachedCap
      settlersReachedCap += 1
    ElseIf settlerHandled == Settler_Updated
      settlersUpdated += 1
    Else
      ; Can't happen today, don't lie about stats if it does
    EndIf
    currentSettler += 1
  EndWhile
  Log("Finished Workshop " + akCurrentWorkshop.GetFormID() + " (" + settlersUpdated + " updated/" + settlersNoJob + " no job/" + settlersJobUnknown + " unknown job/" + settlersReachedCap + " at max level)")
EndFunction

Int Function HandleSettler(Actor akSettler, WorkshopScript akCurrentWorkshop, SimSettlementsV2:Quests:NPC_RPGManager akSS2RPGManager, Keyword akLinkKeyword, Keyword akJobAssignmentKeyword, SimSettlementsV2:DataStructures:PlotSpecialStatAdjustment[] akPlotSpecialStatAdjustments, SimSettlementsV2:DataStructures:StatTraining[] akStatTraining, Float maxProgress)
  ; find settler's current JOB assignment (can be none)
  SimSettlementsV2:ObjectReferences:SimPlot jobPlot = FindSettlerJobPlot(akCurrentWorkshop, akSettler, akLinkKeyword, akJobAssignmentKeyword)
  If jobPlot == None
    Return Settler_NoJob
  EndIf
  ; if not none, find SPECIAL corresponding to JOB
  SimSettlementsV2:DataStructures:StatTraining trainingProgress = FindTrainingProgress(jobPlot, akPlotSpecialStatAdjustments, akStatTraining)
  If trainingProgress == None
    Return Settler_JobUnknown
  EndIf
  ActorValue statAV = trainingProgress.StatAV
  ActorValue tpAV = trainingProgress.TrainingProgressAV
  ; apply progress to Settler's training progress for that SPECIAL
  float progressValue = akSettler.GetValue(tpAV)
  If progressValue == 0
    float statValue = akSettler.GetBaseValue(statAV)
    progressValue = akSS2RPGManager.GetStatTrainingTimeNeeded(statValue as int, akCurrentWorkshop)
  EndIf
  ; Compare to max
  If progressValue >= maxProgress
    Return Settler_ReachedCap
  EndIf
  ; Increase progressValue and setValue
  progressValue += fDailyProgress
  akSettler.SetValue(tpAV, progressValue)
  Return Settler_Updated
EndFunction

SimSettlementsV2:ObjectReferences:SimPlot Function FindSettlerJobPlot(WorkshopScript akWorkshop, Actor akSettler, Keyword akLinkKeyword, Keyword akJobAssignmentKeyword)
  ; Find the Job Plot assigned to this settler - assume they can only have one
  ObjectReference[] allObjects = akWorkshop.GetWorkshopOwnedObjects(akSettler)
  int currentObj = 0
  While currentObj < allObjects.Length
    SimSettlementsV2:ObjectReferences:SimPlot maybePlot = allObjects[currentObj] as SimSettlementsV2:ObjectReferences:SimPlot
    If !maybePlot
      maybePlot = SimSettlementsV2:UtilityFunctions.GetLinkedPlot(allObjects[currentObj], akLinkKeyword)
    EndIf
    If maybePlot != None
      SimSettlementsV2:MiscObjects:PlotConfiguration plotConfig = maybePlot.GetPlotConfig()
      If plotConfig != None && plotConfig.AssignmentTypeKeywords.Find(akJobAssignmentKeyword) != -1
        return maybePlot
      EndIf
    EndIf
    currentObj += 1
  EndWhile
  return None
EndFunction

SimSettlementsV2:DataStructures:StatTraining Function FindTrainingProgress(SimSettlementsV2:ObjectReferences:SimPlot jobPlot, SimSettlementsV2:DataStructures:PlotSpecialStatAdjustment[] akPlotSpecialStatAdjustments, SimSettlementsV2:DataStructures:StatTraining[] akStatTraining)
  SimSettlementsV2:Weapons:BuildingPlan buildingPlan = jobPlot.GetParentBuildingPlan()
  If buildingPlan == None
    return None
  EndIf
  Keyword classKeyword = buildingPlan.ClassKeyword
  if classKeyword == None
    return None
  EndIf
  int statIdx = akPlotSpecialStatAdjustments.FindStruct("BuildingClassKeyword", classKeyword)
  If statIdx == -1
    Log("Unable to find ClassKeyword " + classKeyword + " on " + jobPlot)
    return None
  EndIf
  ActorValue SpecialStatAV = akPlotSpecialStatAdjustments[statIdx].SpecialStatAV
  int trainingIdx = akStatTraining.FindStruct("StatAV", SpecialStatAV)
  If trainingIdx == -1
    return None
  EndIf
  return akStatTraining[trainingIdx]
EndFunction

bool Function Log(String evt)
  if (bLoggingEnabled)
    Debug.OpenUserLog(sLogName)
    return Debug.TraceUser(sLogName, Utility.GetCurrentRealTime() + "/" + Utility.GetCurrentGameTime() + ": " + evt)
  EndIf
  return false
EndFunction