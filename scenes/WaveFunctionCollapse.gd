extends Node2D

export var size = 25

var source_objects = {}
var children_sprites = {}

var coefficients: Array
var initial_state: Array
var image_size: Vector2
var number: Vector2
var images: Array
var dict: Dictionary
var weight: Dictionary

var rng = RandomNumberGenerator.new()

onready var texture = load("res://test_tiles2.png")
#onready var texture = load("res://tileset_test.png")
#onready var viewport = $ViewportContainer
#onready var tilemap = $ViewportContainer/TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	load_data()
	
	var baseImage: Image = texture.get_data()
	images = get_sample_images(baseImage)
	dict = get_images_dict(images)
	
	#newTexture.create_from_image(dict["p0"], 0)
	
#	var tempBytes = []
#	var tempRow = []
#	tempRow.append(dict["p0"])
#	tempRow.append(dict["p1"])
#	tempBytes.append_array(dict["p0"].get_data())
#	tempBytes.append_array(dict["p1"].get_data())
#	var output: Image = Image.new()
	
#	for l in range(image_size.y):
#		var begin = l * image_size.x * 3
#		var end = (l + 1) * image_size.x * 3 - 1
#		for image in tempRow:
#			tempBytes.append_array(image.get_data().subarray(begin, end))
#
#	output.create_from_data(
#		image_size.x * 2,
#		image_size.y,
#		false,
#		dict["p1"].get_format(),
#		tempBytes
#	)
#	newTexture.create_from_image(output, 0)
	
	
	
#	var tileset = TileSet.new()
#	var id = tileset.get_last_unused_tile_id()
#	tileset.create_tile(id)
#	tileset.tile_set_name(id, "p0")
#
#	tilemap.tile_set

func generate_image_texture(width: int, height: int) -> ImageTexture:
	size = width / image_size.x
	print(size)
	
	
	start_wave_function()
	wfc()
	
#	var sprite = Sprite.new()
	var newTexture = ImageTexture.new()
	newTexture.create_from_image(collect_images(dict, coefficients), 0)
	return newTexture
#	sprite.texture = newTexture
#	sprite.position = Vector2(size * image_size.x / 2, size * image_size.y / 2)
#	sprite.scale = Vector2(1, 1)
#	add_child(sprite)

func collect_images(dict: Dictionary, coefficients: Array):
	var output: Image = Image.new()
	# FORMAT_RGBA8
	
	var tempBytes: Array = []
	var preimage_array = []
	for i in range(size):
		for j in range(size):
			var list = coefficients[i][j]
			var patternType
			if list.size() > 0:
				patternType = list[0]
			else:
				patternType = "default"
				print("default")
			var image = dict[patternType]
			for k in range(image_size.y):
				var byte_array
				if j == 0:
					byte_array = []
					preimage_array.append(byte_array)
				else:
					byte_array = preimage_array[i * image_size.y + k]
				var begin = k * image_size.x * 3
				var end = (k + 1) * image_size.x * 3 - 1
				byte_array.append_array(image.get_data().subarray(begin, end))
	
	for l in range(image_size.y * size):
		tempBytes.append_array(preimage_array[l])
	
	output.create_from_data(
		image_size.x * size,
		image_size.y * size,
		false,
		dict["p0"].get_format(),
		tempBytes
	)
	
	return output

func get_sample_images(image: Image) -> Array:
	var images: Array = []
	var x = 0
	var y = 0
	for i in range(number.y):
		var row: Array = []
		x = 0
		for j in range(number.x):
			var imgTemp = Image.new()
			imgTemp.create(image_size.x, image_size.y, false, image.get_format())
			imgTemp.blit_rect(image, Rect2(x, y, image_size.x, image_size.y), Vector2(0, 0))
			row.append(imgTemp)
			x += image_size.x + 1
		y += image_size.y + 1
		images.append(row)
	return images

func get_images_dict(images: Array):
	var resultDict = {}
	var k = 0
	for i in range(number.y):
		for j in range(number.x):
			var index = "p" + str(k)
			resultDict[index] = images[i][j]
			k += 1
	resultDict["default"] = images[0][0]
	return resultDict

