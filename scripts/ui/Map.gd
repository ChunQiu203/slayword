extends Control

@onready var scroll_container = $ScrollContainer
@onready var location_container: MapLocationContainer = $ScrollContainer/LocationContainer
@onready var back_button: Button = $BackButton

@onready var map_button = %MapButton

var can_travel: bool = false	# if clicking on a location brings you to the next location

const MAP_CONTENT_WIDTH: float = 508
const MAP_TOP_PADDING: float = 92
const MAP_BOTTOM_PADDING: float = 116
const MAP_SIDE_PADDING: float = 72
const MAP_FLOOR_SPACING: float = 94
const MAP_NODE_SIZE: Vector2 = Vector2(40, 40)

func _ready():
	map_button.button_up.connect(_on_map_button_up)
	back_button.button_up.connect(_on_back_button_up)
	
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	
	Signals.dialogue_ended.connect(_on_dialogue_ended)
	
	Signals.chest_opened.connect(_on_chest_opened)
	Signals.shop_opened.connect(_on_shop_opened)
	
	Signals.map_location_selected.connect(_on_map_location_selected)
	
func populate_locations(locations: Array[LocationData] = Global.get_all_act_locations()):
	clear_locations()
	
	var next_locations: Array[LocationData] = Global.get_next_locations()
	var next_location_ids: Array[String] = []
	for next_location in next_locations:
		next_location_ids.append(next_location.location_id)
	
	var current_location_data: LocationData = Global.get_player_location_data()
	var current_location_id: String = ""
	if current_location_data != null:
		current_location_id = current_location_data.location_id
	
	var visible_locations: Array[LocationData] = _get_visible_locations(locations)
	var map_bounds: Dictionary[String, float] = _get_map_bounds(visible_locations)
	var location_center_by_id: Dictionary[String, Vector2] = {}
	var location_by_id: Dictionary[String, LocationData] = {}
	var max_y: float = 0.0
	
	var current_map_location: MapLocation = null
	
	for location_data in visible_locations:
		var location_center: Vector2 = _get_location_center(location_data, map_bounds)
		location_center_by_id[location_data.location_id] = location_center
		location_by_id[location_data.location_id] = location_data
		var location_bottom: float = location_center.y + (MAP_NODE_SIZE.y * 0.5)
		if location_bottom > max_y:
			max_y = location_bottom
	
	var route_connections: Array[MapRouteConnection] = _get_route_connections(visible_locations, location_center_by_id, location_by_id)
	var visited_location_ids: Array[String] = _get_visited_location_ids(visible_locations)
	location_container.set_route_data(route_connections, current_location_id, next_location_ids, visited_location_ids)
	
	for location_data in visible_locations:
		var is_reachable: bool = can_travel and next_locations.has(location_data)
		var is_current: bool = location_data.location_id == current_location_id
		
		var map_location: MapLocation = Scenes.MAP_LOCATION.instantiate()
		location_container.add_child(map_location)
		map_location.init(location_data, is_reachable, is_current)
		map_location.position = location_center_by_id[location_data.location_id] - (MAP_NODE_SIZE * 0.5)
		
		map_location.map_location_button_up.connect(_on_map_location_button_up)
		
		# flash the locations the player can travel to
		if is_reachable:
			map_location.flash_location()
			current_map_location = map_location
	
	# set the size of the container to make scrolling posible
	var content_height: float = max_y + MAP_BOTTOM_PADDING
	location_container.custom_minimum_size = Vector2(MAP_CONTENT_WIDTH, content_height)
	location_container.size = Vector2(MAP_CONTENT_WIDTH, content_height)
	
	# wait a frame to ensure container is properly resized
	await Global.get_tree().process_frame
	# set the scroll
	if current_map_location != null:
		current_map_location.grab_focus()
	else:
		# presumably the invisible starting location, set to bottom
		scroll_container.scroll_vertical = int(content_height)
	

func clear_locations() -> void:
	for child in location_container.get_children():
		child.queue_free()
	var route_connections: Array[MapRouteConnection] = []
	location_container.set_route_data(route_connections, "", [], [])

