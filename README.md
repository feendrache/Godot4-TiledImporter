# Godot4-TiledImporter
Import Tiled Maps into Godot 4

Currently in Alpha State

What the plugin can do:
- import Tilesets from Tiled, usable as Tilesets in Godot like Godot-Tilesets
- import Tilemap from Tiled, usable as Tilemap with Layers lile Godot-Tilemaps

What the plugin can not do (maybe yet):
- import Objects from Object-Layer
- import Collisions in Tilesets since this is still bugged in Godot4 Alpha 9

There are Importers for the FileTypes shown in the "Import" Tab when a Tileset or Tilemap is selected

Tilesets:
- Animations are imported
- For each Tile created in the Tileset the importer created three alternative Tiles: 
  1. flipped horizontal
  2. flipped vertical
  3. flipped vertical and horizontal
- Collision import is planned, the option to check is already presented in the importer but won't work

Tilemap:
- It imports with the reference of the Tilesets, so import the Tilesets first
- It may take a while to import and currently some Godot closings happen that i wasn't able to get a real clue why
- To get the flipped Tiles into godot i chose the alterntive-Tile way for the Tilesets. So the importer uses the alternative Tiles where needed

A Short List of things that may be interesting for using it: https://github.com/feendrache/Godot4-TiledImporter/blob/main/short-notes-how-to-use.txt
I will add a more detailed Tutorial as soon as Godot 4 is out of beta and is more clear what still needs  to be adjusted in the importer
