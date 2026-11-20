#include "ShadowArenaGameMode.h"
#include "Engine/World.h"
#include "Engine/StaticMeshActor.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"
#include "GameFramework/PlayerStart.h"
AShadowArenaGameMode::AShadowArenaGameMode() {
 PrimaryActorTick.bCanEverTick = false;
}
void AShadowArenaGameMode::BeginPlay() {
 Super::BeginPlay();
 UWorld* W = GetWorld(); if (!W) return;
 // Simple greybox arena built from engine primitives; replace with authored assets later.
 auto SpawnBlock = [W](FVector Location, FVector Scale, FColor Color) {
  AStaticMeshActor* A = W->SpawnActor<AStaticMeshActor>(Location, FRotator::ZeroRotator);
  if (!A) return;
  UStaticMeshComponent* M = A->GetStaticMeshComponent();
  static ConstructorHelpers::FObjectFinder<UStaticMesh> Cube(TEXT("/Engine/BasicShapes/Cube.Cube"));
  if (Cube.Succeeded()) M->SetStaticMesh(Cube.Object);
  M->SetWorldScale3D(Scale);
  M->SetMobility(EComponentMobility::Movable);
  M->SetVectorParameterValueOnMaterials(FName("Color"), FVector(Color.R,Color.G,Color.B));
  M->SetCollisionProfileName(TEXT("BlockAll"));
 };
 SpawnBlock(FVector(0,0,-60),FVector(18,18,1),FColor(35,39,48));
 for(int i=0;i<4;i++){
  float X=(i<2?-900.f:900.f), Y=(i%2==0?-900.f:900.f);
  SpawnBlock(FVector(X,Y,100),FVector(1,18,2),FColor(20,24,35));
 }
}