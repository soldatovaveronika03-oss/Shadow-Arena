#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "ShadowArenaGameMode.generated.h"

UCLASS()
class SHADOWARENA_API AShadowArenaGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    AShadowArenaGameMode();
    virtual void BeginPlay() override;
};