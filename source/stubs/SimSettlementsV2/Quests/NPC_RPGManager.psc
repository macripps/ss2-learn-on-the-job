ScriptName SimSettlementsV2:Quests:NPC_RPGManager Extends Quest
{ COMPILE STUB ONLY - do not ship. Members used by SS2LearnOnTheJob, signatures from SS2 3.8.0. }

WorkshopParentScript Property WorkshopParent Auto Const
SimSettlementsV2:Quests:PlotManager Property PlotManager Auto Const
Keyword Property AssignmentType_Job Auto Const
Keyword Property WorkshopItemKeyword Auto Const
Keyword Property SecondaryAssignmentMarkerLinkKeyword Auto Const
SimSettlementsV2:DataStructures:StatTraining[] Property TrainingMaps Auto Const
Int Property iMaxStatValue = 10 AutoReadOnly

Actor[] Function GetSettlers(WorkshopScript akWorkshopRef, Bool abIncludePermanent)
EndFunction

Float Function GetStatTrainingTimeNeeded(Int aiTargetStatValue, WorkshopScript akWorkshopRef)
EndFunction

Bool Function ProcessTraining(Actor akActorRef, Bool abCalledFromStopTraining)
EndFunction

Function UpdateSettlerPlotBonuses(Actor akActorRef)
EndFunction
