--[[
OBS Studio script to display a count down timer on screen and when that
expires optionally switch scenes.

Parameters:
	Top Text	Text displayed above remaining time while counting down
				Hidden once timer expires
	When		Text time (with optional date) to end countdown	
	Duration	Minutes to count down from, not used if When used
	Text Source	The text box to display Top Text & remaining time in
	Final Text	Content of Text Source when timer expires
	Switch to scene If set, OBS will switch to this scene when the 
				timer expires

Copyright information

This script is a modification by Julia Clement of the original
countdown.lua made by "Jim" and distributed by Debian with OBS Studio
as version 1:27.0.1-dmo2

https://github.com/obsproject/obs-studio/blob/master/UI/frontend-plugins/frontend-tools/data/scripts/countdown.lua

Some code has been cribbed from another modification of the original
script made by "SiR" https://obsproject.com/forum/resources/count-down-time-and-switch-scene.742/

I can't find individual licences for the original scripts so assume 
they are licenced on the same terms as OBS Studio which uses GPL 2.0
https://github.com/obsproject/obs-studio/blob/master/COPYING hence
this script is licenced under GPL either version 2 or at your
choice any later version adopted by OBS Studio.
--]]
obs           = obslua
source_name   = ""
total_seconds = 0
when_to		  = ""
cur_seconds   = 0
last_text     = ""
stop_text     = ""
top_text     = ""
switch_scene = ""
activated     = false

hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

-- Helper stuff

function isInteger(str)
  if str == nil or str == "" or str:find("%D") then return false end
  return true
end

function isntInteger(str)
  return not isInteger( str )
end

function integer_or_zero( str )
	if str == nil or str == "" or str:find("%D") then return 0 else return tonumber(str) end
end

-- Function to set cur_seconds based on when_to with fallback to total_seconds
-- when to is encoded [dd/mm[/yy] ]hh:mm[:ss] or +[hh:]mm:ss
-- Target of several tests
function decode_when_to( when_to, the_time )
	if when_to == "" then
		cur_seconds = total_seconds
		return total_seconds
	end
	if the_time == nil then the_time = os.time() end
	local hh = 0
	local mi = 0
	local ss = 0
	local p ="(%d+):*(%d*):*(%d*)"
	-- process +[hh:]mm[:ss] -> now()+hh:mm:ss
	if when_to:sub(0,1) == "+" then
		hh,mi,ss=when_to:match(p)
		hh=integer_or_zero( hh)
		if isntInteger(mi) then -- single digit = minutes not hours
			mi = hh
			hh = 0
		end
		ss=integer_or_zero(ss)
		cur_seconds = hh*3600 + mi*60 + ss
		total_seconds = cur_seconds
		return the_time + cur_seconds
	end
	-- process date + time
	local yy = 0
	local mm = 0
	local dd = 0
	dd,mm,yy = when_to:match("(%d+)/(%d+)/*(%d*)")
	local the_date = os.date( "*t", the_time )
	if isInteger( mm ) then 
		-- we have a date
		yy = integer_or_zero( yy )
		mm = integer_or_zero( mm )
		dd = integer_or_zero( dd )
		if dd > 0 then the_date.day = dd end
		if mm > 0 then the_date.month = mm end
		if yy > 2000 then
			the_date.year = yy
		else
			if yy > 0 then
				the_date.year = yy+2000
			end
		end
		when_to = when_to:match( "%d+/%d+/*%d* *(%d+:*%d*:*%d*)")
	end
	
	hh,mi,ss=when_to:match("(%d+):*(%d*):*(%d*)")
	if isntInteger(mi) then -- single digit = minutes not hours
		mi = hh
		hh = nil
	end
	the_date.hour = integer_or_zero ( hh )
	the_date.min = integer_or_zero ( mi )
	the_date.sec = integer_or_zero ( ss )
	new_time = os.time( the_date )
	cur_seconds = new_time - the_time
	total_seconds = cur_seconds
	return new_time
