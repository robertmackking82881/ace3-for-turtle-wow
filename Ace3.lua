-- This file is only there in standalone Ace3 and provides handy dev tool stuff
-- Adds /rl to reload your UI and console commands.

-- GLOBALS: next, loadstring, ReloadUI, geterrorhandler
-- GLOBALS: BINDING_HEADER_ACE3, BINDING_NAME_RELOADUI, Ace3, LibStub

-- BINDINGs labels
BINDING_HEADER_ACE3 = "Ace3"
BINDING_NAME_RELOADUI = "ReloadUI"

local gui = LibStub("AceGUI-3.0")
local reg = LibStub("AceConfigRegistry-3.0")
local dialog = LibStub("AceConfigDialog-3.0")

-- Define a local strtrim function compatible with WoW 1.12 and Lua 5.0
local function strtrim(s)
    if not s then return "" end
    -- Lua 5.0 compatible trim using gsub pattern
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

Ace3 = LibStub("AceAddon-3.0"):NewAddon("Ace3", "AceConsole-3.0")
local Ace3 = Ace3

local strfind = string.find

local selectedgroup
local frame
local select
local status = {}
local configs = {}

local function frameOnClose()
    if frame then
        gui:Release(frame)
        frame = nil
    end
end

local function RefreshConfigs()
    for name in reg:IterateOptionsTables() do
        configs[name] = name
    end
end

local function ConfigSelected(widget, event, _, value)
    selectedgroup = value
    dialog:Open(value, widget)
end

local old_CloseSpecialWindows

-- GLOBALS: CloseSpecialWindows, next
function Ace3:Open()
    if not old_CloseSpecialWindows then
        old_CloseSpecialWindows = CloseSpecialWindows
        CloseSpecialWindows = function()
            local found = false
            if old_CloseSpecialWindows then
                found = old_CloseSpecialWindows()
            end
            if frame then
                frame:Hide()
                return true
            end
            return found
        end
    end

    RefreshConfigs()

    if next(configs) == nil then
        self:Print("No Configs are Registered")
        return
    end

    if not frame then
        frame = gui:Create("Frame")
        frame:ReleaseChildren()
        frame:SetTitle("Ace3 Options")
        frame:SetLayout("FILL")
        frame:SetCallback("OnClose", frameOnClose)

        select = gui:Create("DropdownGroup")
        select:SetGroupList(configs)
        select:SetCallback("OnGroupSelected", ConfigSelected)
        frame:AddChild(select)
    end

    if not selectedgroup then
        selectedgroup = next(configs)
    end

    select:SetGroup(selectedgroup)
    frame:Show()
end

local function RefreshOnUpdate(this)
    select:SetGroup(selectedgroup)
    if this then
        this:SetScript("OnUpdate", nil)
    end
end

function Ace3:ConfigTableChanged(event, appName)
    if selectedgroup == appName and frame then
        frame.frame:SetScript("OnUpdate", RefreshOnUpdate)
    end
end

reg.RegisterCallback(Ace3, "ConfigTableChange", "ConfigTableChanged")

function Ace3:PrintCmd(input)
    if not input then return end
    local _, _, input_clean = strfind(strtrim(input), "^(.-);*$")
    -- Protect against errors in loadstring argument
    if not input_clean then 
        self:Print("Invalid input")
        return
    end
    local func, err = loadstring("LibStub(\"AceConsole-3.0\"):Print(" .. input_clean .. ")")
    if not func then
        LibStub("AceConsole-3.0"):Print("Error: " .. err)
    else
        local status, execErr = pcall(func)
        if not status then
            LibStub("AceConsole-3.0"):Print("Error running command: " .. execErr)
        end
    end
end

function Ace3:OnInitialize()
    self:RegisterChatCommand("ace3", function() self:Open() end)
    self:RegisterChatCommand("rl", function() ReloadUI() end)
    self:RegisterChatCommand("print", "PrintCmd")
end