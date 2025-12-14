if REPENTOGON or CALLBACK_HOOKED then return end
CALLBACK_HOOKED = true
local CBW={
    ModName = "CallbackWrapper",
    ModVersion = "1.0.0",
    Author = "Keye3Tuido"
}
Isaac.ConsoleOutput(CBW.ModName.." v"..CBW.ModVersion.." - "..CBW.Author.."\n")

local debug = require("debug")
local Orig2Wrap = {}
local Wrap2Orig = {}
local Hooked = false

local function WrapFunction(func)
    return function(...)
        local success, result = pcall(func, ...)
        if success then
            return result
        end
    end
end

local function _WrapCallbacks()
    if not Hooked then
        for callbackName, callbackId in pairs(ModCallbacks) do
            for callbackNo, callbackInfo in pairs(Isaac.GetCallbacks(callbackId)) do
                local origFunc = callbackInfo.Function
                if not Wrap2Orig[origFunc] then
                    local wrappedFunc = Orig2Wrap[origFunc] or WrapFunction(origFunc)
                    Orig2Wrap[origFunc] = wrappedFunc
                    Wrap2Orig[wrappedFunc] = origFunc
                    callbackInfo.Function = wrappedFunc
                end
            end
        end

        debug.sethook(function(event)
            local callingFunc = debug.getinfo(2, 'f').func
            if callingFunc == Isaac.AddPriorityCallback then
                local origFunc = select(2, debug.getlocal(2, 4))
                if not Wrap2Orig[origFunc] then
                    local wrappedFunc = Orig2Wrap[origFunc] or WrapFunction(origFunc)
                    Orig2Wrap[origFunc] = wrappedFunc
                    Wrap2Orig[wrappedFunc] = origFunc
                    debug.setlocal(2, 4, wrappedFunc)
                end
            elseif callingFunc == Isaac.RemoveCallback then
                local origFunc = select(2, debug.getlocal(2, 3))
                if not Wrap2Orig[origFunc] then
                    debug.setlocal(2, 3, Orig2Wrap[origFunc] or origFunc)
                end
            end
        end, 'c')

        Hooked = true
    end
end

local function _UnwrapCallbacks()
    if Hooked then
        debug.sethook()

        for callbackName, callbackId in pairs(ModCallbacks) do
            for callbackNo, callbackInfo in pairs(Isaac.GetCallbacks(callbackId)) do
                local wrappedFunc = callbackInfo.Function
                local origFunc = Wrap2Orig[wrappedFunc]
                if origFunc then
                    callbackInfo.Function = origFunc
                end
            end
        end

        Orig2Wrap = {}
        Wrap2Orig = {}
        Hooked = false
    end
end

WrapCallbacks = _WrapCallbacks
UnwrapCallbacks = _UnwrapCallbacks

WrapCallbacks()