end
-- Function to set the time text
function display_time()
	local seconds       = math.floor(cur_seconds % 60)
	local total_minutes = math.floor(cur_seconds / 60)
	local minutes       = math.floor(total_minutes % 60)
	local total_hours   = math.floor(total_minutes / 60)
	local hours			= math.floor(total_hours % 24)
	local days			= math.floor( total_hours / 24 )
	local text          = ""
	if days > 0 then
		text			=  string.format("%d days %02d:%02d:%02d", days, hours, minutes, seconds)
	else
		text			= string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end
	text = top_text .. "\n" .. text;

	if cur_seconds < 1 then
		text = stop_text
	end

	if text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end

	last_text = text
end

function find_source_by_name_in_list(source_list, name)
  for i, source in pairs(source_list) do
    source_name = obs.obs_source_get_name(source)
    if source_name == name then
      return source
    end
  end

  return nil
end

function activate_scene(switch_scene_name)
  local scenes = obs.obs_frontend_get_scenes()
  local to_scene = find_source_by_name_in_list(scenes, switch_scene_name)
  obs.obs_frontend_set_current_scene(to_scene)
  obs.source_list_release(scenes)
end

function timer_callback()
	cur_seconds = cur_seconds - 1
	if cur_seconds < 0 then
		obs.remove_current_callback()
		cur_seconds = 0
		if switch_scene ~= "" then
			activate_scene( switch_scene )
		end
	end

	display_time()
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		cur_seconds = total_seconds
		display_time()
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset(pressed)
	if not pressed then
		return
	end

	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

function reset_button_clicked(props, p)
	reset(true)
	return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_text(props, "top_text", "Top Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "duration", "Duration (minutes)", 1, 100000, 1)
	local when_to_prop = obs.obs_properties_add_text(props, "when_to", "When to", obs.OBS_TEXT_DEFAULT)
    obs.obs_property_set_long_description(when_to_prop, "Start date and time\n([dd/mm[/yy] ]hh:mm[:ss] or +[hh:]mm:ss)")
	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	obs.obs_properties_add_text(props, "stop_text", "Final Text", obs.OBS_TEXT_DEFAULT)
    local scenedropdown = obs.obs_properties_add_list(props, "scenechoice", "Switch to scene", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    
    local allScenes = obs.obs_frontend_get_scenes()
    for _, sceneSource in ipairs(allScenes) do
		local name = obs.obs_source_get_name(sceneSource)
		obs.obs_property_list_add_string(scenedropdown, name, name)
	end
	obs.source_list_release(allScenes)
	
	obs.obs_properties_add_button(props, "reset_button", "Reset Timer", reset_button_clicked)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Sets a text source to act as a countdown timer when the source is active.\n\nMade by Jim"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	activate(false)

	top_text = obs.obs_data_get_string(settings, "top_text")
	total_seconds = obs.obs_data_get_int(settings, "duration") * 60
	when_to = obs.obs_data_get_string(settings, "when_to")
	if when_to ~= "" then decode_when_to( when_to, os.time() ) end
	source_name = obs.obs_data_get_string(settings, "source")
	switch_scene  = obs.obs_data_get_string(settings,"scenechoice")
	stop_text = obs.obs_data_get_string(settings, "stop_text")

	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "duration", 0)
	obs.obs_data_set_default_string(settings, "when_to", "+05:00")
	obs.obs_data_set_default_string(settings, "top_text", "Show starts in")
	obs.obs_data_set_default_string(settings, "stop_text", "Starting soon (tm)")
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect hotkey and activation/deactivation signal callbacks
	--
	-- NOTE: These particular script callbacks do not necessarily have to
	-- be disconnected, as callbacks will automatically destroy themselves
	-- if the script is unloaded.  So there's no real need to manually
	-- disconnect callbacks that are intended to last until the script is
	-- unloaded.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
	local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end
