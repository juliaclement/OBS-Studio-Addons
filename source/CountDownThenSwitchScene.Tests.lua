--[[

Unit tests for CountDownThenSwitchScene.lua
Author Julia Clement
Licence GPL, same version as CountDownThenSwitchScene.lua

These are very simplistic, their main purpose in the initial 
commit is to catch any 
breakages as I make further modifications to the script.

They do provide 100% code coverage as reported by luacov

--]]

-- luacov: disable
luaunit = require('luaunit')
-- luacov: enable

require('obsluaDummy')
obsluaDummy.reset()
obslua = obsluaDummy

require('CountDownThenSwitchScene')

local now = os.time();


TestIntegers = {} --class
    -- As isntInteger is just a negation of isInteger we don't need to test both
    function TestIntegers:test1_nil_isnt_number()
    	luaunit.assertTrue( isntInteger() )
    end
    function TestIntegers:test2_space_isnt_number()
    	luaunit.assertTrue( isntInteger( "" ) )
    end
    function TestIntegers:test3_alpha_isnt_number()
    	luaunit.assertTrue( isntInteger( "one" ) )
    end
    function TestIntegers:test4_digit_is_number()
    	luaunit.assertFalse( isntInteger( "1" ) )
    end
    function TestIntegers:test5_digits_are_number()
    	luaunit.assertFalse( isntInteger( "123" ) )
    end
    function TestIntegers:test6_nil_to_zero()
    	luaunit.assertEquals( integer_or_zero( ), 0 )
    end
    function TestIntegers:test7_empty_to_zero()
    	luaunit.assertEquals( integer_or_zero( "" ), 0 )
    end
    function TestIntegers:test8_non_digits_to_zero()
    	luaunit.assertEquals( integer_or_zero( "A" ), 0 )
    end
    function TestIntegers:test9_number_to_number()
    	luaunit.assertEquals( integer_or_zero( "123" ), 123 )
    end
    
TestDecodeWhenTo = {} --class

    function TestDecodeWhenTo:test01_return_plus_5_minutes_on_blank()
    	luaunit.assertEquals( decode_when_to( "", 10000 ), 10300 )
    end
    
    function TestDecodeWhenTo:test02_return_now_on_0_0_0()
    	local start_time = os.time()
    	luaunit.assertEquals( decode_when_to( "+0:0:0", start_time ), start_time )
    end
    
    function TestDecodeWhenTo:test03_plus_m()
    	local start_time = os.time();
    	luaunit.assertEquals( decode_when_to( "+1", start_time ), start_time + 60 )
    end
    
    function TestDecodeWhenTo:test04_plus_hm()
    	local start_time = os.time();
    	luaunit.assertEquals( decode_when_to( "+1:2", start_time ), start_time + 3600 + 120 )
    end
    
    function TestDecodeWhenTo:test05_plus_hms()
    	local start_time = os.time();
    	luaunit.assertEquals( decode_when_to( "+1:2:3", start_time ), start_time + 3600 + 120 + 3 )
    end
    
    function TestDecodeWhenTo:test06_hh_mm_ss()
    	local start_time = os.time({year=2021, month=9, day=17, hour=0, min=0, sec=0});
    	luaunit.assertEquals( decode_when_to( "1:2:3", start_time ), start_time + 3600 + 120 + 3 )
    end
    
    function TestDecodeWhenTo:test07_hh_mm()
    	local start_time = os.time({year=2021, month=9, day=17, hour=0, min=0, sec=0});
    	luaunit.assertEquals( decode_when_to( "2:4", start_time ), start_time + 7200 + 240 )
    end
    
    function TestDecodeWhenTo:test08_mm()
    	local start_time = os.time({year=2021, month=9, day=17, hour=0, min=0, sec=0});
    	luaunit.assertEquals( decode_when_to( "3", start_time ), start_time + 180 )
    end
    
    function TestDecodeWhenTo:test09_dd_mm_hh_mm()
    	local start_time = os.time({year=2021, month=9, day=17, hour=06, min=10, sec=1});
    	luaunit.assertEquals( os.date( "%Y/%m/%d %H:%M:%S", decode_when_to( "22/9 19:30", start_time )), "2021/09/22 19:30:00" )
    end
    
    function TestDecodeWhenTo:test10_dd_mm_yy_hh_mm_ss()
    	local start_time = os.time({year=2021, month=9, day=17, hour=06, min=10, sec=1});
    	luaunit.assertEquals( os.date( "%Y/%m/%d %H:%M:%S", decode_when_to( "22/9/23 19:30:15", start_time )), "2023/09/22 19:30:15" )
    end
    
    function TestDecodeWhenTo:test11_dd_mm_yyyy_hh_mm_ss()
    	local start_time = os.time({year=2021, month=9, day=17, hour=06, min=10, sec=1});
    	luaunit.assertEquals( os.date( "%Y/%m/%d %H:%M:%S", decode_when_to( "13/9/2023 19:30:15", start_time )), "2023/09/13 19:30:15" )
    end
    
