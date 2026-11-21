#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "AtlasGameMode.generated.h"

UCLASS()
class ATLASWILDSARENA_API AAtlasGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    AAtlasGameMode();
    virtual void BeginPlay() override;
};