func _get_visible_locations(locations: Array[LocationData]) -> Array[LocationData]:
	var visible_locations: Array[LocationData] = []
	for location_data in locations:
		if location_data.location_type == LocationData.LOCATION_TYPES.STARTING:
			continue	# starting area not displayed
		visible_locations.append(location_data)
	return visible_locations

func _get_map_bounds(locations: Array[LocationData]) -> Dictionary[String, float]:
	var min_lane_index: float = 0.0
	var max_lane_index: float = 0.0
	var max_floor_index: float = 0.0
	var initialized: bool = false
	
	for location_data in locations:
		if not initialized:
			min_lane_index = location_data.location_index.x
			max_lane_index = location_data.location_index.x
			max_floor_index = location_data.location_index.y
			initialized = true
		else:
			if location_data.location_index.x < min_lane_index:
				min_lane_index = location_data.location_index.x
			if location_data.location_index.x > max_lane_index:
				max_lane_index = location_data.location_index.x
			if location_data.location_index.y > max_floor_index:
				max_floor_index = location_data.location_index.y
	
	return {
		"min_lane_index": min_lane_index,
		"max_lane_index": max_lane_index,
		"max_floor_index": max_floor_index,
	}

func _get_location_center(location_data: LocationData, map_bounds: Dictionary[String, float]) -> Vector2:
	var min_lane_index: float = map_bounds.get("min_lane_index", 0.0)
	var max_lane_index: float = map_bounds.get("max_lane_index", 0.0)
	var max_floor_index: float = map_bounds.get("max_floor_index", 0.0)
	var lane_count: float = max_lane_index - min_lane_index
	if lane_count < 1.0:
		lane_count = 1.0
	var lane_width: float = (MAP_CONTENT_WIDTH - (MAP_SIDE_PADDING * 2.0)) / lane_count
	var x: float = MAP_SIDE_PADDING + ((location_data.location_index.x - min_lane_index) * lane_width)
	var y: float = MAP_TOP_PADDING + ((max_floor_index - location_data.location_index.y) * MAP_FLOOR_SPACING)
	
	if location_data.location_type == LocationData.LOCATION_TYPES.BOSS:
		x = MAP_CONTENT_WIDTH * 0.5
	
	return Vector2(x, y)

func _get_route_connections(
	visible_locations: Array[LocationData],
	location_center_by_id: Dictionary[String, Vector2],
	location_by_id: Dictionary[String, LocationData]
) -> Array[MapRouteConnection]:
	var route_connections: Array[MapRouteConnection] = []
	for location_data in visible_locations:
		if not location_center_by_id.has(location_data.location_id):
			continue
		
		for next_location_id in location_data.location_next_location_ids:
			if not location_center_by_id.has(next_location_id):
				continue
			
			var next_location_data: LocationData = location_by_id[next_location_id]
			route_connections.append(MapRouteConnection.new(
				location_center_by_id[location_data.location_id],
				location_center_by_id[next_location_id],
				location_data.location_id,
				next_location_data.location_id
			))
	return route_connections

func _get_visited_location_ids(locations: Array[LocationData]) -> Array[String]:
	var visited_location_ids: Array[String] = []
	for location_data in locations:
		if location_data.location_visited:
			visited_location_ids.append(location_data.location_id)
	return visited_location_ids

func show_map():
	populate_locations()
	visible = true

func hide_map():
	visible = false

func _on_map_button_up():
	show_map()

func _on_map_location_button_up(map_location: MapLocation):
	# map must be in travel mode
	if can_travel:
		# must be adjacent to player location
		if Global.get_next_locations().has(map_location.location_data):
			# visit the location
			map_location.location_data.location_visited = true
			ActionGenerator.generate_visit_location(map_location.location_data.location_id)
	
func _on_map_location_selected(location_data: LocationData):
	# disable travel mode
	can_travel = false
	hide_map()

func _on_combat_started(_event_id: String):
	can_travel = false

func _on_combat_ended():
	can_travel = true

func _on_chest_opened():
	can_travel = true

func _on_shop_opened():
	can_travel = true

func _on_dialogue_ended():
	var player: Player = Global.get_player()
	if player.is_alive():
		can_travel = true
		show_map()
	else:
		hide_map()

func _on_back_button_up():
	hide_map()
	get_combined_minimum_size()
