@tool
extends EditorPlugin

var tileset_import = null
var tilemap_import = null

func get_name():
	return "Naddys Tiled Maps"

func _enter_tree():
	tileset_import = preload("res://addons/naddys_tiled_maps/tileset_import.gd").new()
	add_import_plugin(tileset_import)
	tilemap_import = preload("res://addons/naddys_tiled_maps/tilemap_import.gd").new()
	add_import_plugin(tilemap_import)


func _exit_tree():
	remove_import_plugin(tileset_import)
	tileset_import = null
	remove_import_plugin(tilemap_import)
	tilemap_import = null
