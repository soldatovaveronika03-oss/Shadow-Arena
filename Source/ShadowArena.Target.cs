using UnrealBuildTool;
using System.Collections.Generic;
public class ShadowArenaTarget : TargetRules {
 public ShadowArenaTarget(TargetInfo Target) : base(Target) {
  Type = TargetType.Game;
  DefaultBuildSettings = BuildSettingsVersion.V5;
  IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
  ExtraModuleNames.Add("ShadowArena");
 }
}