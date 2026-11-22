using UnrealBuildTool;

public class AtlasWildsArena : ModuleRules
{
    public AtlasWildsArena(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new string[]
        {
            "Core", "CoreUObject", "Engine", "InputCore", "EnhancedInput", "UMG",
            "ProceduralMeshComponent"
        });
    }
}