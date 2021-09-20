--[[

Dummy obslua Objects for unit tests for my OBS extensions
This would have been nicer done as Mock objects, but obslua is
a namespace not a class and Mocks would have massively increased the
work required for little benefit.

Author Julia Clement 2021
Licence GPL, same version as CountDownThenSwitchScene.lua

I'm only adding what I need to test my code & not necessarily following
the documentation closely.

--]]


obsluaDummy={ OBS_INVALID_HOTKEY_ID = 1, OBS_COMBO_TYPE_EDITABLE = 2, OBS_COMBO_FORMAT_STRING = 3, classname = "obsluaDummy"}
obsluaDummy.__index = obsluaDummy

-- obslua is a singleton accessed with . not : notation, but we need somewhere convenient to store data
obsluaDummy.Data={}
obsluaDummy.Data.__index = obsluaDummy.Data
obsluaDummy.Data.classname="obsluaDummy.Data"
function obsluaDummy.Data:new( )
	o = {}
	setmetatable(o, self)
	o.__index = self
	o.sources={}
	o.scenes={}
  o.active_scene=nil
	o.properties=nil
	return o
end

function obsluaDummy.reset( )
	obsluaDummy.data = obsluaDummy.Data:new()
end

-- Data object
-- a way of getting data into other objects
-- Implementation is a gross oversimplification, but I think this is all we need for now
obsluaDummy.obs_data_t = {}
obsluaDummy.obs_data_t.__index=obsluaDummy.obs_data_t
obsluaDummy.obs_data_t.classname="obs_data_t"
function obsluaDummy.obs_data_t:new()
  local o = {}
	setmetatable(o, self)
	o.__index = self
  o.name = ""
  o.value = ""
  return o
end
function obsluaDummy.obs_data_t:set_string( name, value )
  self.name = name
  self.value = value
end
function obsluaDummy.obs_data_t:get_text()
  return self.value
end
function obsluaDummy.obs_data_create() return obsluaDummy.obs_data_t:new() end
function obsluaDummy.obs_data_set_string(data, name, value) data:set_string( name, value ) end
-- TODO - do we need different routines?
function obsluaDummy.obs_data_set_array(data, name, value)
  --data:set_string( name, value )
end
function obsluaDummy.obs_data_release(data)
  -- C memory management, does nothing here
end

-- Property

obsluaDummy.obs_property_t = {}
obsluaDummy.obs_property_t.__index=obsluaDummy.obs_property_t
obsluaDummy.obs_property_t.classname="obs_property_t"
function obsluaDummy.obs_property_t:new( thename, thedescription, theproptype, theformat )
	local o = {}
	setmetatable(o, self)
	o.__index = self
  o:construct( thename, thedescription, theproptype, theformat )
  return o
end
function obsluaDummy.obs_property_t:construct( thename, thedescription, theproptype, theformat )
	self.name=thename
	self.description=thedescription
	self.proptype=theproptype
	self.format=theformat
	self.longdescription=""
  self.value=""
  self.default_value=""
  -- included
  return self
end  

function obsluaDummy.obs_property_t:set_long_description( description )
  self.longdescription = description
end	 

function obsluaDummy.obs_property_t:set_default_string(val)
  self.default_value = val
  if self.value=="" then 
    self.value = val
  end
end	 

function obsluaDummy.obs_property_t:get_string()
  return self.value
end

-- This should be a subclass, but I just can't make that work.
obsluaDummy.obs_list_property_t = {}
obsluaDummy.obs_list_property_t.__index=obsluaDummy.obs_list_property_t
obsluaDummy.obs_list_property_t.classname="obs_list_property_t"
obsluaDummy.obs_list_property_t.set_long_description = obsluaDummy.obs_property_t.set_long_description
obsluaDummy.obs_list_property_t.set_default_string = obsluaDummy.obs_property_t.set_default_string
obsluaDummy.obs_list_property_t.get_string = obsluaDummy.obs_property_t.get_string
function obsluaDummy.obs_list_property_t:new( thename, thedescription, theproptype, theformat )
	local o = {}
	setmetatable(o, self)
	o.__index = self
  obsluaDummy.obs_property_t.construct( o, thename, thedescription, theproptype, theformat )
	o.listitems={}
	return o
