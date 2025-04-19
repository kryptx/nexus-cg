-- lua_syntax_demo.lua
-- Demonstrates Lua colon vs. dot syntax for tables/methods

print("--- Lua Syntax Demonstration ---")

-- Define a simple table (like a class)
local MyClass = { value = "instance_value" }
MyClass.__index = MyClass

-- Method definition using colon ':'
-- Lua implicitly adds 'self' as the first argument
function MyClass:method(arg1)
  print(string.format("Called MyClass:method(arg1) -> defined with :method(...)"))
  print(string.format("  self.value = %s", self and self.value or "nil"))
  print(string.format("  arg1 = %s", arg1 or "nil"))
  print("---")
end

-- Method definition using colon ':' BUT also explicitly listing 'self'
-- This mirrors the style in renderer.lua
function MyClass:explicit_self_method(self, arg1)
  print(string.format("Called MyClass:explicit_self_method(self, arg1) -> defined with :explicit_self_method(self, ...)"))
  print(string.format("  self = %s (type: %s)", tostring(self), type(self)))
  print(string.format("  self.value = %s", (type(self) == 'table' and self.value) or "nil"))
  print(string.format("  arg1 = %s", arg1 or "nil"))
  print("---")
end

-- Function definition using dot '.'
-- 'self' is NOT implicitly added. If used, it's just a regular parameter name.
function MyClass.dot_func(param1, arg1)
  print(string.format("Called MyClass.dot_func(param1, arg1) -> defined with .dot_func(...)"))
  -- If called like instance.dot_func(instance, ...), param1 will be the instance
  -- If called like instance:dot_func(...), param1 will be the instance (implicit self)
  print(string.format("  param1 = %s (type: %s)", tostring(param1), type(param1)))
  print(string.format("  param1.value = %s", (type(param1) == 'table' and param1.value) or "nil"))
  print(string.format("  arg1 = %s", arg1 or "nil"))
  print("---")
end

-- Create an instance
local instance = setmetatable({ specific = "my_instance"}, MyClass)
print("Created instance with value:", instance.value)
print("")

print("=== 1. Calling method defined with ':' using ':' (instance:method('A')) ===")
instance:method('A') -- Correct way to call a method

print("=== 2. Calling method defined with ':' using '.' (instance.method(instance, 'B')) ===")
instance.method(instance, 'B') -- Manually passing 'self'

print("=== 3. Calling function defined with '.' using '.' (instance.dot_func(instance, 'C')) ===")
instance.dot_func(instance, 'C') -- Passing instance explicitly as first arg

print("=== 4. Calling function defined with '.' using ':' (instance:dot_func('D')) ===")
-- This implicitly passes 'instance' as the FIRST arg ('param1') due to the ':' call
-- and 'D' as the second arg ('arg1')
instance:dot_func('D')

print("=== 5. Calling method defined with ':' and explicit 'self' using ':' (instance:explicit_self_method('E')) ===")
-- The ':' call implicitly passes 'instance'. Lua assigns this to the first param ('self').
-- 'E' is passed as the next argument ('arg1').
instance:explicit_self_method('E')

print("--- Demonstration Complete ---") 
