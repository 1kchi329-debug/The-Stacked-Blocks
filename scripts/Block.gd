extends StaticBody3D

## Block behavior script.
## A block can optionally be marked as hot, which spawns a smoke particle effect.

@export var hot: bool = false:
	set(value):
		hot = value
		_update_smoke()

@onready var smoke: GPUParticles3D = $Smoke
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	_update_smoke()

## Enables/disables smoke emission based on hot flag.
func _update_smoke() -> void:
	if not is_node_ready():
		return
	smoke.emitting = hot
