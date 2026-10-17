ScriptName AISS2LearnOnTheJob:JobTrainingQuest Extends Quest
{ A simple quest that gives Settlers on-the-job experience every 24 hours. }

Bool Property bLoggingEnabled = False Auto

Bool bUpdateInProcess = False

String sLogName = "LearningOnTheJob"

Int Property iInstalledVersion = 0 Auto hidden

Int iTimerID_Recalculate = 102 Const
Int iTimerID_Registration = 101 Const
Int iTimerID_WaitForSS2Main = 100 Const

SimSettlementsV2:Quests:SS2Main Property SS2Main Auto hidden
SimSettlementsV2:Quests:NPC_RPGManager Property SS2RPGManager Auto Hidden
{ Access to the NPC RPG Manager for training purposes }

Event OnQuestInit()
  Debug.OpenUserLog(sLogName)
  Log("LearningOnTheJob init")
  Self.UpdateVars()
  If SS2Main.IsRunning()
    Self.HandleGameLoaded()
  Else
    Self.RegisterForRemoteEvent(SS2Main as ScriptObject, "OnQuestInit")
  EndIf
EndEvent

Event Quest.OnQuestInit(Quest akSenderRef)
  If akSenderRef == SS2Main as Quest
    Self.TryToHandleGameLoaded()
    Self.UnregisterForRemoteEvent(akSenderRef as ScriptObject, "OnQuestInit")
  EndIf
EndEvent

Function TryToHandleGameLoaded()
  If !SS2Main.IsRunning()
    Self.StartTimer(2.0, iTimerID_WaitForSS2Main)
  Else
    Self.HandleGameLoaded()
  EndIf
EndFunction

Function HandleGameLoaded()
  If iInstalledVersion < SS2CurrentVersion.GetValueInt()
    If iInstalledVersion > 0
      Self.InstallModChanges()
    Else
      iInstalledVersion = SS2CurrentVersion.GetValueInt()
    EndIf
  EndIf
EndFunction

Function InstallModChanges()
  iInstalledVersion = SS2CurrentVersion.GetValueInt()
EndFunction

Event OnTimer(Int aiTimerID)
  If aiTimerID == iTimerID_WaitForSS2Main
    Self.TryToHandleGameLoaded()
  ElseIf aiTimerID == iTimerID_Recalculate
    Self.HandleRecalculation()
  EndIf
EndEvent

Function HandleRecalculation()
    ; Set timer for update
EndFunction

Function Log(String evt)
EndFunction