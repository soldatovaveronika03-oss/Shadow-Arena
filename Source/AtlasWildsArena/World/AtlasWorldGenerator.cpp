#include "World/AtlasWorldGenerator.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "ProceduralMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInterface.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    constexpr int32 TerrainQuads = 128;
    constexpr float WorldHalfSize = 40000.0f;
    constexpr float TerrainCell = (WorldHalfSize * 2.0f) / TerrainQuads;

    UMaterialInstanceDynamic* MakeTintedMaterial(UObject* Outer, const TCHAR* AssetPath, const FLinearColor& Tint)
    {
        static ConstructorHelpers::FObjectFinder<UMaterialInterface> ShapeMaterial(
            TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if (!ShapeMaterial.Succeeded()) return nullptr;
        UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(ShapeMaterial.Object, Outer);
        if (Material) Material->SetVectorParameterValue(TEXT("Color"), Tint);
        return Material;
    }
}

AAtlasWorldGenerator::AAtlasWorldGenerator()
{
    PrimaryActorTick.bCanEverTick = false;

    Terrain = CreateDefaultSubobject<UProceduralMeshComponent>(TEXT("Terrain"));
    SetRootComponent(Terrain);
    Terrain->SetMobility(EComponentMobility::Static);
    Terrain->bUseAsyncCooking = true;

    River = CreateDefaultSubobject<UProceduralMeshComponent>(TEXT("River"));
    River->SetupAttachment(RootComponent);
    River->SetMobility(EComponentMobility::Static);
    River->bUseAsyncCooking = true;

    TreeTrunks = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("TreeTrunks"));
    TreeTrunks->SetupAttachment(RootComponent);
    TreeCrowns = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("TreeCrowns"));
    TreeCrowns->SetupAttachment(RootComponent);
    Rocks = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("Rocks"));
    Rocks->SetupAttachment(RootComponent);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeMesh(TEXT("/Engine/BasicShapes/Cone.Cone"));

    if (CubeMesh.Succeeded())
    {
        TreeTrunks->SetStaticMesh(CubeMesh.Object);
        Rocks->SetStaticMesh(CubeMesh.Object);
    }
    if (ConeMesh.Succeeded()) TreeCrowns->SetStaticMesh(ConeMesh.Object);

    TreeTrunks->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    TreeTrunks->SetCollisionProfileName(TEXT("BlockAll"));
    Rocks->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    Rocks->SetCollisionProfileName(TEXT("BlockAll"));
    TreeCrowns->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void AAtlasWorldGenerator::OnConstruction(const FTransform& Transform)
{
    Super::OnConstruction(Transform);
    BuildWorld();
}

float AAtlasWorldGenerator::SampleTerrainHeight(float X, float Y) const
{
    const float BroadNoise = FMath::PerlinNoise2D(FVector2D(X * 0.000055f, Y * 0.000055f)) * 420.0f;
    const float DetailNoise = FMath::PerlinNoise2D(FVector2D(X * 0.00022f + 17.0f, Y * 0.00022f - 9.0f)) * 95.0f;

    const float MountainA = 2100.0f * FMath::Exp(-(
        FMath::Square((X + 20500.0f) / 9500.0f) + FMath::Square((Y - 9000.0f) / 12500.0f)));
    const float MountainB = 1650.0f * FMath::Exp(-(
        FMath::Square((X - 22000.0f) / 10500.0f) + FMath::Square((Y + 18000.0f) / 9000.0f)));

    const float RiverCenterX = 9000.0f + FMath::Sin(Y * 0.00011f) * 6500.0f;
    const float RiverDistance = FMath::Abs(X - RiverCenterX);
    const float RiverValley = 620.0f * FMath::Exp(-FMath::Square(RiverDistance / 3600.0f));

    return BroadNoise + DetailNoise + MountainA + MountainB - RiverValley;
}

