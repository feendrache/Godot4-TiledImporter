@tool
extends RefCounted

const FLIPPED_HORIZONTALLY_FLAG = 0x80000000
const FLIPPED_VERTICALLY_FLAG   = 0x40000000
const FLIPPED_DIAGONALLY_FLAG   = 0x20000000

var xml_parser = preload("res://addons/naddys_tiled_maps/tiled_xml_to_dict.gd").new()
var tiled_helper = preload("res://addons/naddys_tiled_maps/tiled_helper.gd").new()

func create_from_file(path):
	var parsed_data = xml_parser.read_tmx(path)
	return create_tilemap(parsed_data, path)

func create_tilemap(map_data, path):
	var tilemap = TileMap.new()
	var tileset_creator = load("res://addons/naddys_tiled_maps/tileset_creator.gd").new()
	tilemap.tile_set = tileset_creator.create_tileset(map_data.tilesets, path)
	
	var width = map_data.width
	var height = map_data.height
	var tilesize = Vector2i(int(map_data.tilewidth), int(map_data.tileheight))
	var infinite = map_data.infinite
	var orientation = map_data.orientation
	
	tilemap.set_name(path.get_file().get_basename())
	tilemap.cell_quadrant_size = int(map_data.tilewidth)
	tilemap.remove_layer(0)
	var layer_counter = 0	
	for layer in map_data.layers:
		#if layer_counter > 1: continue
		var visible = true 
		if "visible" in layer:
			if layer.visible == 0: visible = false
		var z_index = 0
		if "properties" in layer:
			if "z_index" in layer.properties:
				z_index = layer.properties.z_index
		if layer.type == "tilelayer":
			tilemap.add_layer(layer_counter)
			tilemap.set_layer_name(layer_counter, layer.name)
			tilemap.set_layer_y_sort_enabled(layer_counter, true)
			tilemap.set_layer_enabled(layer_counter, visible)
			tilemap.set_layer_z_index(layer_counter, z_index)
			if "data" in layer:
				var cell_counter = 0
				for cell in layer.data:
					var int_id = int(cell) & 0xFFFFFFFF
					if int_id == 0:
						cell_counter += 1
						continue
					var alt_id = 0
					var flipped_h = bool(int_id & FLIPPED_HORIZONTALLY_FLAG)
					if flipped_h: alt_id = 1
					var flipped_v = bool(int_id & FLIPPED_VERTICALLY_FLAG)
					if flipped_v: alt_id = 2
					if flipped_h && flipped_v: alt_id = 3
					var flipped_d = bool(int_id & FLIPPED_DIAGONALLY_FLAG)
					if flipped_d: alt_id = 3
						
					var gid = int_id & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)
					
					var source_id = get_source_id(gid, map_data.tilesets)
					var tileset_path = path.get_base_dir().path_join(map_data.tilesets[source_id].source)
					var tileset_data = xml_parser.read_tsx(tileset_path)
					var atlas_coords = get_atlas_coords(gid, map_data.tilesets[source_id].firstgid, tileset_data)
					var cell_coord = get_cell_coord(cell_counter, width, height, tileset_data, int(map_data.tilewidth))
					#if source_id > 0: print("gid "+str(gid)+" in "+str(source_id)+" at "+str(atlas_coords.x)+"/"+str(atlas_coords.y)+" => "+str(gid-map_data.tilesets[source_id].firstgid))
					if gid > 0: 
						tilemap.set_cell(layer_counter, cell_coord, source_id, atlas_coords, alt_id)
					cell_counter = cell_counter+1
			elif "chunks" in layer:
				var layer_width = layer.width
				var layer_height = layer.height
				var chunk_counter = 0
				for chunk in layer.chunks:
					#print(chunk)
					var chunk_width = chunk.width
					var chunk_height = chunk.height
					var cell_counter = 0
					#if chunk_counter > 0: continue
					for cell in chunk.data:
						var int_id = int(cell) & 0xFFFFFFFF
						if int_id == 0:
							cell_counter += 1
							continue
						var alt_id = 0
						var flipped_h = bool(int_id & FLIPPED_HORIZONTALLY_FLAG)
						if flipped_h: alt_id = 1
						var flipped_v = bool(int_id & FLIPPED_VERTICALLY_FLAG)
						if flipped_v: alt_id = 2
						if flipped_h && flipped_v: alt_id = 3
						var flipped_d = bool(int_id & FLIPPED_DIAGONALLY_FLAG)
						if flipped_d: alt_id = 3
						var gid = int_id & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)
						var source_id = get_source_id(gid, map_data.tilesets)
						var tileset_path = path.get_base_dir().path_join(map_data.tilesets[source_id].source)
						var tileset_data = xml_parser.read_tsx(tileset_path)
						var atlas_coords = get_atlas_coords(gid, map_data.tilesets[source_id].firstgid, tileset_data)
						var cell_coord = get_cell_coord_from_chunk(cell_counter, chunk_width, chunk_height, chunk.x, chunk.y, tileset_data, int(map_data.tilewidth))
						#if source_id > 0: print(cell_coord)#print("gid "+str(gid)+" in "+str(source_id)+" at "+str(atlas_coords.x)+"/"+str(atlas_coords.y)+" => "+str(gid-map_data.tilesets[source_id].firstgid))
						if gid > 0: 
							tilemap.set_cell(layer_counter, cell_coord, source_id, atlas_coords, alt_id)
						cell_counter = cell_counter+1
					chunk_counter = chunk_counter+1
		elif layer.type == "objectgroup":
			var object_layer = Node2D.new()
			object_layer.z_index = z_index
			object_layer.visible = visible
			if "name" in layer and not str(layer.name).is_empty():
				object_layer.set_name(str(layer.name))
			tilemap.add_child(object_layer)
			object_layer.set_owner(tilemap)
			if "objects" in layer:
				for object in layer.objects:
					var shape = tiled_helper.shape_from_object(object)					
					var body = Area2D.new() if object.type == "area" else StaticBody2D.new()

					var offset = Vector2()
					var collision
					var pos = Vector2()
					var rot = 0

					if not ("polygon" in object or "polyline" in object):
						# Regular shape
						collision = CollisionShape2D.new()
						collision.shape = shape
						if shape is RectangleShape2D:
							offset = shape.extents
						elif shape is CircleShape2D:
							offset = Vector2(shape.radius, shape.radius)
						elif shape is CapsuleShape2D:
							offset = Vector2(shape.radius, shape.height)
							if shape.radius > shape.height:
								var temp = shape.radius
								shape.radius = shape.height
								shape.height = temp
								collision.rotation_degrees = 90
							shape.height *= 2
						collision.position = offset
					else:
						collision = CollisionPolygon2D.new()
						var points = null
						if shape is ConcavePolygonShape2D:
							points = []
							var segments = shape.segments
							for i in range(0, segments.size()):
								if i % 2 != 0:
									continue
								points.push_back(segments[i])
							collision.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
						else:
							points = shape.points
							collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
						collision.polygon = points

					collision.one_way_collision = object.type == "one-way"

					if "x" in object:
						pos.x = float(object.x)
					if "y" in object:
						pos.y = float(object.y)
					if "rotation" in object:
						rot = float(object.rotation)

					body.set("editor/display_folded", true)
					object_layer.add_child(body)
					body.set_owner(tilemap)
					body.add_child(collision)
					collision.set_owner(tilemap)

					if "name" in object and not str(object.name).is_empty():
						body.set_name(str(object.name))
					elif "id" in object and not str(object.id).is_empty():
						body.set_name(str(object.id))
					body.visible = bool(object.visible) if "visible" in object else true
					body.position = pos
					body.rotation = rot
			
		layer_counter = layer_counter+1
	
	return tilemap

