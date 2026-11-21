#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "AtlasWorldGenerator.generated.h"

class UInstancedStaticMeshComponent;
class UStaticMeshComponent;

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
    TObjectPtr<UStaticMeshComponent> Ground;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UStaticMeshComponent> River;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> TreeTrunks;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> TreeCrowns;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> Rocks;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UInstancedStaticMeshComponent> Hills;

    void BuildWorld();
};
