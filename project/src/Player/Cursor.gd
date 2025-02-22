extends Spatial

export (NodePath) var player_controller_path = "../../.."
export (NodePath) var camera_path = "../../../CameraController/CameraGimbal/Camera"
export (NodePath) var ray_path = "../../../CameraController/CameraGimbal/RayCast"
export (NodePath) var selector_path = "../../../CameraController/CameraGimbal/Cursor/Selector"
export (NodePath) var detector_path = "../../../CameraController/CameraGimbal/Cursor/Detector"
export (NodePath) var projector_path = "../../../CameraController/CameraGimbal/Cursor/Projector"
export (NodePath) var selection_mesh_path = "../../../CameraController/CameraGimbal/Cursor/SelectionMesh"
export (NodePath) var attractor_mesh_path = "../../../CameraController/CameraGimbal/Cursor/AttractorMesh"

onready var player_controller: Node = get_node(player_controller_path)
onready var camera = get_node(camera_path)
onready var ray = get_node(ray_path)
onready var selector = get_node(selector_path)
onready var detector = get_node(detector_path)
onready var projector = get_node(projector_path)
onready var selection_mesh = get_node(selection_mesh_path)
onready var attractor_mesh = get_node(attractor_mesh_path)

# current ray intersection on gridmap
var ray_grid_map_intersection: Vector3
# current section position
var selection_position: Vector3

# MeshGrid index constants
var EMPTY_MESHLIB_IDX = -1
var FIRST_SOUL_MESHLIB_IDX = 0
var ATTRACTOR_PLANT_MESHLIB_IDX = 1

# current grid_cell_item for placement
var grid_cell_menu_item: int = EMPTY_MESHLIB_IDX

func _handle_inputs():
	# Select attractor plant with the 1 key
	if Input.is_action_just_pressed("select_attractor") and player_controller.player_souls > 0:
		_store_grid_cell_menu_item(ATTRACTOR_PLANT_MESHLIB_IDX)
		projector._set_mesh(get_grid_cell_menu_item())
		
	# Place a plant
	if Input.is_action_just_pressed("ui_accept") and grid_cell_menu_item == 1 and player_controller.player_souls > 0:
		selector._place_plant()
		player_controller.player_souls = player_controller.change_player_souls(EMPTY_MESHLIB_IDX)
		Signals.emit_signal("player_souls_changed", player_controller.player_souls)
		if player_controller.player_souls == 0:
			_store_grid_cell_menu_item(EMPTY_MESHLIB_IDX)
			projector._set_mesh(get_grid_cell_menu_item())
	
	# collect first soul
	if Input.is_action_just_pressed("ui_accept") and detector.is_first_soul():
		selector._on_select_first_soul()
		player_controller.player_souls = player_controller.change_player_souls(1)
		Signals.emit_signal("player_souls_changed", player_controller.player_souls)

# update cursor positon to center of camera at ray intersection with ground grid
func _follow_camera(_delta: float) -> void:
	if !ray.is_colliding():
		visible = false
	else:
		ray_grid_map_intersection = get_ray_grid_intersection()
		global_transform.origin = get_selection_position()
		visible = true

# Handle Signals from radial menu
func _on_attractor_button_pressed():
	if player_controller.player_souls > 0:
		_store_grid_cell_menu_item(1)
		projector._set_mesh(get_grid_cell_menu_item())

# CURSOR HELPER FUNCTIONS

func _store_grid_cell_menu_item(item) -> void:
	grid_cell_menu_item = item

func get_grid_cell_menu_item() -> int:
	return grid_cell_menu_item

# return the meshlib item at the grid position of the cursor
func get_world_grid_cell_item() -> int:
	return get_placement_grid().get_cell_item(ray_grid_map_intersection.x,
											  ray_grid_map_intersection.y,
											  ray_grid_map_intersection.z)

# insert a meshlib item at the grid position of the cursor
func set_world_grid_cell_item(mesh_lib_item: int) -> void:
	get_placement_grid().set_cell_item(ray_grid_map_intersection.x,
									   ray_grid_map_intersection.y,
									   ray_grid_map_intersection.z,
									   mesh_lib_item)

#convert gridmap coordinate into worldspace coordinate
func get_selection_position() -> Vector3:
	return get_placement_grid().map_to_world(ray_grid_map_intersection.x, 
											 ray_grid_map_intersection.y,
											 ray_grid_map_intersection.z)

#convert collison point intro gridmap coordinate
func get_ray_grid_intersection() -> Vector3:
	return get_placement_grid().world_to_map(ray.get_collision_point())
	

# HANDLE DEPS

func get_placement_grid() -> GridMap:
	if player_controller.placement_grid:
		return player_controller.placement_grid
	else:
		print("Warning: (get_placement_grid) No grid configured, please configure a placement grid configured a default, but it will be ugly...")
		var placement_grid = GridMap.new()
		return placement_grid

func _ready():
	Signals.connect("attractor_button_pressed", self, "_on_attractor_button_pressed")
