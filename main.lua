-- /main.lua (Project Root)
-- Bootstrapper for running the game from the src/ directory

-- Add the 'src' directory to Lua's package path
-- This allows require('module') instead of require('src.module') within src files
-- and require('src.module') from this file.
package.path = package.path .. ';./src/?.lua'

-- Set the source directory for LÖVE's perspective if needed (often helps)
-- love.filesystem.setSource(arg[0]) -- arg[0] might be the .love file or dir

-- Load the main game code from the src directory
print("Root main.lua: Bootstrapping from src/main.lua...")
require 'src.main' 
