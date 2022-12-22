@tool
extends EditorImportPlugin

enum Presets { DEFAULT, PIXEL_ART }

func _get_importer_name():
	return "naddys.tiled_tileset"
	
func _get_visible_name():
	return "Naddys Tiled Tileset"

func _get_recognized_extensions():
	return ["tsx"]

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "TileSet"

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
			return [{
				"name": "contains_collisions",
				"default_value": false
			}]
		Presets.PIXEL_ART:
			return [{
				"name": "contains_collisions",
				"default_value": false
			}]
		_:
			return [{
				"name": "contains_collisions",
				"default_value": false
			}]

func _get_import_order():
	return 98

func _get_option_visibility(path, option_name, options):
	return true

func _import(source_file, save_path, options, platform_variants, gen_files):
	#print("tileset import")
	#print(source_file)
	if !FileAccess.file_exists(source_file):
		return "No File found"
	
	var tileset_creator = load("res://addons/naddys_tiled_maps/tileset_creator.gd").new()
	var tileset = tileset_creator.create_from_file(source_file, options)
	return ResourceSaver.save(tileset, "%s.%s" % [save_path, _get_save_extension()])
