#include "ShadowArenaCharacter.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "DrawDebugHelpers.h"
#include "TimerManager.h"
#include "GameFramework/PlayerController.h"

AShadowArenaCharacter::AShadowArenaCharacter()
{
    PrimaryActorTick.bCanEverTick = false;
    GetCapsuleComponent()->InitCapsuleSize(42.0f, 96.0f);

    bUseControllerRotationPitch = false;
    bUseControllerRotationYaw = false;
    bUseControllerRotationRoll = false;

    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 540.0f, 0.0f);
    GetCharacterMovement()->JumpZVelocity = 520.0f;
    GetCharacterMovement()->AirControl = 0.30f;
    GetCharacterMovement()->MaxWalkSpeed = 520.0f;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 520.0f;
    CameraBoom->SetRelativeRotation(FRotator(-18.0f, 0.0f, 0.0f));
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 8.0f;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    BodyVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyVisual"));
    BodyVisual->SetupAttachment(RootComponent);
    BodyVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 0.0f));
    BodyVisual->SetRelativeScale3D(FVector(0.55f, 0.42f, 0.85f));
    BodyVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    HeadVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("HeadVisual"));
    HeadVisual->SetupAttachment(RootComponent);
    HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 78.0f));
    HeadVisual->SetRelativeScale3D(FVector(0.32f));
    HeadVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    WeaponVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WeaponVisual"));
    WeaponVisual->SetupAttachment(RootComponent);
    WeaponVisual->SetRelativeLocation(FVector(48.0f, 28.0f, 24.0f));
    WeaponVisual->SetRelativeRotation(FRotator(0.0f, 0.0f, -25.0f));
    WeaponVisual->SetRelativeScale3D(FVector(0.12f, 0.12f, 0.85f));
    WeaponVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void AShadowArenaCharacter::BeginPlay()
{
    Super::BeginPlay();

    UStaticMesh* Cube = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Sphere = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (Cube)
    {
        BodyVisual->SetStaticMesh(Cube);
        WeaponVisual->SetStaticMesh(Cube);
    }
    if (Sphere)
    {
        HeadVisual->SetStaticMesh(Sphere);
    }
}

void AShadowArenaCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AShadowArenaCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AShadowArenaCharacter::MoveRight);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Pressed, this, &ACharacter::Jump);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Released, this, &ACharacter::StopJumping);
    PlayerInputComponent->BindAction(TEXT("Attack"), IE_Pressed, this, &AShadowArenaCharacter::Attack);
}

void AShadowArenaCharacter::MoveForward(float Value)
{
    if (Controller && FMath::Abs(Value) > KINDA_SMALL_NUMBER)
    {
        const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
        AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
    }
}

void AShadowArenaCharacter::MoveRight(float Value)
{
    if (Controller && FMath::Abs(Value) > KINDA_SMALL_NUMBER)
    {
        const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
        AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
    }
}

void AShadowArenaCharacter::Attack()
{
    if (!bCanAttack || !FollowCamera || !GetWorld()) return;
    bCanAttack = false;

    const FVector Start = FollowCamera->GetComponentLocation();
    const FVector End = Start + FollowCamera->GetForwardVector() * 280.0f;
    FHitResult Hit;
    FCollisionQueryParams Params(SCENE_QUERY_STAT(ShadowArenaAttack), false, this);
    GetWorld()->LineTraceSingleByChannel(Hit, Start, End, ECC_Pawn, Params);
    DrawDebugLine(GetWorld(), Start, End, FColor::Orange, false, 0.18f, 0, 3.0f);

    GetWorldTimerManager().SetTimer(AttackCooldownHandle, this, &AShadowArenaCharacter::ResetAttack, 0.55f, false);
}

void AShadowArenaCharacter::ResetAttack()
{
    bCanAttack = true;
}