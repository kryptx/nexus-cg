-- tests/test_helper.lua

-- Get the absolute path to the project root
local current_dir = debug.getinfo(1).source:match("@?(.*/)") or ""
local project_root = current_dir:gsub("tests/$", "")

-- Add the project root to package path
package.path = project_root .. "?.lua;" .. package.path

-- You can add more test setup here if needed 
