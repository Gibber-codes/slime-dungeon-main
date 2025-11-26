extends TileMapLayer

const FLOOR_WIDTH = 9
const FLOOR_HEIGHT = 9
const FILLER_THICKNESS = 3

# Check your actual source IDs in the TileSet
const ATLAS_TOP: int = 1  # Adjust these to match your setup
const ATLAS_BOTTOM: int = 2
const FILLER_SOURCE_ID: int = 1
const FILLER_COORD = Vector2i(0, 1)

func _ready():
	print("Script is running!")
	generate_room()
	print("Room generated!")

func generate_room():
	clear()
	draw_basic_room()
	# add_variations() # Temporarily disabled until updated for new layout

func draw_basic_room():
	# Calculate total dimensions
	# Width = Filler(3) + Wall(1) + Floor(9) + Wall(1) + Filler(3)
	var total_width = FILLER_THICKNESS + 1 + FLOOR_WIDTH + 1 + FILLER_THICKNESS
	var total_height = FILLER_THICKNESS + 1 + FLOOR_HEIGHT + 1 + FILLER_THICKNESS
	
	for y in range(total_height):
		for x in range(total_width):
			# Check if we are in the filler region
			var is_filler = (
				x < FILLER_THICKNESS or 
				x >= total_width - FILLER_THICKNESS or 
				y < FILLER_THICKNESS or 
				y >= total_height - FILLER_THICKNESS
			)
			
			if is_filler:
				set_cell(Vector2i(x, y), FILLER_SOURCE_ID, FILLER_COORD)
				continue
			
			# We are inside the room (walls + floor)
			# Calculate coordinates relative to the room (0,0 is top-left wall)
			var rx = x - FILLER_THICKNESS
			var ry = y - FILLER_THICKNESS
			var r_width = FLOOR_WIDTH + 2
			var r_height = FLOOR_HEIGHT + 2
			
			var is_top = (ry == 0)
			var is_bottom = (ry == r_height - 1)
			var is_left = (rx == 0)
			var is_right = (rx == r_width - 1)
			
			var source_id: int = ATLAS_TOP
			var atlas_coord = Vector2i(1, 1)  # Default: floor
			
			# Corners and edges
			if is_top and (is_left or is_right):
				atlas_coord = Vector2i(2, 0)  # Top corners
			elif is_top:
				atlas_coord = Vector2i(1, 0)  # Top wall
			elif is_bottom and (is_left or is_right):
				source_id = ATLAS_BOTTOM
				atlas_coord = Vector2i(2, 0)  # Bottom corners
			elif is_bottom:
				source_id = ATLAS_BOTTOM
				atlas_coord = Vector2i(1, 0)  # Bottom wall
			elif is_left or is_right:
				atlas_coord = Vector2i(2, 1)  # Side walls
			
			set_cell(Vector2i(x, y), source_id, atlas_coord)
	
	print("Drew room with total size: ", total_width, "x", total_height)

# Add random variations
# NOTE: These need to be updated to account for FILLER_THICKNESS offsets if re-enabled
# func add_variations():
# 	if randf() > 0.5:
# 		add_top_indent()
# 	if randf() > 0.5:
# 		add_right_indent()
# 	if randf() > 0.5:
# 		add_bottom_indent()
# 	if randf() > 0.5:
# 		add_left_indent()

func next_room():
	generate_room()