end

function obsluaDummy.obs_list_property_t:add_key_plus_string( key, string )
	self.listitems[ key ] = string
end	

-- Properties. A collection of propety objects

obsluaDummy.obs_properties_t = {  }
obsluaDummy.obs_properties_t.__index=obsluaDummy.obs_properties_t
obsluaDummy.obs_properties_t.classname="obs_properties_t"
function obsluaDummy.obs_properties_t:add_text(name, description, proptype) 
	local o = obsluaDummy.obs_property_t:new(name, description, proptype, nil)
	self.props[name]= o
	return o
end

function obsluaDummy.obs_properties_t:add_list(name, description, proptype, format) 
	local o = obsluaDummy.obs_list_property_t:new(name, description, proptype, format)
	self.props[name]= o
	return o
end


function obsluaDummy.obs_properties_t:add_button( name, description, callback )
	local o = obsluaDummy.obs_property_t:new(name, description, 0, callback)
	self.props[name]= o
	return o
end

function obsluaDummy.obs_properties_t:set_default_string( name, val )
  for propname,property in pairs(self.props) do
    if propname == name then
      property:set_default_string(val)
      break
    end
  end
end  

function obsluaDummy.obs_properties_t:get_string( name)
  for propname,property in pairs(self.props) do
    if propname == name then
      return property:get_string()
    end
  end
end

function obsluaDummy.obs_properties_t:new( )
	local o = {}
	setmetatable(o, self)
	o.__index = self
	o.props= {}
	return o
end

function obsluaDummy.obs_properties_create()
	local o = obsluaDummy.obs_properties_t:new()
	obsluaDummy.data.properties = o
	return o
end	

function obsluaDummy.obs_properties_add_text( props, name, description, proptype )
	return props:add_text( name, description, proptype )
end

function obsluaDummy.obs_properties_add_list( props, name, description, proptype, propformat )
	return props:add_list( name, description, proptype, propformat )
end

function obsluaDummy.obs_property_list_add_string( the_list, name, description )
	return the_list:add_key_plus_string( name, description )
end

function obsluaDummy.obs_properties_add_button( props, name, description, callback )
	return props:add_button( name, description, callback )
end

-- Scenes

obsluaDummy.obs_scene_t = {}
obsluaDummy.obs_scene_t.__index=obsluaDummy.obs_scene_t
obsluaDummy.obs_scene_t.classname="obs_scene_t"
function obsluaDummy.obs_scene_t:get_name() return self.name end

function obsluaDummy.obs_scene_t:new( thename )
	o = {}
	setmetatable(o, self)
	o.__index = self
	o.name=thename
  o.active=false
	return o
end

function obsluaDummy.obs_scene_t:get_name()
	return self.name
end	

function obsluaDummy.obs_scene_t:set_active( active )
  if active then
    if obsluaDummy.data.active_scene ~= nil then
      obsluaDummy.data.active_scene:set_active( false )
    end
    obsluaDummy.data.active_scene = self
  else
    if self.active then
      obsluaDummy.data.active_scene = nil
    end
  end
	self.active=active
end

function obsluaDummy.obs_scene_create(name)
	local o = obsluaDummy.obs_scene_t:new(name)
	obsluaDummy.data.scenes[ name ] = o
	return o
end

function obsluaDummy.obs_frontend_get_scenes()
  -- we store scenes keyed by name, the OBS routine returns a numeric indexed array
  local answer={}
  local i = 0
  local scene
  for _,scene in pairs(obsluaDummy.data.scenes) do
    i = i + 1
    answer[ i ] = scene
  end
  return answer
