extends SceneTree

const MODEL_PATHS := [
	"res://assets/43293218-c338-4fe2-a177-32a10bffe72c.glb",
	"res://assets/bdd1f502-bdb6-4287-8d2c-7799487a4999.glb",
	"res://assets/fb414334-be07-4e6e-9570-0fcc8769768a.glb"
]

func _initialize() -> void:
	call_deferred("_run_audit")

func _run_audit() -> void:
	for path in MODEL_PATHS:
		print("MODEL_AUDIT|BEGIN|", path)
		if not ResourceLoader.exists(path):
			print("MODEL_AUDIT|MISSING|", path)
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			print("MODEL_AUDIT|NOT_PACKED_SCENE|", path)
			continue
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		_scan_node(instance, path)
		instance.queue_free()
		await process_frame
		print("MODEL_AUDIT|END|", path)
	quit()

func _scan_node(node: Node, model_path: String) -> void:
	if node is Skeleton3D:
		var skeleton := node as Skeleton3D
		var names: Array[String] = []
		for index in range(skeleton.get_bone_count()):
			names.append(skeleton.get_bone_name(index))
		print("MODEL_AUDIT|SKELETON|", model_path, "|", skeleton.get_path(), "|bones=", skeleton.get_bone_count(), "|", ",".join(names))
	if node is AnimationPlayer:
		var player := node as AnimationPlayer
		var clips: Array[String] = []
		for animation_name in player.get_animation_list():
			var animation := player.get_animation(animation_name)
			clips.append("%s(duration=%.2f,tracks=%d)" % [str(animation_name), animation.length, animation.get_track_count()])
		print("MODEL_AUDIT|ANIMATIONS|", model_path, "|", player.get_path(), "|", ";".join(clips))
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			print("MODEL_AUDIT|MESH|", model_path, "|", mesh_node.get_path(), "|", mesh_node.mesh.get_class(), "|", mesh_node.get_aabb())
	for child in node.get_children():
		_scan_node(child, model_path)