func load_data():
	var file = File.new()
	file.open("res://WaveFunctionCollapse_test1.json", file.READ)
	var text = file.get_as_text()
	source_objects = parse_json(text)
	initial_state = source_objects["list"]
	var sizes = source_objects["size"]
	image_size = Vector2(sizes["x"], sizes["y"])
	var numbers = source_objects["number"]
	number = Vector2(numbers["x"], numbers["y"])
	weight = source_objects["weight"]
	
func start_wave_function():
	for i in range(size):
		var x = []
		for j in range(size):
			x.append(initial_state)
		coefficients.append(x)

func is_fully_collapsed():
	for wave in coefficients:
		for entry in wave:
			if entry.size() > 1:
				return false
	return true

func get_min_entropy_coords() -> Vector2:
	var min_entropy = initial_state.size()
	var coords_min_entropy: Array = []
	for i in range(size):
		for j in range(size):
			var coef = coefficients[i][j].size()
			if coef > 1 and min_entropy > coef:
				min_entropy = coef
				coords_min_entropy = []
				coords_min_entropy.append(Vector2(j, i))
			elif min_entropy == coef:
				coords_min_entropy.append(Vector2(j, i))
	var result = coords_min_entropy[0]
	var coords_len = coords_min_entropy.size()
	if (coords_len > 1):
		var index = rng.randi_range(0, coords_len - 1)
		result = coords_min_entropy[index]
	return result

func collapse_at(coords: Vector2):
	var coef = coefficients[coords.y][coords.x]
	var sum_weight = 0
	for val in coef:
		sum_weight += weight[val]
	var rand_weight = rng.randf_range(0, sum_weight)
	var pattern
	for val in coef:
		if rand_weight < weight[val]:
			pattern = val
		rand_weight -= weight[val]
	coef = []
	coef.push_back(pattern)
	coefficients[coords.y][coords.x] = coef

func propagate(coords: Vector2):
	var stack = []
	stack.append(coords)
	
	while stack.size() > 0:
		var cur_coords = stack.pop_back()
		
		for dir in valid_dirs(cur_coords):
			var possible_list = get_possible_patterns(cur_coords, dir)
			
			var neighbour_coords = cur_coords + dir
			var neighbour_patterns = coefficients[neighbour_coords.y][neighbour_coords.x]
			var neighbour_patterns_len = neighbour_patterns.size()
			
			if neighbour_patterns.size() == 1:
				continue
			
			var intersect_list: Array = intersect(possible_list, neighbour_patterns)
			coefficients[neighbour_coords.y][neighbour_coords.x] = intersect_list
			if (neighbour_patterns_len > intersect_list.size()) and not (stack.has(neighbour_coords)):
				stack.append(neighbour_coords)
	pass

func iterate():
	var coords = get_min_entropy_coords()
	collapse_at(coords)
	propagate(coords)

func wfc():
	while not is_fully_collapsed():
		iterate()

func valid_dirs(coords: Vector2) -> Array:
	var result = []
	var x = coords.x
	var y = coords.y
	if x + 1 < size:
		result.append(Vector2.RIGHT)
	if x - 1 >= 0:
		result.append(Vector2.LEFT)
	if y + 1 < size:
		result.append(Vector2.DOWN)
	if y - 1 >= 0:
		result.append(Vector2.UP)
	return result

func intersect(array1, array2) -> Array:
	var intersection = []
	for item in array1:
		if array2.has(item):
			intersection.append(item)
	return intersection

func get_possible_patterns(coords: Vector2, dir: Vector2) -> Array:
	var cur_patterns = coefficients[coords.y][coords.x]
	var possible_list: Array
	var dir_key: String
	if (dir == Vector2.UP):
		dir_key = "up"
	elif (dir == Vector2.DOWN):
		dir_key = "down"
	elif (dir == Vector2.LEFT):
		dir_key = "left"
	elif (dir == Vector2.RIGHT):
		dir_key = "right"
	for pattern in cur_patterns:
		for adding_pat in source_objects[pattern]["neighbours"][dir_key]:
			if not possible_list.has(adding_pat):
				possible_list.append(adding_pat)
	return possible_list