end


-- Sources

obsluaDummy.obs_source_t = {}
obsluaDummy.obs_source_t.__index=obsluaDummy.obs_source_t
obsluaDummy.obs_source_t.classname="obs_source_t"
function obsluaDummy.obs_source_t:get_unversioned_id() return self.id end
function obsluaDummy.obs_source_t:get_name() return self.name end

function obsluaDummy.obs_source_t:new( the_id, thename, the_active )
	o = {}
	setmetatable(o, self)
	o.__index = self
	o.id=the_id
	o.name=thename
  o.text = ""
  o.is_active = the_active or false -- allow for nil
	return o
end

function obsluaDummy.obs_source_t:get_name()
	return self.name
end

function obsluaDummy.obs_source_t:set_text( text )
	self.text = text
end

function obsluaDummy.obs_source_t:get_text()
	return self.text
end

function obsluaDummy.obs_get_source_by_name(name)
	return obsluaDummy.data.sources[name]
end

function obsluaDummy.obs_source_active(source)
  return source.is_active
end

function obsluaDummy.obs_source_create(id, name, settings, hotkey_data)
	local o = obsluaDummy.obs_source_t:new(id, name,true)
	obsluaDummy.data.sources[ name ] = o
	return o
end

function obsluaDummy.obs_source_update(source, data) source:set_text( data:get_text() ) end

function obsluaDummy.obs_enum_sources()
	local o = {}
	local i = 0
	local ign
	local source
	for ign, source in pairs(obsluaDummy.data.sources) do
		i=i+1
		o[i]=source
	end
	if i == 0 then return nil end
	return o
end

function obsluaDummy.obs_source_get_unversioned_id(source) return source:get_unversioned_id() end
function obsluaDummy.obs_source_get_name(source) return source:get_name() end
function obsluaDummy.obs_property_set_long_description( prop, long_description)
	prop:set_long_description( long_description)
end	
-- Casts a pointer parameter of a calldata_t object to an obsluaDummy.obs_source_t object.
function obsluaDummy.calldata_source(calldata, name)
  local find_name = calldata:get_text()
	local this_source
	for _, this_source in pairs(obsluaDummy.data.sources) do
		if this_source:get_name() == find_name then
			return this_source
		end
	end
end

function obsluaDummy.obs_source_get_name(scene_source) return scene_source:get_name() end

function obsluaDummy.obs_frontend_set_current_scene(to_scene)
  if to_scene ~= nil then
    to_scene:set_active( true )
  end
end

function obsluaDummy.obs_source_release(source)
	-- C memory management, does nothing here
end	

function obsluaDummy.source_list_release(source)
	-- C memory management, does nothing here
end


-- Automation / hooks
function obsluaDummy.obs_data_set_default_string(data, name, val)
  data:set_default_string( name, val )
end 

function obsluaDummy.obs_data_get_string(data, name)
  return data:get_string( name )
end 

function obsluaDummy.obs_data_get_array(data, name)
  return data:get_string( name )
end 

function obsluaDummy.timer_add(callback, msec)
  -- dummy 
end 

function obsluaDummy.timer_remove(callback)
  -- dummy 
end 

function obsluaDummy.remove_current_callback()
  -- dummy
end

function obsluaDummy.obs_get_signal_handler()
  return {}
end

function obsluaDummy.signal_handler_connect(sh, desc, callback)
  end

-- Can't find documentation on what this is
function obsluaDummy.obs_hotkey_save(hotkey_id)
    local answer = {}
    answer[1] = hotkey_id
    return answer
  end

function obsluaDummy.obs_hotkey_load(hotkey_id, hotkey_save_array)
end

function obsluaDummy.obs_hotkey_register_frontend(sh, desc, reset)
  return 17
end

function obsluaDummy.obs_data_array_release(sh)
  -- C++ memory management, not relevant for us
end

