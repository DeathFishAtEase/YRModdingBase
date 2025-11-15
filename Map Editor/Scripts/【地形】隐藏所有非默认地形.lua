base = get_integer("General", "ClearTile", 0, "theater")
for i=0,tile_set_count() do
	if i ~= base then
		hide_tile_set(i)
	end
end