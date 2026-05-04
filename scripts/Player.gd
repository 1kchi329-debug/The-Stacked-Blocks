extends CharacterBody3D

## First-person controller + tool interactions.

const SPEED: float = 6.5
const ACCEL: float = 14.0
const AIR_ACCEL: float = 4.0
const GRAVITY: float = 20.0
const MOUSE_SENS: float = 0.002

enum Tool {
	HAND,
	PICKAXE,
	FARMING
}

@export var block_scene: PackedScene
@export var world_root_path: NodePath

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/RayCast3D

var current_tool: Tool = Tool.HAND
var world_root: Node3D
var target_camera_pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	world_root = get_node(world_root_path) as Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Smooth first-person look.
		rotate_y(-event.relative.x * MOUSE_SENS)
		target_camera_pitch = clamp(target_camera_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
	
	if event.is_action_pressed("tool_1"):
		current_tool = Tool.HAND
	elif event.is_action_pressed("tool_2"):
		current_tool = Tool.PICKAXE
	elif event.is_action_pressed("tool_3"):
		current_tool = Tool.FARMING
	
	if event.is_action_pressed("place_block"):
		_use_primary_action()
	elif event.is_action_pressed("remove_block"):
		_use_secondary_action()

func _physics_process(delta: float) -> void:
	# Camera smoothing on X rotation.
	camera_pivot.rotation.x = lerp(camera_pivot.rotation.x, target_camera_pitch, 12.0 * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var desired_dir := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	var target_vel := desired_dir * SPEED
	var accel := ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target_vel.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, accel * delta)

	move_and_slide()

func _use_primary_action() -> void:
	match current_tool:
		Tool.HAND:
			_place_block()
		Tool.PICKAXE:
			_remove_targeted_block()
		Tool.FARMING:
			_farm_targeted_block()

func _use_secondary_action() -> void:
	# Right click always removes a block per requirement.
	_remove_targeted_block()

## Places a block on the face currently looked at.
func _place_block() -> void:
	if not raycast.is_colliding():
		return
	var hit_pos: Vector3 = raycast.get_collision_point()
	var hit_normal: Vector3 = raycast.get_collision_normal()
	var place_pos := (hit_pos + hit_normal * 0.5).snapped(Vector3.ONE)
	
	if _get_block_at(place_pos) != null:
		return
	
	var block := block_scene.instantiate() as Node3D
	block.global_position = place_pos
	world_root.add_child(block)

## Removes the block currently looked at.
func _remove_targeted_block() -> void:
	if not raycast.is_colliding():
		return
	var collider := raycast.get_collider()
	if collider is StaticBody3D and collider.is_in_group("blocks"):
		(collider as Node).queue_free()

## Converts targeted block to farm soil by changing color.
func _farm_targeted_block() -> void:
	if not raycast.is_colliding():
		return
	var collider := raycast.get_collider()
	if collider is StaticBody3D and collider.is_in_group("blocks"):
		var mesh := collider.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.25, 0.17)
			mat.roughness = 1.0
			mesh.material_override = mat

func _get_block_at(world_pos: Vector3) -> Node3D:
	for child in world_root.get_children():
		if child is Node3D and (child as Node3D).global_position == world_pos:
			return child
	return null
