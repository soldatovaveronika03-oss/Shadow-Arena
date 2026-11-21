#include "Characters/AtlasPlayerCharacter.h"
#include "Camera/CameraComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/InputComponent.h"
#include "UObject/ConstructorHelpers.h"

AAtlasPlayerCharacter::AAtlasPlayerCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 420.0f;
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->SetRelativeLocation(FVector(0.0f, 0.0f, 70.0f));

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereMesh.Succeeded())
    {
        BodyVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyVisual"));
        BodyVisual->SetupAttachment(GetCapsuleComponent());
        BodyVisual->SetStaticMesh(SphereMesh.Object);
        BodyVisual->SetRelativeLocation(FVector(0, 0, -12));
        BodyVisual->SetRelativeScale3D(FVector(0.62f, 0.42f, 0.92f));
        BodyVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);

        HeadVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("HeadVisual"));
        HeadVisual->SetupAttachment(GetCapsuleComponent());
        HeadVisual->SetStaticMesh(SphereMesh.Object);
        HeadVisual->SetRelativeLocation(FVector(0, 0, 82));
        HeadVisual->SetRelativeScale3D(FVector(0.34f, 0.34f, 0.38f));
        HeadVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }

    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 540.0f, 0.0f);
    GetCharacterMovement()->MaxWalkSpeed = 500.0f;
    GetCharacterMovement()->JumpZVelocity = 600.0f;
    GetCharacterMovement()->AirControl = 0.25f;
}

void AAtlasPlayerCharacter::MoveForward(float Value)
{
    if (Controller && FMath::Abs(Value) > KINDA_SMALL_NUMBER)
    {
        const FRotator YawRotation(0, Controller->GetControlRotation().Yaw, 0);
        AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
    }
}

void AAtlasPlayerCharacter::MoveRight(float Value)
{
    if (Controller && FMath::Abs(Value) > KINDA_SMALL_NUMBER)
    {
        const FRotator YawRotation(0, Controller->GetControlRotation().Yaw, 0);
        AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
    }
}

void AAtlasPlayerCharacter::TurnCamera(float Value)
{
    AddControllerYawInput(Value);
}

void AAtlasPlayerCharacter::LookCamera(float Value)
{
    AddControllerPitchInput(Value);
}

void AAtlasPlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    check(PlayerInputComponent);
    PlayerInputComponent->BindAxis("MoveForward", this, &AAtlasPlayerCharacter::MoveForward);
    PlayerInputComponent->BindAxis("MoveRight", this, &AAtlasPlayerCharacter::MoveRight);
    PlayerInputComponent->BindAxis("Turn", this, &AAtlasPlayerCharacter::TurnCamera);
    PlayerInputComponent->BindAxis("TurnRate", this, &AAtlasPlayerCharacter::TurnCamera);
    PlayerInputComponent->BindAxis("LookUp", this, &AAtlasPlayerCharacter::LookCamera);
    PlayerInputComponent->BindAxis("LookUpRate", this, &AAtlasPlayerCharacter::LookCamera);
    PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
    PlayerInputComponent->BindAction("Jump", IE_Released, this, &ACharacter::StopJumping);
}
