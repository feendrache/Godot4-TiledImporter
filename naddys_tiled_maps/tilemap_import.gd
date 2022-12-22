@tool
extends EditorImportPlugin

enum Presets { DEFAULT, PIXEL_ART }

func _get_importer_name():
	return "naddys.tiled_tilemap"
	
func _get_visible_name():
	return "Naddys Tiled Tilemap"

func _get_recognized_extensions():
	return ["tmx"]

func _get_save_extension():
	return "scn"

func _get_resource_type():
	return "PackedScene"

func _get_priority():
	return 1

func _get_preset_count():
	return Presets.size()

func _get_preset_name(preset_index):
	match preset_index:
		Presets.DEFAULT: return "Default"
		Presets.PIXEL_ART: return "PixelArt"
		_: return "Unknown"

func _get_import_options(path, preset_index):
	match preset_index:
		Presets.DEFAULT:
			return []
		Presets.PIXEL_ART:
			return []
		_:
			return []

func _get_import_order():
	return 99

func _get_option_visibility(path, option_name, options):
	return true

func _import(source_file, save_path, options, platform_variants, gen_files):
	#print("import tilemap")
	#print(source_file)
	if !FileAccess.file_exists(source_file):
		return "No File found"
	
	var tilemap_creator = load("res://addons/naddys_tiled_maps/tilemap_creator.gd").new()
	var tilemap = tilemap_creator.create_from_file(source_file)
	if typeof(tilemap) != TYPE_OBJECT:
		# Error happened
		#print(tilemap)
		return tilemap
	#print (tilemap)
	var packed_scene = PackedScene.new()
	packed_scene.pack(tilemap)
	return ResourceSaver.save(packed_scene, "%s.%s" % [save_path, _get_save_extension()])