void AAtlasWorldGenerator::BuildWorld()
{
    if (!Terrain || !River) return;

    Terrain->ClearAllMeshSections();
    River->ClearAllMeshSections();
    TreeTrunks->ClearInstances();
    TreeCrowns->ClearInstances();
    Rocks->ClearInstances();

    TArray<FVector> Vertices;
    TArray<int32> Triangles;
    TArray<FVector> Normals;
    TArray<FVector2D> UVs;
    TArray<FLinearColor> Colors;
    Vertices.Reserve((TerrainQuads + 1) * (TerrainQuads + 1));
    Normals.Init(FVector::ZeroVector, (TerrainQuads + 1) * (TerrainQuads + 1));
    UVs.Reserve((TerrainQuads + 1) * (TerrainQuads + 1));
    Colors.Reserve((TerrainQuads + 1) * (TerrainQuads + 1));

    for (int32 X = 0; X <= TerrainQuads; ++X)
    {
        for (int32 Y = 0; Y <= TerrainQuads; ++Y)
        {
            const float WorldX = -WorldHalfSize + X * TerrainCell;
            const float WorldY = -WorldHalfSize + Y * TerrainCell;
            const float Height = SampleTerrainHeight(WorldX, WorldY);
            Vertices.Add(FVector(WorldX, WorldY, Height));
            UVs.Add(FVector2D(X / 8.0f, Y / 8.0f));

            const float MountainBlend = FMath::Clamp((Height - 500.0f) / 1700.0f, 0.0f, 1.0f);
            const FLinearColor Grass(0.12f, 0.25f, 0.10f, 1.0f);
            const FLinearColor Stone(0.34f, 0.33f, 0.30f, 1.0f);
            Colors.Add(FLinearColor::LerpUsingHSV(Grass, Stone, MountainBlend));
        }
    }

    for (int32 X = 0; X < TerrainQuads; ++X)
    {
        for (int32 Y = 0; Y < TerrainQuads; ++Y)
        {
            const int32 A = X * (TerrainQuads + 1) + Y;
            const int32 B = (X + 1) * (TerrainQuads + 1) + Y;
            const int32 C = A + 1;
            const int32 D = B + 1;
            Triangles.Append({A, B, C, B, D, C});

            const FVector N1 = FVector::CrossProduct(Vertices[B] - Vertices[A], Vertices[C] - Vertices[A]);
            const FVector N2 = FVector::CrossProduct(Vertices[D] - Vertices[B], Vertices[C] - Vertices[B]);
            Normals[A] += N1; Normals[B] += N1 + N2; Normals[C] += N1 + N2; Normals[D] += N2;
        }
    }
    for (FVector& Normal : Normals) Normal.Normalize();

    Terrain->CreateMeshSection_LinearColor(0, Vertices, Triangles, Normals, UVs, Colors, TArray<FProcMeshTangent>(), true);
    if (UMaterialInstanceDynamic* GroundMat = MakeTintedMaterial(this, TEXT(""), FLinearColor(0.18f, 0.31f, 0.13f)))
        Terrain->SetMaterial(0, GroundMat);

    // A gently winding water ribbon follows the valley and has collision disabled.
    TArray<FVector> WaterVertices;
    TArray<int32> WaterTriangles;
    TArray<FVector> WaterNormals;
    TArray<FVector2D> WaterUVs;
    TArray<FLinearColor> WaterColors;
    constexpr int32 RiverSegments = 160;
    constexpr float RiverHalfWidth = 520.0f;
    for (int32 I = 0; I <= RiverSegments; ++I)
    {
        const float Y = -36000.0f + (72000.0f * I / RiverSegments);
        const float CenterX = 9000.0f + FMath::Sin(Y * 0.00011f) * 6500.0f;
        const float WaterZ = SampleTerrainHeight(CenterX, Y) + 24.0f;
        WaterVertices.Add(FVector(CenterX - RiverHalfWidth, Y, WaterZ));
        WaterVertices.Add(FVector(CenterX + RiverHalfWidth, Y, WaterZ));
        WaterUVs.Add(FVector2D(0, I / 12.0f)); WaterUVs.Add(FVector2D(1, I / 12.0f));
        WaterNormals.Add(FVector::UpVector); WaterNormals.Add(FVector::UpVector);
        WaterColors.Add(FLinearColor(0.035f, 0.28f, 0.38f, 1)); WaterColors.Add(FLinearColor(0.035f, 0.28f, 0.38f, 1));
        if (I < RiverSegments)
        {
            const int32 A = I * 2, B = A + 1, C = A + 2, D = A + 3;
            WaterTriangles.Append({A, C, B, B, C, D});
        }
    }
    River->CreateMeshSection_LinearColor(0, WaterVertices, WaterTriangles, WaterNormals, WaterUVs, WaterColors, TArray<FProcMeshTangent>(), false);
    if (UMaterialInstanceDynamic* WaterMat = MakeTintedMaterial(this, TEXT(""), FLinearColor(0.035f, 0.28f, 0.38f)))
        River->SetMaterial(0, WaterMat);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeMesh(TEXT("/Engine/BasicShapes/Cone.Cone"));
    if (CubeMesh.Succeeded()) { TreeTrunks->SetStaticMesh(CubeMesh.Object); Rocks->SetStaticMesh(CubeMesh.Object); }
    if (ConeMesh.Succeeded()) TreeCrowns->SetStaticMesh(ConeMesh.Object);

    FRandomStream Random(20261122);
    for (int32 X = -22; X <= 22; ++X)
    {
        for (int32 Y = -22; Y <= 22; ++Y)
        {
            const float PX = X * 1650.0f + Random.FRandRange(-360.0f, 360.0f);
            const float PY = Y * 1650.0f + Random.FRandRange(-360.0f, 360.0f);
            if (FMath::Abs(PX) > WorldHalfSize - 1000 || FMath::Abs(PY) > WorldHalfSize - 1000) continue;

            const float RiverX = 9000.0f + FMath::Sin(PY * 0.00011f) * 6500.0f;
            if (FMath::Abs(PX - RiverX) < 2300.0f || FMath::Abs(PY - PX * 0.12f) < 1200.0f) continue;
            const float BaseZ = SampleTerrainHeight(PX, PY);

            if (Random.FRand() < 0.30f)
            {
                const float H = Random.FRandRange(320.0f, 620.0f);
                const FVector Position(PX, PY, BaseZ + H * 0.5f);
                TreeTrunks->AddInstance(FTransform(FRotator(0, Random.FRandRange(0, 360), 0), Position,
                    FVector(0.42f, 0.42f, H / 100.0f)));
                TreeCrowns->AddInstance(FTransform(FRotator(0, Random.FRandRange(0, 360), 0),
                    FVector(PX, PY, BaseZ + H + 90.0f),
                    FVector(Random.FRandRange(2.0f, 3.0f), Random.FRandRange(2.0f, 3.0f), Random.FRandRange(2.5f, 4.0f))));
            }

            if (Random.FRand() < 0.055f)
            {
                const float S = Random.FRandRange(100.0f, 360.0f);
                Rocks->AddInstance(FTransform(FRotator(Random.FRandRange(-12,12), Random.FRandRange(0,360), Random.FRandRange(-12,12)),
                    FVector(PX, PY, BaseZ + S * 0.28f), FVector(S / 100.0f, S / 100.0f, S / 100.0f)));
            }
        }
    }
}