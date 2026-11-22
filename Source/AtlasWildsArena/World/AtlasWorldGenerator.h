#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "AtlasWorldGenerator.generated.h"

class UInstancedStaticMeshComponent;
class UProceduralMeshComponent;

UCLASS()
class ATLASWILDSARENA_API AAtlasWorldGenerator : public AActor
{
    GENERATED_BODY()

public:
    AAtlasWorldGenerator();

protected:
    virtual void OnConstruction(const FTransform& Transform) override;

private:
    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UProceduralMeshComponent> Terrain;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UProceduralMeshComponent> River;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> TreeTrunks;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> TreeCrowns;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> Rocks;

    void BuildWorld();
    float SampleTerrainHeight(float X, float Y) const;
};