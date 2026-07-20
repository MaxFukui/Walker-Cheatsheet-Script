package.path = "hammerspoon/?.lua;hammerspoon/tests/?.lua;" .. package.path
local t = require("test_helper")
require("core_test")
t.run()
