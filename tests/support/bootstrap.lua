local Bootstrap = {}

local prefixes = {
    "Kdm/",
    "KDM/",
}

local function normalizePath(path)
    local normalized = path:gsub("//+", "/")
    normalized = normalized:gsub("%./", "")
    return normalized
end

function Bootstrap.addKdmSearcher(root)
    root = root or ""
    table.insert(package.searchers, 1, function(moduleName)
        local relative
        for _, prefix in ipairs(prefixes) do
            if moduleName:sub(1, #prefix) == prefix then
                relative = moduleName:sub(#prefix + 1)
                break
            end
        end

        if not relative then
            return nil
        end

        local candidates = {
            normalizePath(("%s%s.ttslua"):format(root, relative)),
            normalizePath(("%s%s.lua"):format(root, relative)),
            normalizePath(("%s%s/init.ttslua"):format(root, relative)),
            normalizePath(("%s%s/init.lua"):format(root, relative)),
        }

        for _, file in ipairs(candidates) do
            local chunk, err = loadfile(file)
            if chunk then
                return chunk, file
            end
            if err and not err:match("No such file") then
                return ("\n\tloader error for %s: %s"):format(moduleName, err)
            end
        end

        return ("\n\tno file found for %s (looked in %s)"):format(moduleName, table.concat(candidates, ", "))
    end)
end

function Bootstrap.stubTts()
    local function noop()
    end

    _G.log = _G.log or noop
    _G.printToAll = _G.printToAll or noop
    _G.broadcastToAll = _G.broadcastToAll or noop
    _G.logStyle = _G.logStyle or noop

    if type(_G.Wait) ~= "table" then
        _G.Wait = {
            frames = function(callback)
                return callback()
            end,
            condition = function(callback, condition, timeout, timeoutCallback)
                -- In tests, just call the callback immediately (assume condition is met)
                return callback()
            end,
        }
    end
end

function Bootstrap.setup()
    Bootstrap.stubTts()
    Bootstrap.addKdmSearcher("")
end

return Bootstrap
