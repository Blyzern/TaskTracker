-- TaskTracker Frame
local TaskTrackerFrame = CreateFrame("Frame", "TaskTrackerMainFrame", UIParent)
TaskTrackerFrame:SetWidth(400)
TaskTrackerFrame:SetHeight(300)
TaskTrackerFrame:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
TaskTrackerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TaskTrackerFrame:SetBackdropColor(0, 0, 0, 0.8)
TaskTrackerFrame:EnableMouse(true)
TaskTrackerFrame:SetMovable(true)
TaskTrackerFrame:RegisterForDrag("LeftButton")
TaskTrackerFrame:SetScript("OnDragStart", TaskTrackerFrame.StartMoving)
TaskTrackerFrame:SetScript("OnDragStop", TaskTrackerFrame.StopMovingOrSizing)

-- Title
local Title = TaskTrackerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetFontObject("GameFontHighlight")
Title:SetPoint("TOP", TaskTrackerFrame, "TOP", 0, -12)
Title:SetText("TaskTracker")

local TaskInput = CreateFrame("EditBox", nil, TaskTrackerFrame, "InputBoxTemplate")
TaskInput:SetSize(260, 30)
TaskInput:SetPoint("TOPLEFT", TaskTrackerFrame, "TOPLEFT", 20, -40)
TaskInput:SetAutoFocus(false)
TaskInput:SetMaxLetters(100)

-- Add Button for tasks
local AddButton = CreateFrame("Button", nil, TaskTrackerFrame, "UIPanelButtonTemplate")
AddButton:SetSize(24, 24)
AddButton:SetPoint("LEFT", TaskInput, "RIGHT", 5, 0)
AddButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
AddButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
AddButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
-- Adjust texture insets to avoid cutting
AddButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
AddButton:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
AddButton:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)

AddButton:SetNormalFontObject("GameFontNormal")
AddButton:SetHighlightFontObject("GameFontHighlight")


-- Task List Container
local TaskListFrame = CreateFrame("Frame", nil, TaskTrackerFrame)
TaskListFrame:SetSize(360, 200)
TaskListFrame:SetPoint("TOPLEFT", TaskTrackerFrame, "TOPLEFT", 20, -80)
TaskListFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TaskListFrame:SetBackdropColor(0, 0, 0, 0.5)

-- Scrollable Area for Task List
local TaskListScrollFrame = CreateFrame("ScrollFrame", "TaskListScrollFrame", TaskListFrame, "UIPanelScrollFrameTemplate")
TaskListScrollFrame:SetPoint("TOPLEFT", TaskListFrame, "TOPLEFT", 5, -5)
TaskListScrollFrame:SetPoint("BOTTOMRIGHT", TaskListFrame, "BOTTOMRIGHT", -28, 5)

local TaskListContent = CreateFrame("Frame", nil, TaskListScrollFrame)
TaskListContent:SetSize(340, 200)
TaskListScrollFrame:SetScrollChild(TaskListContent)

-- Task List Table 
local tasks = {}
-- Function to Refresh the Task List
local function RefreshTaskList()
    -- Hide any existing task frames
    for _, child in ipairs({TaskListContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = 0
    local containerWidth = 340
    -- Create a task frame for each task in the list
    for index, task in ipairs(tasks) do
        local TaskFrame = CreateFrame("Frame", nil, TaskListContent)
        TaskFrame:SetSize(containerWidth, 30)
        TaskFrame:SetPoint("TOPLEFT", TaskListContent, "TOPLEFT", 0, -yOffset)
        
        local Checkedbutton = CreateFrame("CheckButton", nil, TaskFrame, "UICheckButtonTemplate")
        Checkedbutton:SetSize(23, 23)
        Checkedbutton:SetPoint("LEFT", TaskFrame, "LEFT", 5, 0)
        Checkedbutton:SetChecked(task.checked)

        -- Toggle the checkbox state and save it when clicked
        Checkedbutton:SetScript("OnClick", function()
            task.checked = not task.checked -- Toggle the state
            TaskTrackerDB.tasksList[index].checked = task.checked -- Save to database
        end)

        -- Optional: Add tooltip to explain functionality
        Checkedbutton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Mark this task as completed.")
            GameTooltip:Show()
        end)
        Checkedbutton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        local TaskLabel = TaskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        TaskLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        TaskLabel:SetPoint("LEFT", Checkedbutton, "RIGHT", 5, 0)
        TaskLabel:SetWidth(containerWidth - 55)
        TaskLabel:SetWordWrap(true)
        TaskLabel:SetJustifyH("LEFT") -- Align text to the left
        TaskLabel:SetText(task.text)

        -- Calculate the height of the text
        local textHeight = TaskLabel:GetStringHeight()
        local frameHeight = math.max(20, textHeight + 5) -- Minimum height of 20, add padding
        TaskFrame:SetHeight(frameHeight)

        local DeleteButton = CreateFrame("Button", nil, TaskFrame, "UIPanelButtonTemplate")
        DeleteButton:SetSize(25, 25)
        DeleteButton:SetPoint("RIGHT", TaskFrame, "RIGHT", -10, 0)
        -- Set the "X" button textures
        DeleteButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        DeleteButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        DeleteButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")

        -- Adjust texture insets to avoid cutting
        DeleteButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
        DeleteButton:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
        DeleteButton:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)

        DeleteButton:SetScript("OnClick", function()
            table.remove(tasks, index)
            TaskTrackerDB["tasksList"] = tasks
            RefreshTaskList() -- Refresh the list after removal
        end)

        yOffset = yOffset + frameHeight -- Increase the yOffset to position the next task below the previous one
    end

    -- Update the height of the content frame based on the number of tasks
    TaskListContent:SetHeight(math.max(yOffset, 200)) -- Set a minimum height (200px) to prevent too small content area
