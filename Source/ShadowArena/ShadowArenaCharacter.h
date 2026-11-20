#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "ShadowArenaCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;

UCLASS()
class SHADOWARENA_API AShadowArenaCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AShadowArenaCharacter();

protected:
    virtual void BeginPlay() override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void Attack();
    void ResetAttack();

    UPROPERTY(VisibleAnywhere, Category="Camera")
    USpringArmComponent* CameraBoom;

    UPROPERTY(VisibleAnywhere, Category="Camera")
    UCameraComponent* FollowCamera;

    UPROPERTY(VisibleAnywhere, Category="Visual")
    UStaticMeshComponent* BodyVisual;

    UPROPERTY(VisibleAnywhere, Category="Visual")
    UStaticMeshComponent* HeadVisual;

    UPROPERTY(VisibleAnywhere, Category="Visual")
    UStaticMeshComponent* WeaponVisual;

    bool bCanAttack = true;
    FTimerHandle AttackCooldownHandle;
};