TestFunctions = {}
    function TestFunctions:setUp()
    	obsluaDummy.reset();
    	obsluaDummy.obs_source_create("Camera", "Camera", nil, nil)
    	self.countdown = obsluaDummy.obs_source_create("text_gdiplus", "Countdown", nil, nil)
    	obsluaDummy.obs_scene_create("Before Show")
    	obsluaDummy.obs_scene_create("In Show")
    	obsluaDummy.obs_scene_create("After Show")
      self.script_props = script_properties()
      script_defaults(self.script_props)
      switch_scene="In Show"
    	obs=obsluaDummy
    	obslua=obs
    	set_obs(obs)
    end
    function TestFunctions:test01_script_properties()
    	luaunit.assertEquals( obs.obs_data_get_string(self.script_props, "top_text"), "Show starts in")
    end
    -- activate a scene, check it's active
    -- activate another scene, check it's active and the first one isn't
    function TestFunctions:test02_activate_scene()
      activate_scene("Before Show")
      local before_show = obs.data.active_scene
      luaunit.assertNotNil( before_show )
      luaunit.assertEquals( before_show:get_name(), "Before Show" )
      luaunit.assertTrue( before_show.active )
      activate_scene("In Show")
      local in_show = obs.data.active_scene
      luaunit.assertEquals( in_show:get_name(), "In Show" )
      luaunit.assertTrue( in_show.active )
      luaunit.assertFalse( before_show.active )
    end
    -- Check activating a scene that doesn't exist has no effect
    function TestFunctions:test03_activate_scene()
      activate_scene("Before Show")
      local before_show = obs.data.active_scene
      activate_scene("Not There")
      luaunit.assertEquals( before_show, obs.data.active_scene )
      luaunit.assertTrue( before_show.active )
    end
    -- Check deactivating the active scene doesn't cause a crash
    function TestFunctions:test04_deactivate_scene()
      activate_scene("Before Show")
      local before_show = obs.data.active_scene
      before_show:set_active( false );
      luaunit.assertNil( obs.data.active_scene )
    end
    -- Check time can be displayed
    function TestFunctions:test05_display_time()
      activate_scene("Before Show")
      source_name = "Countdown"
      local source = obsluaDummy.obs_get_source_by_name(source_name)
      luaunit.assertNotNil( source )
      source:set_text("Random text")
      display_time()
      -- TODO: Check the time is right
      -- TODO: Check time expired handled correctly
      luaunit.assertStrContains( source:get_text(), top_text )
    end
    -- test timer callback state
    function TestFunctions:check_post_callback( expected_cur_seconds, active_scene_name, expected_text )
      luaunit.assertEquals( cur_seconds, expected_cur_seconds )
      luaunit.assertNotNil( obs.data.active_scene )
      local active_scene_name = obs.data.active_scene:get_name()
      luaunit.assertEquals( active_scene_name, active_scene_name )
      luaunit.assertStrContains( self.countdown:get_text(), expected_text )
      
    end
    -- check timer callback decrements cur_seconds but doesn't switches until -1
    -- TODO - bad design, split
    function TestFunctions:test06_callback()
      activate_scene("Before Show")
      source_name = "Countdown"
      stop_text = "Stop text"
      local start_time = os.time()
      decode_when_to( "+00:00:03", start_time )
      timer_callback()
      self:check_post_callback(2, "Before Show", "00:00:02")
      timer_callback()
      self:check_post_callback(1, "Before Show", "00:00:01")
      timer_callback()
      self:check_post_callback(0, "Before Show", "Stop text")
      -- when timer goes to -1, the scene switch happens & timer is forced back to 0
      timer_callback()
      self:check_post_callback(0, "In Show", "Stop text")
    end
    -- check timer callback switches on switch_at
    -- TODO - bad design, split
    function TestFunctions:test09_callback()
      activate_scene("Before Show")
      source_name = "Countdown"
      stop_text = "Stop text"
      local start_time = os.time()
      decode_when_to( "+00:01:03", start_time )
      switch_on = 60
      timer_callback()
      self:check_post_callback(62, "Before Show", "00:01:02")
      timer_callback()
      self:check_post_callback(61, "Before Show", "00:01:01")
      timer_callback()
      self:check_post_callback(60, "In Show", "00:01:00")
      -- when timer goes to -1, the scene switch happens & timer is forced back to 0
      timer_callback()
      self:check_post_callback(59, "In Show", "00:00:59")
    end
    
    function TestFunctions:test10_source_actived()
      activate_scene("Before Show")
      activated = false
      cd=obsluaDummy.obs_data_t:new()
      cd:set_string( "source", "Countdown" )
      source_activated(cd)
      luaunit.assertEquals( activated, true )
    end
    
    function TestFunctions:test11_source_deactived()
      activate_scene("Before Show")
      activated = true
      cd=obsluaDummy.obs_data_t:new()
      cd:set_string( "source", "Countdown" )
      source_deactivated(cd)
      luaunit.assertEquals( activated, false )
    end
      

TestMisc = {}
    function TestMisc:setUp()
    	obsluaDummy.reset();
    	obsluaDummy.obs_source_create("Camera", "Camera", nil, nil)
    	self.countdown = obsluaDummy.obs_source_create("text_gdiplus", "Countdown", nil, nil)
    	obsluaDummy.obs_scene_create("Before Show")
    	obsluaDummy.obs_scene_create("In Show")
    	obsluaDummy.obs_scene_create("After Show")
      self.script_props = script_properties()
      script_defaults(self.script_props)
    	obs=obsluaDummy
    	obslua=obs
    	set_obs(obs)
    end
    function TestMisc:test01_script_description()
    	luaunit.assertStrContains( script_description(), "Sets a text source")
    end
    -- TODO I have no idea how to test these routines
    function TestMisc:test02_reset_button_clicked()
    	luaunit.assertEquals( reset_button_clicked(), false)
    end
    function TestMisc:test03_script_save()
      script_save( self.script_props )
    end
    function TestMisc:test04_script_load()
      script_load( self.script_props )
    end
    function TestMisc:test05_script_update()
      script_update( self.script_props )
    end
    
os.exit(luaunit.LuaUnit.run())

