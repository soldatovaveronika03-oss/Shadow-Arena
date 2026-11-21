using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.IO;

[InitializeOnLoad]
public static class AtlasProjectSetup
{
    private const string ScenePath = "Assets/Scenes/ArenaPrototype.unity";

    static AtlasProjectSetup()
    {
        EditorApplication.delayCall += EnsureStarterScene;
    }

    [MenuItem("ATLAS WILDS/Generate Starter Arena")]
    public static void EnsureStarterScene()
    {
        if (EditorApplication.isPlayingOrWillChangePlaymode) return;

        Directory.CreateDirectory("Assets/Scenes");
        if (!File.Exists(ScenePath))
            CreateStarterScene();

        var scenes = new EditorBuildSettingsScene[]
        {
            new EditorBuildSettingsScene(ScenePath, true)
        };
        EditorBuildSettings.scenes = scenes;
        AssetDatabase.SaveAssets();
    }

    private static void CreateStarterScene()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var lightObject = new GameObject("Sun Light");
        var light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.25f;
        lightObject.transform.rotation = Quaternion.Euler(50f, -35f, 0f);

        var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = "Arena Ground";
        ground.transform.position = new Vector3(0f, -0.5f, 0f);
        ground.transform.localScale = new Vector3(90f, 1f, 70f);
        ground.GetComponent<Renderer>().sharedMaterial = MakeMaterial("Ground - Moss Green", new Color(0.19f, 0.29f, 0.19f));

        CreateLane(new Vector3(0f, 0.03f, 0f), new Vector3(90f, 0.1f, 8f), "Central Lane");
        CreateTower(new Vector3(-30f, 1f, 0f), "Blue Tower", new Color(0.25f, 0.55f, 1f));
        CreateTower(new Vector3(30f, 1f, 0f), "Red Tower", new Color(1f, 0.28f, 0.2f));
        CreateHero(new Vector3(-18f, 1f, 0f));

        var cameraObject = new GameObject("Arena Camera");
        var camera = cameraObject.AddComponent<Camera>();
        cameraObject.tag = "MainCamera";
        cameraObject.transform.position = new Vector3(-10f, 24f, -26f);
        cameraObject.transform.rotation = Quaternion.Euler(42f, 20f, 0f);
        camera.fieldOfView = 55f;
        cameraObject.AddComponent<AudioListener>();

        var ambient = new GameObject("Arena Bootstrap");
        ambient.AddComponent<AtlasArenaBootstrap>();

        EditorSceneManager.SaveScene(scene, ScenePath);
        Debug.Log("ATLAS WILDS starter arena created. Open the ArenaPrototype scene and press Play.");
    }

    private static void CreateLane(Vector3 position, Vector3 scale, string name)
    {
        var lane = GameObject.CreatePrimitive(PrimitiveType.Cube);
        lane.name = name;
        lane.transform.position = position;
        lane.transform.localScale = scale;
        lane.GetComponent<Renderer>().sharedMaterial = MakeMaterial("Lane - Sandstone", new Color(0.48f, 0.42f, 0.29f));
    }

    private static void CreateTower(Vector3 position, string name, Color color)
    {
        var tower = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        tower.name = name;
        tower.transform.position = position;
        tower.transform.localScale = new Vector3(2.2f, 2.5f, 2.2f);
        tower.GetComponent<Renderer>().sharedMaterial = MakeMaterial(name + " Material", color);
    }

    private static void CreateHero(Vector3 position)
    {
        var hero = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        hero.name = "Kairon - Placeholder Hero";
        hero.transform.position = position;
        hero.GetComponent<Renderer>().sharedMaterial = MakeMaterial("Hero - Blue Steel", new Color(0.25f, 0.55f, 0.85f));
    }

    private static Material MakeMaterial(string name, Color color)
    {
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null) shader = Shader.Find("Standard");
        var material = new Material(shader);
        material.name = name;
        material.color = color;
        return material;
    }
}

public class AtlasArenaBootstrap : MonoBehaviour
{
    private void Start()
    {
        Debug.Log("ATLAS WILDS ARENA Unity prototype started.");
    }
}
