#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "AtlasPlayerCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;

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

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Prototype Visual")
    TObjectPtr<UStaticMeshComponent> BodyVisual;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Prototype Visual")
    TObjectPtr<UStaticMeshComponent> HeadVisual;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void TurnCamera(float Value);
    void LookCamera(float Value);

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
};
