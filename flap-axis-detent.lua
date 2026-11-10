-- Flap Axis Detent 1.6
-- https://github.com/lrdn/flap-axis-detent
-- Copyright (c) 2019 LRDN <git@lrdn.net>
-- Released under the MIT license

flap_ratio_dataref = {
	"laminar/B738/axis/flap_lever",
	"ixeg/733/hydraulics/hyd_flap_lever_act",
	"Rotate/md80/systems/flap_handle_drag_position_ratio",
	"sim/cockpit2/controls/flap_handle_request_ratio",
	"sim/cockpit2/controls/flap_ratio"
}

for index, candidate in ipairs(flap_ratio_dataref) do
	if XPLMFindDataRef(candidate) ~= nil then
		flap_ratio_dataref = candidate
		break
	end
end

if type(flap_ratio_dataref) == "table" then
	flap_ratio_dataref = nil
end

for index = 0, 499 do
	if get("sim/joystick/joystick_axis_assignments", index) == 11 then
		config = io.open(SCRIPT_DIRECTORY .. "flap-axis-detent-v2.cfg", "w+")
		config:write(index)
		config:close()
	end
end

config = io.open(SCRIPT_DIRECTORY .. "flap-axis-detent-v2.cfg", "r")

if config ~= nil then
	flap_axis = tonumber(config:read())
	config:close()
end

if flap_axis ~= nil and flap_ratio_dataref ~= nil then
	flap_axis_assignment = get("sim/joystick/joystick_axis_assignments", flap_axis)
	flap_axis_reverse = get("sim/joystick/joystick_axis_reverse", flap_axis)

	if flap_axis_assignment == 0 or flap_axis_assignment == 11 then
		dataref("flap_axis_min", "sim/joystick/joystick_axis_minimum", "readonly", flap_axis)
		dataref("flap_axis_max", "sim/joystick/joystick_axis_maximum", "readonly", flap_axis)
		dataref("flap_axis", "sim/joystick/joystick_axis_values", "readonly", flap_axis)
		dataref("flap_detents", "sim/aircraft/controls/acf_flap_detents", "readonly")
		dataref("flap_ratio", flap_ratio_dataref, "writeable")

		-- Guard against NaN/Inf reaching the flight model: an aircraft with
		-- zero flap detents or a stale axis index with an empty calibration
		-- range (min == max) would otherwise divide by zero and crash X-Plane
		-- with "Airfoil AOAinduced NAN"
		if flap_detents >= 1 and flap_axis_max > flap_axis_min then
			set_axis_assignment(flap_axis, "none", (flap_axis_reverse == 1 and "reverse") or "normal")

			flap_step = 1.0 / flap_detents
			flap_axis_last = 0

			function update_flap_ratio()
				if math.abs(flap_axis_last - flap_axis) > 0.0005 then
					flap_axis_last = flap_axis
					flap_axis_range = flap_axis_max - flap_axis_min

					if flap_axis_range > 0 then
						flap_axis_map = math.abs(flap_axis_reverse - (flap_axis - flap_axis_min) / flap_axis_range)

						if flap_axis_map == flap_axis_map then
							if flap_axis_map < 0 then flap_axis_map = 0 end
							if flap_axis_map > 1 then flap_axis_map = 1 end

							flap_ratio = math.floor((flap_axis_map / flap_step) + 0.5) * flap_step
						end
					end
				end
			end

			do_every_frame("update_flap_ratio()")
		else
			logMsg("flap-axis-detent: disabled (flap detents = " .. tostring(flap_detents)
				.. ", axis " .. tostring(flap_axis) .. " range = [" .. tostring(flap_axis_min)
				.. ", " .. tostring(flap_axis_max) .. "])")
		end
	end
end
