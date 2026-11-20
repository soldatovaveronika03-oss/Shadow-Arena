using UnrealBuildTool;
public class ShadowArena : ModuleRules {
 public ShadowArena(ReadOnlyTargetRules Target) : base(Target) {
  PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
  PublicDependencyModuleNames.AddRange(new string[] { "Core", "CoreUObject", "Engine", "InputCore" });
 }
}