end


local CloseButton = CreateFrame("Button", nil, TaskTrackerFrame, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", TaskTrackerFrame, "TOPRIGHT", -5, -5)
CloseButton:SetScript("OnClick", function ()
    TaskTrackerDB.isVisible = false
    TaskTrackerFrame:Hide()
end)

-- Create the minimap button
local TaskTrackerMinimapButton = CreateFrame("Button", "TaskTrackerMinimapButton", Minimap)
TaskTrackerMinimapButton:SetSize(32, 32)  -- Set button size (32x32 pixels)
TaskTrackerMinimapButton:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)  -- Position relative to the Minimap
TaskTrackerMinimapButton:SetNormalTexture("Interface\\AddOns\\TaskTracker\\Icons\\Minimap_icon.blp")  -- Icon texture
TaskTrackerMinimapButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")  -- Highlight on hover
TaskTrackerMinimapButton:SetPushedTexture("Interface\\Buttons\\Button-Pressed")  -- Button when clicked
TaskTrackerMinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText("TaskTracker |cFF00FF00 v0.8|r\nClick to toggle", 1, 1, 1)  -- Tooltip text
    GameTooltip:Show()
end)

TaskTrackerMinimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
TaskTrackerMinimapButton:RegisterForDrag("LeftButton")  -- Allows the user to drag the button

TaskTrackerMinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

TaskTrackerMinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)


-- Add a script to toggle visibility on click
TaskTrackerMinimapButton:SetScript("OnClick", function()
    if TaskTrackerFrame:IsShown() then
        TaskTrackerFrame:Hide()  -- Hide TaskTracker UI
        TaskTrackerDB["isVisible"] = false
    else
        TaskTrackerFrame:Show()  -- Show TaskTracker UI
        TaskTrackerDB["isVisible"] = true
    end
end)

-- Add Button Functionality
AddButton:SetScript("OnClick", function()
    local taskText = TaskInput:GetText():gsub("^%s*(.-)%s*$", "%1") -- Trim spaces
    if taskText == "" then
        DEFAULT_CHAT_FRAME:AddMessage("TaskTracker: Task cannot be empty!", 1, 0, 0)
        return
    end

    -- Check for duplicates
    for _, task in ipairs(tasks) do
        if task == taskText then
            DEFAULT_CHAT_FRAME:AddMessage("TaskTracker: Task already exists!", 1, 0.5, 0)
            return
        end
    end
    local newTask = { text = taskText, checked = false }
    table.insert(tasks, newTask) -- Add the task to the list
    TaskTrackerDB["tasksList"] = tasks
    TaskInput:SetText("") -- Clear the input box
    TaskInput:ClearFocus()
    RefreshTaskList() -- Refresh the task list
end)

-- Load Saved Tasks on Addon Load
local function OnAddonLoaded(self, event, addon)
    if addon == "TaskTracker" then
        print(addon ..": LOADED_CORRECTLY")
        if not TaskTrackerDB then
            TaskTrackerDB = {
                ["tasksList"] = {},
                ["isVisible"] = true
            } -- Initialize database if empty
        end
        tasks = TaskTrackerDB["tasksList"] -- Load saved tasks into memory
        RefreshTaskList()
        if TaskTrackerDB["isVisible"] == true then
            TaskTrackerFrame:Show()
        else
            TaskTrackerFrame:Hide()
        end
        
    end
end

-- Save Tasks on Logout
local function OnPlayerLogout(self, event)
    TaskTrackerDB["tasksList"] = tasks -- Save current tasks to SavedVariables
end

-- Add a slash command to toggle the frame
SLASH_TASKTRACKER1 = "/tasktracker"
SlashCmdList["TASKTRACKER"] = function()
    if TaskTrackerFrame:IsShown() then
        TaskTrackerFrame:Hide()
        TaskTrackerDB["isVisible"] = false
    else
        TaskTrackerFrame:Show()
        TaskTrackerDB["isVisible"] = true
    end
end

-- Register Events
TaskTrackerFrame:RegisterEvent("ADDON_LOADED")
TaskTrackerFrame:RegisterEvent("PLAYER_LOGOUT")
TaskTrackerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(self, event, ...)
    elseif event == "PLAYER_LOGOUT" then
        OnPlayerLogout(self, ...)
    end
end)

