if REPENTOGON or CALLBACK_HOOKED then return end
CALLBACK_HOOKED = true
local CBW={
    ModName = "CallbackWrapper",
    ModVersion = "2.0.1",
    Author = "Keye3Tuido"
}
Isaac.ConsoleOutput(CBW.ModName.." v"..CBW.ModVersion.." - "..CBW.Author.."\n")

local debug = require("debug")
local Orig2Wrap = {}
local Wrap2Orig = {}
local ExistingCallbacks = {}
for callbackName, callbackId in pairs(ModCallbacks) do
    ExistingCallbacks[callbackId] = true
end
local Hooked = false

local function WrapFunction(func)
    local function wrappedFunc(...)
        local results = {pcall(func, ...)}
        if results[1] then
            return table.unpack(results, 2)
        end
    end
    Orig2Wrap[func] = wrappedFunc
    Wrap2Orig[wrappedFunc] = func
    return wrappedFunc
end

local function WrapByCallbackID(callbackId)
    for callbackNo, callbackInfo in pairs(Isaac.GetCallbacks(callbackId)) do
        local origFunc = rawget(callbackInfo,'Function')
        if not Wrap2Orig[origFunc] then
            local wrappedFunc = Orig2Wrap[origFunc] or WrapFunction(origFunc)
            rawset(callbackInfo,'Function', wrappedFunc)
        end
    end
end

local function CheckCallbackId(callbackId)
    local exists = ExistingCallbacks[callbackId]
    if not exists then
        ExistingCallbacks[callbackId] = true
        WrapByCallbackID(callbackId)
    end
    return exists
end

local function _WrapCallbacks()
    if not Hooked then
        for callbackId, exists in pairs(ExistingCallbacks) do
            WrapByCallbackID(callbackId)
        end

        debug.sethook(function(event)
            local callingFunc = debug.getinfo(2, 'f').func
            local callbackId
            if callingFunc == Isaac.AddPriorityCallback then
                callbackId = select(2,debug.getlocal(2, 2))
                CheckCallbackId(callbackId)
                local origFunc = select(2, debug.getlocal(2, 4))
                if not Wrap2Orig[origFunc] then
                    local wrappedFunc = Orig2Wrap[origFunc] or WrapFunction(origFunc)
                    debug.setlocal(2, 4, wrappedFunc)
                end
            elseif callingFunc == Isaac.RemoveCallback then
                callbackId = select(2,debug.getlocal(2, 2))
                CheckCallbackId(callbackId)
                local origFunc = select(2, debug.getlocal(2, 3))
                if not Wrap2Orig[origFunc] then
                    debug.setlocal(2, 3, Orig2Wrap[origFunc] or origFunc)
                end
            elseif callingFunc == Isaac.RunCallback or callingFunc == Isaac.RunCallbackWithParam or callingFunc == Isaac.GetCallbacks then
                callbackId = select(2,debug.getlocal(2, 1))
                CheckCallbackId(callbackId)
            end
        end, 'c')

        Hooked = true
    end
end

local function _UnwrapCallbacks()
    if Hooked then
        debug.sethook()

        for callbackId, exists in pairs(ExistingCallbacks) do
            for callbackNo, callbackInfo in pairs(Isaac.GetCallbacks(callbackId)) do
                local wrappedFunc = rawget(callbackInfo,'Function')
                local origFunc = Wrap2Orig[wrappedFunc]
                if origFunc then
                    rawset(callbackInfo,'Function', origFunc)
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