func get_atlas_coords(cell_value, firstgid, parsed_data):
	var columns = parsed_data.columns
	var tilecount = parsed_data.tilecount
	var rel_id = cell_value - (firstgid-1)
	var x = 0
	var y = 0
	
	if cell_value > 0:
		var cell_counter = 1
		while cell_counter < tilecount:
			if cell_counter == rel_id: return Vector2i(x,y)
			x = x+1
			if x >= columns:
				y = y+1
				x = 0
			cell_counter = cell_counter+1
	return Vector2i(x,y)

func get_source_id(cell_value, tilesets) -> int:
	var source_id: int = 0
	var ts_counter = 0
	for ts in tilesets:
		if cell_value > 0:
			if cell_value >= ts.firstgid:
				source_id = ts_counter
		ts_counter = ts_counter + 1
	return source_id

func get_cell_coord_from_chunk(cell, chunk_width, chunk_height, chunk_x, chunk_y, tileset_data, tilewidth):
	return get_cell_coord(cell, chunk_width, chunk_height, tileset_data, tilewidth, chunk_x, chunk_y)

func get_cell_coord(cell, width, height, tileset_data, base_length, xs:int = 0, ys:int = 0):
	var cellcount = width * height
	var i = 0
	var x = 0
	var y = 0
	var coord = Vector2(x,y)
	while i < cellcount:
		if i == cell: break
		x = x+1
		if x >= width:
			y = y+1
			x = 0
		coord = Vector2(x,y)
		i = i+1
	
	if xs != 0: coord.x = coord.x + xs
	if ys != 0: coord.y = coord.y + ys
	
	var c_changer = 0
	var r_changer = 0
	if tileset_data.tilewidth != base_length:
		c_changer = tileset_data.tilewidth / base_length / 2
	if tileset_data.tileheight != base_length:
		r_changer = tileset_data.tileheight / base_length / 2
	
	return Vector2i(coord.x + c_changer, coord.y - r_changer)
