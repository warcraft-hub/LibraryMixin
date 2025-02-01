--[[
  LibraryMixin: An enhanced versioning system for WoW addons.
  Provides robust functions for registering, retrieving, updating,
  locking, and removing libraries. Includes dependency management and
  optional callback integration.
  
  ## Interface: 110100
  ## Version: 1.0.0
  ## Author: Devil
  ## Email: devil.wow.uk@gmail.com
--]]

-- Define reserved names that cannot be used as library identifiers.
local RESERVED_NAMES = {
  RemoveLibrary = true,
  LibraryExists  = true,
  UpdateLibrary  = true,
  ListLibrary    = true,
}

LibraryMixin = {
  libs         = {},  -- Registered libraries.
  minors       = {},  -- Version numbers for libraries.
  locked       = {},  -- Locked libraries to prevent changes.
  dependencies = {},  -- Dependency management.
}

----------------------------------------------------------------------
-- Creates or updates a library.
-- If a library exists with an equal or higher version, the new registration is ignored.
--
-- @param major string: Unique identifier for the library.
-- @param minor number|string: The library version (first digit sequence is used).
-- @return table|nil: The library table (or nil if update is skipped).
-- @return number|nil: The previous version if it existed.
----------------------------------------------------------------------
function LibraryMixin:NewLibrary(major, minor)
  assert(type(major) == "string", "Bad argument #1 to 'NewLibrary' (string expected)")
  
  -- Prevent use of a reserved name.
  if RESERVED_NAMES[major] then
    error("Library name '" .. major .. "' is protected and cannot be used.")
  end

  local version = tonumber(string.match(tostring(minor), "%d+"))
  assert(version, "Minor version must be a number or contain a number.")

  local oldVersion = self.minors[major]
  if oldVersion and oldVersion >= version then
    return nil, oldVersion
  end

  self.minors[major] = version
  self.libs[major] = self.libs[major] or {}
  return self.libs[major], oldVersion
end

----------------------------------------------------------------------
-- Retrieves a library by its 'major' identifier.
--
-- @param major string: Unique library identifier.
-- @param silent boolean (optional): If true, returns nil instead of error on not found.
-- @return table|nil: The library table if found.
-- @return number|nil: The library's version if found.
----------------------------------------------------------------------
function LibraryMixin:GetLibrary(major, silent)
  local lib = self.libs[major]
  if not lib then
    if not silent then
      error(string.format("Library '%s' not found.", major), 2)
    end
    return nil
  end
  return lib, self.minors[major]
end

----------------------------------------------------------------------
-- Iterates over all registered libraries.
--
-- @param sorted boolean (optional): If true, returns libraries sorted by name.
-- @return function: An iterator returning (name, library) pairs.
----------------------------------------------------------------------
function LibraryMixin:IterateLibraries(sorted)
  if not sorted then
    return pairs(self.libs)
  else
    local keys = {}
    for key in pairs(self.libs) do
      table.insert(keys, key)
    end
    table.sort(keys)
    local i = 0
    return function()
      i = i + 1
      if keys[i] then
        return keys[i], self.libs[keys[i]]
      end
    end
  end
end

----------------------------------------------------------------------
-- Checks if a library exists.
--
-- @param major string: The unique library identifier.
-- @return boolean: true if the library exists, false otherwise.
----------------------------------------------------------------------
function LibraryMixin:LibraryExists(major)
  return self.libs[major] ~= nil
end

----------------------------------------------------------------------
-- Removes a library from the registry.
--
-- @param major string: The unique library identifier.
-- @return boolean, string|nil: true if removal was successful; otherwise false and an error message.
----------------------------------------------------------------------
function LibraryMixin:RemoveLibrary(major)
  if self:IsLocked(major) then
    error("Library '" .. major .. "' is locked and cannot be removed.", 2)
  end
  if not self.libs[major] then
    return false, "Library '" .. major .. "' not found."
  end
  local oldVersion = self.minors[major]
  local lib = self.libs[major]
  self.libs[major] = nil
  self.minors[major] = nil
  if self.OnLibraryRemove then
    self:OnLibraryRemove(major, lib, oldVersion)
  end
  return true
end

----------------------------------------------------------------------
-- Updates a library to a new version, regardless of current version.
-- If the library doesn't exist, it is created.
--
-- @param major string: The unique library identifier.
-- @param minor number|string: The new version.
-- @return table: The updated library table.
-- @return number|nil: The previous version if it existed.
----------------------------------------------------------------------
function LibraryMixin:UpdateLibrary(major, minor)
  if self:IsLocked(major) then
    error("Library '" .. major .. "' is locked and cannot be updated.", 2)
  end
  assert(type(major) == "string", "Bad argument #1 to 'UpdateLibrary' (string expected)")
  local version = tonumber(string.match(tostring(minor), "%d+"))
  assert(version, "Minor version must be a number or contain a number.")
  local oldVersion = self.minors[major]
  if self.libs[major] then
    self.minors[major] = version
    if self.OnLibraryUpdate then
      self:OnLibraryUpdate(major, self.libs[major], oldVersion, version)
    end
    return self.libs[major], oldVersion
  else
    return self:NewLibrary(major, minor)
  end
