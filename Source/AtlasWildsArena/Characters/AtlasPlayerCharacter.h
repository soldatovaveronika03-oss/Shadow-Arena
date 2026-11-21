#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "AtlasPlayerCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;

UCLASS()
class ATLASWILDSARENA_API AAtlasPlayerCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AAtlasPlayerCharacter();

protected:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
};
