--[[
@title lua-profiler
@description Code profiling for Lua based code;
The output is a report file (text) and optionally to a console or other logger

@authors Charles Mallah
@copyright (c) 2018-2020 Charles Mallah
@license MIT license

@example Print a profile report of a code block
`local profiler = require("profiler")
`profiler.start()
`-- Code block and/or called functions to profile --
`profiler.stop()
`profiler.report("profiler.log")

@example Profile a code block and allow mirror print to a custom print function
`local profiler = require("profiler")
`function exampleConsolePrint()
`  -- Custom function in your code-base to print to file or console --
`end
`profiler.attachPrintFunction(exampleConsolePrint, true)
`profiler.start()
`-- Code block and/or called functions to profile --
`profiler.stop()
`profiler.report("profiler.log") -- exampleConsolePrint will now be called from this

]]

--[[ Configuration ]]--

-- Location and name of profiler (to remove itself from reports);
-- e.g. if this is in a 'tool' folder, rename this as: "tool/profiler.lua"
local PROFILER_FILENAME = "profiler.lua"
local EMPTY_TIME = "0.0000" -- Detect empty time, replace with tag below
local emptyToThis = "~"
local fW = 20 -- Width of the file column
local fnW = 28 -- Width of the function name column
local lW = 7 -- Width of the line column
local tW = 7 -- Width of the time taken column
local rW = 6 -- Width of the relative percentage column
local cW = 5 -- Width of the call count column
local str = "s: %-"
local reportSaved = " > Report saved to"
local outputHeader = "| %-"..fW..str..fnW..str..lW..str..tW..str..rW..str..cW.."s|\n"
local formatHeader = string.format(outputHeader, "FILE", "FUNCTION", "LINE", "TIME", "%", "#")
local outputTitle = "%-"..fW.."."..fW..str..fnW.."."..fnW..str..lW.."s"
local formatOutput = "| %s: %-"..tW..str..rW..str..cW.."s|\n"
local formatTotalTime = "TOTAL TIME   = %f s\n"
local formatFunLine = "%"..(lW - 2).."i"
local formatFunTime = "%04.4f"
local formatFunRelative = "%03.1f"
local formatFunCount = "%"..(cW - 1).."i"

--[[ Locals ]]--

local module = {}
local getTime = os.clock
local string = string
local debug = debug
local table = table
local TABL_REPORT_CACHE = {}
local TABL_REPORTS = {}
local reportCount = 0
local startTime = 0
local stopTime = 0
local printFun = nil
local verbosePrint = false

local function functionReport(information)
  local src = information.short_src
  if src == nil then
    src = "<C>"
  elseif string.sub(src, #src - 3, #src) == ".lua" then
    src = string.sub(src, 1, #src - 4)
  end
  local name = information.name
  if name == nil then
    name = "Anon"
  elseif string.sub(name, #name - 1, #name) == "_l" then
    name = string.sub(name, 1, #name - 2)
  end
  local title = string.format(outputTitle, src, name,
  string.format(formatFunLine, information.linedefined or 0))
  local report = TABL_REPORT_CACHE[title]
  if not report then
    report = {
      title = string.format(outputTitle, src, name,
      string.format(formatFunLine, information.linedefined or 0)),
      count = 0, timer = 0,
    }
    TABL_REPORT_CACHE[title] = report
    reportCount = reportCount + 1
    TABL_REPORTS[reportCount] = report
  end
  return report
end

local onDebugHook = function(hookType)
  local information = debug.getinfo(2, "nS")
  if hookType == "call" then
    local funcReport = functionReport(information)
    funcReport.callTime = getTime()
    funcReport.count = funcReport.count + 1
  elseif hookType == "return" then
    local funcReport = functionReport(information)
    if funcReport.callTime and funcReport.count > 0 then
      funcReport.timer = funcReport.timer + (getTime() - funcReport.callTime)
    end
  end
end

local function charRepetition(n, character)
  local s = ""
  character = character or " "
  for _ = 1, n do
    s = s..character
  end
  return s
end

local function singleSearchReturn(inputString, search)
  for _ in string.gmatch(inputString, search) do -- luacheck: ignore
    do return true end
  end
  return false
end

local divider = charRepetition(#formatHeader - 1, "-").."\n"

--[[ Functions ]]--

--[[Attach a print function to the profiler, to receive a single string parameter
@param fn (function) <required>
@param verbose (boolean) <default: false>
]]
function module.attachPrintFunction(fn, verbose)
  printFun = fn
  verbosePrint = verbose or false
end

--[[Start the profiling
]]
function module.start()
  TABL_REPORT_CACHE = {}
  TABL_REPORTS = {}
  reportCount = 0
  startTime = getTime()
  stopTime = nil
  debug.sethook(onDebugHook, "cr", 0)
end

--[[Stop profiling
]]
function module.stop()
  stopTime = getTime()
  debug.sethook()
end

--[[Writes the profile report to file (will stop profiling if not stopped already)
@param filename (string) <default: "profiler.log"> [File will be created and overwritten]
]]
function module.report(filename)
  if stopTime == nil then
    module.stop()
  end
  filename = filename or "profiler.log"
  table.sort(TABL_REPORTS, function(a, b) return a.timer > b.timer end)
  local file = io.open(filename, "w+")
  local divide = false
  local totalTime = stopTime - startTime
  local totalTimeOutput = " > "..string.format(formatTotalTime, totalTime)
  file:write(totalTimeOutput)
  if printFun ~= nil then
    printFun(totalTimeOutput)
  end
  file:write("\n"..divider)
  file:write(formatHeader)
  file:write(divider)
  for i = 1, reportCount do
    local funcReport = TABL_REPORTS[i]
    if funcReport.count > 0 and funcReport.timer <= totalTime then
      local printThis = true
      if PROFILER_FILENAME ~= "" then
        if singleSearchReturn(funcReport.title, PROFILER_FILENAME) then
          printThis = false
        end
      end
      if printThis == true then -- Remove lines that are not needed
        if singleSearchReturn(funcReport.title, "[[C]]") then
          printThis = false
        end
      end
      if printThis == true then
        local count = string.format(formatFunCount, funcReport.count)
        local timer = string.format(formatFunTime, funcReport.timer)
        local relTime = string.format(formatFunRelative, (funcReport.timer / totalTime) * 100)
        if divide == false and timer == EMPTY_TIME then
          file:write(divider)
          divide = true
        end
        if timer == EMPTY_TIME then
          timer = emptyToThis
          relTime = emptyToThis
        end
        -- Build final line
        local output = string.format(formatOutput, funcReport.title, timer, relTime, count)
        file:write(output)
        -- This is a verbose print to the attached print function
        if printFun ~= nil and verbosePrint == true then
          printFun(output)
        end
      end
    end
  end
  file:write(divider)
  file:close()
  if printFun ~= nil then
    printFun(reportSaved.."'"..filename.."'")
  end
end

--[[ End ]]--
return module
