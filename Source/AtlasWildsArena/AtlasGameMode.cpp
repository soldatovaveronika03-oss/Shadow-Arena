#include "AtlasGameMode.h"
#include "Characters/AtlasPlayerCharacter.h"
#include "World/AtlasWorldGenerator.h"
#include "Engine/World.h"
#include "GameFramework/PlayerStart.h"

AAtlasGameMode::AAtlasGameMode()
{
    DefaultPawnClass = AAtlasPlayerCharacter::StaticClass();
}

void AAtlasGameMode::BeginPlay()
{
    Super::BeginPlay();
    if (UWorld* World = GetWorld())
    {
        FActorSpawnParameters Params;
        Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
        World->SpawnActor<AAtlasWorldGenerator>(AAtlasWorldGenerator::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, Params);
        if (World->GetAuthGameMode() == this)
        {
            World->SpawnActor<APlayerStart>(APlayerStart::StaticClass(), FVector(0, 0, 180), FRotator::ZeroRotator, Params);
        }
    }
}
