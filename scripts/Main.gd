extends Node3D

## Main world manager: tree spawning + day/night cycle.

@export var tree_count: int = 20
@export var tree_spawn_radius: float = 40.0
@export var day_night_speed: float = 3.0

@onready var sun: DirectionalLight3D = $Sun
@onready var world: Node3D = $World
@onready var env: WorldEnvironment = $WorldEnvironment

var sun_angle: float = 25.0

func _ready() -> void:
	randomize()
	_spawn_trees()

func _process(delta: float) -> void:
	# Rotate the sun for day/night progression.
	sun_angle = fmod(sun_angle + day_night_speed * delta, 360.0)
	sun.rotation_degrees.x = sun_angle
	
	# Blend lighting over cycle with ambient floor at night.
	var day_factor := clamp((sin(deg_to_rad(sun_angle)) + 1.0) * 0.5, 0.0, 1.0)
	sun.light_energy = lerp(0.12, 1.1, day_factor)
	env.environment.ambient_light_energy = lerp(0.18, 0.7, day_factor)
	env.environment.background_energy_multiplier = lerp(0.5, 1.0, day_factor)

func _spawn_trees() -> void:
	for i in tree_count:
		var tree := Node3D.new()
		tree.name = "Tree_%d" % i
		
		# Trunk.
		var trunk_body := StaticBody3D.new()
		var trunk_mesh := MeshInstance3D.new()
		var trunk_box := BoxMesh.new()
		trunk_box.size = Vector3(0.8, 3.0, 0.8)
		trunk_mesh.mesh = trunk_box
		var trunk_mat := StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.4, 0.24, 0.1)
		trunk_mesh.material_override = trunk_mat
		var trunk_shape := CollisionShape3D.new()
		var trunk_col := BoxShape3D.new()
		trunk_col.size = Vector3(0.8, 3.0, 0.8)
		trunk_shape.shape = trunk_col
		trunk_body.add_child(trunk_mesh)
		trunk_body.add_child(trunk_shape)
		tree.add_child(trunk_body)
		
		# Leaves canopy.
		var leaves := MeshInstance3D.new()
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius = 1.6
		leaf_mesh.height = 3.2
		leaves.mesh = leaf_mesh
		leaves.position.y = 2.6
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.2, 0.6, 0.2)
		leaves.material_override = leaf_mat
		tree.add_child(leaves)
		
		var angle := randf() * TAU
		var radius := randf_range(8.0, tree_spawn_radius)
		tree.position = Vector3(cos(angle) * radius, 1.5, sin(angle) * radius)
		world.add_child(tree)
