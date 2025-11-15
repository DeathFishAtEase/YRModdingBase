Clear = get_integer("General", "ClearTile", 0, "theater")
Rough = get_integer("General", "RoughTile", 0, "theater")
Sand = get_integer("General", "SandTile", 0, "theater")
Green = get_integer("General", "GreenTile", 0, "theater")
Pave = get_integer("General", "PaveTile", 0, "theater")
RoughLat = get_integer("General", "ClearToRoughLat", 0, "theater")
SandLat = get_integer("General", "ClearToSandLat", 0, "theater")
GreenLat = get_integer("General", "ClearToGreenLat", 0, "theater")
PaveLat = get_integer("General", "ClearToPaveLat", 0, "theater")

for i=0,tile_set_count() do
	if i ~= Clear and i ~= Rough and i ~= Sand and i ~= Green and i ~= Pave and i ~= RoughLat
	and i ~= SandLat and i ~= GreenLat and i ~= PaveLat then
		hide_tile_set(i)
	end
end