ScriptName SimSettlementsV2:DataStructures Extends ScriptObject Const
{ COMPILE STUB ONLY - do not ship. Mirrors the structs used from SS2 3.8.0. }

Struct StatTraining
  ActorValue TrainingTimestampAV
  Keyword BuildingPlanClassKeyword
  ActorValue TrainingProgressAV
  Keyword IsTrainingKeyword
  ActorValue StatAV
EndStruct

Struct PlotSpecialStatAdjustment
  ActorValue ResourceAV
  ActorValue SpecialStatAV
  Float fStatToResourceConversionMultiplier = 1.0
  Int iVirtualResourceHandling = 0
  Keyword BuildingClassKeyword
EndStruct
