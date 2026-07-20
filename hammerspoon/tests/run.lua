package.path = "hammerspoon/?.lua;hammerspoon/tests/?.lua;" .. package.path
local t = require("test_helper")
require("core_test")
require("controller_test")
require("adapter_test")
t.run()
