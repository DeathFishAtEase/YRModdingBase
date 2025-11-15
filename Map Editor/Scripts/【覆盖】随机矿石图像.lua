function is_cru(ovrl)
	if 27 <= ovrl and ovrl <= 38 then return true end
	return false
end
function is_rip(ovrl)
	if 102 <= ovrl and ovrl <= 121 then return true end
	return false
end
function is_vin(ovrl)
	if 127 <= ovrl and ovrl <= 146 then return true end
	return false
end
function is_abo(ovrl)
	if 147 <= ovrl and ovrl <= 166 then return true end
	return false
end

save_undo()
for i,cell in pairs(get_cells()) do
	if is_cru(cell.overlay) then
		cell.overlay = math.random(27, 38)
		cell:apply()
	elseif is_rip(cell.overlay) then
		cell.overlay = math.random(102, 121)
		cell:apply()
	elseif is_vin(cell.overlay) then
		cell.overlay = math.random(127, 146)
		cell:apply()
	elseif is_abo(cell.overlay) then
		cell.overlay = math.random(147, 166)
		cell:apply()
	end
end
save_redo()