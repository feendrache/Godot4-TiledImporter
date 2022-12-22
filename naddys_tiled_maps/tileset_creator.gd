@tool
extends RefCounted

var xml_parser = preload("res://addons/naddys_tiled_maps/tiled_xml_to_dict.gd").new()
var tiled_helper = preload("res://addons/naddys_tiled_maps/tiled_helper.gd").new()

func create_from_file(path, options):
	var parsed_data = xml_parser.read_tsx(path)
	return create_tileset([parsed_data], path, options)

func create_tileset(sets_to_parse, path, options = {}):
	var tileset = TileSet.new()
	
	for set in sets_to_parse:
		if set == null: continue
		var base_path = path
		var atlas_source = TileSetAtlasSource.new()
		
		if "source" in set:
			var source_path = path.get_base_dir().path_join(set.source)
			set = xml_parser.read_tsx(source_path)
			options = read_options(source_path)
			base_path = source_path
			
		var collision_physics_layer = 0
		if options.contains_collisions:
			tileset.add_physics_layer(collision_physics_layer)
		
		atlas_source.resource_name = StringName(set.name)
		atlas_source.texture = get_image(base_path.get_base_dir(), set.image)
		
		var firstgid = 0
		if "firstgid" in set: firstgid = set.firstgid
		var columns = 0
		if "columns" in set: columns = set.columns
		var tilesize = Vector2i(int(set.tilewidth), int(set.tileheight))
		var tilecount = set.tilecount
		
		var i = 0
		var c = 0
		var r = 0
		var gid = firstgid
		
		if "wangsets" in set:
			var set_counter = 0
			for wangset in set.wangsets:
				tileset.add_terrain_set(set_counter)
				match wangset.type:
					"corner":
						tileset.set_terrain_set_mode(set_counter, TileSet.TERRAIN_MODE_MATCH_CORNERS)
				var color_counter = 0
				for color in wangset.wangdata.colors:
					tileset.add_terrain(set_counter, color_counter)
					tileset.set_terrain_name(set_counter, color_counter, color.name)
					tileset.set_terrain_color(set_counter, color_counter, Color(color.color))
					color_counter = color_counter+1
				
				set_counter = set_counter+1
		
		while i < tilecount:
			var relid = gid - firstgid
			var tile_coords = Vector2i(c,r)
			c = c+1
			if c >= columns:
				r = r+1
				c = 0
			if atlas_source.get_tile_at_coords(tile_coords) == Vector2i(-1,-1):
				atlas_source.create_tile(tile_coords)
				if atlas_source.has_tile(tile_coords):
					var flip_h = atlas_source.create_alternative_tile(tile_coords)
					var flip_h_data = atlas_source.get_tile_data(tile_coords, flip_h)
					flip_h_data.flip_h = true
					var flip_v = atlas_source.create_alternative_tile(tile_coords)
					var flip_v_data = atlas_source.get_tile_data(tile_coords, flip_v)
					flip_v_data.flip_v = true
					var flip_b = atlas_source.create_alternative_tile(tile_coords)
					var flip_b_data = atlas_source.get_tile_data(tile_coords, flip_b)
					flip_b_data.flip_h = true
					flip_b_data.flip_v = true
			if "tiles" in set && str(relid) in set.tiles:
				var tile_data = set.tiles[str(relid)]
				if "animation" in tile_data:
					if atlas_source.get_tile_at_coords(tile_coords) == tile_coords:
						var anim_separation = get_anim_separation(tile_data, columns)
						atlas_source.set_tile_animation_separation(tile_coords, anim_separation)
						atlas_source.set_tile_animation_columns(tile_coords, tile_data.animation.size())
						atlas_source.set_tile_animation_frames_count(tile_coords, tile_data.animation.size())
						for fc in tile_data.animation.size():
							atlas_source.set_tile_animation_frame_duration(tile_coords, fc, 0.3)
						#var anim_counter = 0
						#for anim in tile_data.animation:
						#	var anim_coords = Vector2i(tile_coords.x+anim_separation.x, tile_coords.y+anim_separation.y)
						#	var duration = 0.3
						#	if atlas_source.get_tile_at_coords(anim_coords) != Vector2i(-1,-1):
						#		duration = float(str_to_var(anim.duration)) / 1000
						#	atlas_source.set_tile_animation_frame_duration(tile_coords, anim_counter, duration)
						#	anim_counter = anim_counter + 1
				if "objectgroup" in tile_data:
					#print(tile_data.objectgroup)
					var tile_data_obj = atlas_source.get_tile_data(tile_coords,0)
					if tile_data_obj != null:
						if options.contains_collisions:
							var collision_counter = 0
							for object in tile_data.objectgroup.objects:
								var points = tiled_helper.vectorarray_from_object(object)
								#print(points)
								#tile_data_obj.add_collision_polygon(collision_physics_layer)
								#tile_data_obj.set_collision_polygon_points(collision_physics_layer,collision_counter,points)
								collision_counter = collision_counter+1
			if "wangsets" in set:
				if atlas_source.get_tile_at_coords(tile_coords) == tile_coords:
					var set_counter = 0
					for wangset in set.wangsets:
						if relid in wangset.wangdata.tiles:
							var tile_data = atlas_source.get_tile_data(tile_coords,0)
							if tile_data != null:
								tile_data.terrain_set = set_counter
								var wang_settings = wangset.wangdata.tiles[relid].wangid.split(',')
								var trc = int(str_to_var(wang_settings[1])) - 1
								tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, trc)
								var brc = int(str_to_var(wang_settings[3])) - 1
								tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, brc)
								var blc = int(str_to_var(wang_settings[5])) - 1
								tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, blc)
								var tlc = int(str_to_var(wang_settings[7])) - 1
								tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, tlc)
								#print(wangset.wangdata.tiles[relid])
						set_counter = set_counter+1
			i = i+1
			gid = gid+1
		#tileset.tile_size = tilesize
		atlas_source.texture_region_size = tilesize
		tileset.add_source(atlas_source)
	
	return tileset

func get_anim_separation(tile_data, columns):
	var separation = Vector2i.ZERO
	
	var anim_columns = int(str_to_var(tile_data.animation[1].tileid)) - int(str_to_var(tile_data.animation[0].tileid))
	if anim_columns > columns:
		var rest = anim_columns%columns
		separation.x = rest
		separation.y = floori(anim_columns/columns) - 1
	else:
		separation.x = anim_columns - 1
	
	return separation

func get_image(path, file):
	return load(path.path_join(file))

func read_options(path):
	var options = {}
	var config := ConfigFile.new()
	var err = config.load(path+".import")
	if err != OK:
		printerr("Import File for TSX missing, please import the base tileset file again")
	else:
		options["contains_collisions"] = config.get_value("params","contains_collisions",false)
	return options
