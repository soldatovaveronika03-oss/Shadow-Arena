#include "World/AtlasWorldGenerator.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"

AAtlasWorldGenerator::AAtlasWorldGenerator()
{
    PrimaryActorTick.bCanEverTick = false;
    Ground = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Ground"));
    SetRootComponent(Ground);
    River = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("River"));
    River->SetupAttachment(RootComponent);
    TreeTrunks = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("TreeTrunks"));
    TreeTrunks->SetupAttachment(RootComponent);
    TreeCrowns = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("TreeCrowns"));
    TreeCrowns->SetupAttachment(RootComponent);
    Rocks = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("Rocks"));
    Rocks->SetupAttachment(RootComponent);
    Hills = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("Hills"));
    Hills->SetupAttachment(RootComponent);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> PlaneMesh(TEXT("/Engine/BasicShapes/Plane.Plane"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeMesh(TEXT("/Engine/BasicShapes/Cone.Cone"));

    if (PlaneMesh.Succeeded())
    {
        Ground->SetStaticMesh(PlaneMesh.Object);
        River->SetStaticMesh(PlaneMesh.Object);
    }
    if (CubeMesh.Succeeded())
    {
        TreeTrunks->SetStaticMesh(CubeMesh.Object);
        Rocks->SetStaticMesh(CubeMesh.Object);
    }
    if (ConeMesh.Succeeded()) TreeCrowns->SetStaticMesh(ConeMesh.Object);
    if (SphereMesh.Succeeded()) Hills->SetStaticMesh(SphereMesh.Object);
    Ground->SetRelativeLocation(FVector(0, 0, -80));
    Ground->SetRelativeScale3D(FVector(600, 600, 1));
    River->SetRelativeLocation(FVector(0, 1100, -72));
    River->SetRelativeRotation(FRotator(0, 0, 18));
    River->SetRelativeScale3D(FVector(3.5f, 300, 1));
}

void AAtlasWorldGenerator::OnConstruction(const FTransform& Transform)
{
    Super::OnConstruction(Transform);
    BuildWorld();
}

void AAtlasWorldGenerator::BuildWorld()
{
    TreeTrunks->ClearInstances();
    TreeCrowns->ClearInstances();
    Rocks->ClearInstances();
    Hills->ClearInstances();

    FRandomStream Random(20261122);
    for (int32 X = -18; X <= 18; ++X)
    {
        for (int32 Y = -18; Y <= 18; ++Y)
        {
            const float JitterX = Random.FRandRange(-260, 260);
            const float JitterY = Random.FRandRange(-260, 260);
            const FVector P(X * 1500.f + JitterX, Y * 1500.f + JitterY, -65.f);
            const float DistanceFromTrail = FMath::Abs(P.Y - P.X * 0.12f);
            if (DistanceFromTrail < 950.f || FMath::Abs(P.Y - 1100.f) < 520.f) continue;

            if (Random.FRand() < 0.38f)
            {
                const float H = Random.FRandRange(250.f, 520.f);
                TreeTrunks->AddInstance(FTransform(FRotator(0, Random.FRandRange(0, 360), 0), P + FVector(0,0,H*0.5f), FVector(0.8f,0.8f,H/100.f)));
                TreeCrowns->AddInstance(FTransform(FRotator(0, Random.FRandRange(0, 360), 0), P + FVector(0,0,H+100.f), FVector(Random.FRandRange(1.8f,2.8f),Random.FRandRange(1.8f,2.8f),Random.FRandRange(2.5f,3.8f))));
            }
            if (Random.FRand() < 0.08f)
            {
                const float S = Random.FRandRange(100.f, 300.f);
                Rocks->AddInstance(FTransform(FRotator(Random.FRandRange(-12,12), Random.FRandRange(0,360), Random.FRandRange(-12,12)), P + FVector(0,0,S*0.25f), FVector(S/100.f, S/100.f, S/100.f)));
            }
        }
    }

    for (int32 I = 0; I < 22; ++I)
    {
        const float X = Random.FRandRange(-24000.f, 24000.f);
        const float Y = Random.FRandRange(-24000.f, 24000.f);
        const float S = Random.FRandRange(9.f, 24.f);
        Hills->AddInstance(FTransform(FRotator(0,0,0), FVector(X,Y,-120.f), FVector(S,S,S*0.55f)));
    }
}