end

----------------------------------------------------------------------
-- Lists all registered libraries.
--
-- @param sorted boolean (optional): If true, returns a list sorted by library name.
-- @return table: A list of tables with fields: name, library, and version.
----------------------------------------------------------------------
function LibraryMixin:ListLibrary(sorted)
  local list = {}
  if sorted then
    local keys = {}
    for key in pairs(self.libs) do
      table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
      table.insert(list, { name = key, library = self.libs[key], version = self.minors[key] })
    end
  else
    for key, lib in pairs(self.libs) do
      table.insert(list, { name = key, library = lib, version = self.minors[key] })
    end
  end
  return list
end

----------------------------------------------------------------------
-- Locking mechanism: Prevent updates or removals on locked libraries.
----------------------------------------------------------------------

-- Checks if a library is locked.
function LibraryMixin:IsLocked(major)
  return self.locked[major] == true
end

-- Locks a library.
function LibraryMixin:LockLibrary(major)
  assert(type(major) == "string", "Bad argument #1 to 'LockLibrary' (string expected)")
  if not self.libs[major] then
    error("Cannot lock non-existing library '" .. major .. "'.", 2)
  end
  self.locked[major] = true
  return true
end

-- Unlocks a library.
function LibraryMixin:UnlockLibrary(major)
  assert(type(major) == "string", "Bad argument #1 to 'UnlockLibrary' (string expected)")
  if not self.locked[major] then
    error("Library '" .. major .. "' is not locked.", 2)
  end
  self.locked[major] = nil
  return true
end

----------------------------------------------------------------------
-- Version query and count functions.
----------------------------------------------------------------------

-- Retrieves only the version number of a library.
function LibraryMixin:GetVersion(major)
  return self.minors[major]
end

-- Counts the number of registered libraries.
function LibraryMixin:CountLibraries()
  local count = 0
  for _ in pairs(self.libs) do
    count = count + 1
  end
  return count
end

----------------------------------------------------------------------
-- Iteration helper: Applies a function to every registered library.
----------------------------------------------------------------------

function LibraryMixin:ForEachLibrary(func)
  for major, lib in pairs(self.libs) do
    func(major, lib, self.minors[major])
  end
end

----------------------------------------------------------------------
-- Dependency management.
----------------------------------------------------------------------

-- Registers a dependency for a library.
function LibraryMixin:RegisterDependency(major, dependency, requiredVersion)
  assert(type(major) == "string", "Bad argument #1 to 'RegisterDependency' (string expected)")
  assert(type(dependency) == "string", "Bad argument #2 to 'RegisterDependency' (string expected)")
  local reqVer = tonumber(string.match(tostring(requiredVersion), "%d+"))
  assert(reqVer, "Required version must be a number or contain a number.")
  
  self.dependencies[major] = self.dependencies[major] or {}
  table.insert(self.dependencies[major], { dependency = dependency, version = reqVer })
  return true
end

-- Checks if all dependencies for a library are met.
function LibraryMixin:CheckDependencies(major)
  local deps = self.dependencies[major]
  if not deps then
    return true
  end
  for _, dep in ipairs(deps) do
    local libVersion = self.minors[dep.dependency]
    if not libVersion or libVersion < dep.version then
      return false, "Dependency '" .. dep.dependency .. "' (version " .. dep.version .. ") is not satisfied."
    end
  end
  return true
end

----------------------------------------------------------------------
-- Resets the entire library registry (use with caution).
----------------------------------------------------------------------

function LibraryMixin:ResetLibraries()
  self.libs         = {}
  self.minors       = {}
  self.locked       = {}
  self.dependencies = {}
  return true
end

----------------------------------------------------------------------
-- Metatable: Allows LibraryMixin to be called like a function to retrieve libraries.
----------------------------------------------------------------------

setmetatable(LibraryMixin, { __call = LibraryMixin.GetLibrary })

----------------------------------------------------------------------
-- Optional: Integrate callback functionality (if CallbackRegistryMixin is available).
----------------------------------------------------------------------

function LibraryMixin:InitCallbacks()
  if CreateFromMixins then
    CreateFromMixins(self, CallbackRegistryMixin)
    self:GenerateCallbackEvents({
      "OnLibraryUpdate",
      "OnLibraryLoad",
      "OnLibraryRemove"
    })
  end
end