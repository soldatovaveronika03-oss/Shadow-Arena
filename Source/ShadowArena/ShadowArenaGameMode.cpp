#include "ShadowArenaGameMode.h"
#include "Engine/World.h"
#include "Engine/StaticMeshActor.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/UObjectGlobals.h"
AShadowArenaGameMode::AShadowArenaGameMode() {
 PrimaryActorTick.bCanEverTick = false;
}
void AShadowArenaGameMode::BeginPlay() {
 Super::BeginPlay();
 UWorld* W = GetWorld();
 if (!W) return;
 UStaticMesh* CubeMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
 if (!CubeMesh) return;
 auto SpawnBlock = [W, CubeMesh](FVector Location, FVector Scale, FLinearColor Color) {
  AStaticMeshActor* Actor = W->SpawnActor<AStaticMeshActor>(Location, FRotator::ZeroRotator);
  if (!Actor) return;
  UStaticMeshComponent* Mesh = Actor->GetStaticMeshComponent();
  Mesh->SetStaticMesh(CubeMesh);
  Mesh->SetWorldScale3D(Scale);
  Mesh->SetMobility(EComponentMobility::Movable);
  Mesh->SetCollisionProfileName(TEXT("BlockAll"));
  UMaterialInstanceDynamic* Material = Mesh->CreateAndSetMaterialInstanceDynamic(0);
  if (Material) Material->SetVectorParameterValue(TEXT("Color"), Color);
 };
 // Flat arena floor and four perimeter walls.
 SpawnBlock(FVector(0,0,-60), FVector(18,18,1), FLinearColor(0.08f,0.09f,0.12f));
 SpawnBlock(FVector(-900,0,100), FVector(1,18,2), FLinearColor(0.04f,0.05f,0.08f));
 SpawnBlock(FVector(900,0,100), FVector(1,18,2), FLinearColor(0.04f,0.05f,0.08f));
 SpawnBlock(FVector(0,-900,100), FVector(18,1,2), FLinearColor(0.04f,0.05f,0.08f));
 SpawnBlock(FVector(0,900,100), FVector(18,1,2), FLinearColor(0.04f,0.05f,0.08f));
}