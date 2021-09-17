--[[

Unit tests for CountDownThenSwitchScene.lua
Author Julia Clement
Licence GPL, same version as CountDownThenSwitchScene.lua

--]]

luaunit = require('luaunit')

obslua={ OBS_INVALID_HOTKEY_ID = 1 }

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

    function TestDecodeWhenTo:test01_return_total_seconds_on_blank()
    	total_seconds = 123
    	luaunit.assertEquals( decode_when_to( "", 0 ), total_seconds )
    end
    
    function TestDecodeWhenTo:test02_return_now_on_0_0_0()
    	total_seconds = 7;
    	local start_time = os.time() -- 10000
    	luaunit.assertEquals( decode_when_to( "+0:0:0", start_time ), start_time )
    end
    
    function TestDecodeWhenTo:test03_plus_m()
    	total_seconds = 7;
    	local start_time = os.time();
    	luaunit.assertEquals( decode_when_to( "+1", start_time ), start_time + 60 )
    end
    
    function TestDecodeWhenTo:test04_plus_hm()
    	total_seconds = 7;
    	local start_time = os.time();
    	luaunit.assertEquals( decode_when_to( "+1:2", start_time ), start_time + 3600 + 120 )
    end
    
    function TestDecodeWhenTo:test05_plus_hms()
    	total_seconds = 7;
    	local start_time = os.time();
    	luaunit.assertEquals( decode_when_to( "+1:2:3", start_time ), start_time + 3600 + 120 + 3 )
    end
    
    function TestDecodeWhenTo:test06_hh_mm_ss()
    	total_seconds = 7;
    	local start_time = os.time({year=2021, month=9, day=17, hour=0, min=0, sec=0});
    	luaunit.assertEquals( decode_when_to( "1:2:3", start_time ), start_time + 3600 + 120 + 3 )
    end
    
    function TestDecodeWhenTo:test07_hh_mm()
    	total_seconds = 7;
    	local start_time = os.time({year=2021, month=9, day=17, hour=0, min=0, sec=0});
    	luaunit.assertEquals( decode_when_to( "2:4", start_time ), start_time + 7200 + 240 )
    end
    
    function TestDecodeWhenTo:test08_mm()
    	total_seconds = 7;
    	local start_time = os.time({year=2021, month=9, day=17, hour=0, min=0, sec=0});
    	luaunit.assertEquals( decode_when_to( "3", start_time ), start_time + 180 )
    end
    
    function TestDecodeWhenTo:test09_dd_mm_hh_mm()
    	total_seconds = 7;
    	local start_time = os.time({year=2021, month=9, day=17, hour=06, min=10, sec=1});
    	luaunit.assertEquals( os.date( "%Y/%m/%d %H:%M:%S", decode_when_to( "22/9 19:30", start_time )), "2021/09/22 19:30:00" )
    end
    
    function TestDecodeWhenTo:test10_dd_mm_yy_hh_mm_ss()
    	total_seconds = 7;
    	local start_time = os.time({year=2021, month=9, day=17, hour=06, min=10, sec=1});
    	luaunit.assertEquals( os.date( "%Y/%m/%d %H:%M:%S", decode_when_to( "22/9/23 19:30:15", start_time )), "2023/09/22 19:30:15" )
    end
    
    function TestDecodeWhenTo:test11_dd_mm_yyyy_hh_mm_ss()
    	total_seconds = 7;
    	local start_time = os.time({year=2021, month=9, day=17, hour=06, min=10, sec=1});
    	luaunit.assertEquals( os.date( "%Y/%m/%d %H:%M:%S", decode_when_to( "13/9/23 19:30:15", start_time )), "2023/09/13 19:30:15" )
    end
    
os.exit(luaunit.LuaUnit.run())

