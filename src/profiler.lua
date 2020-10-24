--[[
@title lua-profiler
@version 1.1
@description Code profiling for Lua based code;
The output is a report file (text) and optionally to a console or other logger.

The initial reason for this project was to reduce  misinterpretations of code profiling
caused by the lengthy measurement time of the 'ProFi' profiler v1.3;
and then to remove the self-profiler functions from the output report.

The profiler code has been substantially rewritten to remove dependence to the 'OO'
class definitions, and repetitions in code;
thus this profiler has a smaller code footprint and reduced execution time up to ~900% faster.

The second purpose was to allow slight customisation of the output report,
which I have parametrised the output report and rewritten.

Caveats: I didn't include an 'inspection' function that ProFi had, also the RAM
output is gone. Please configure the profiler output in top of the code, particularly the
location of the profiler source file (if not in the 'main' root source directory).

@authors Charles Mallah
@copyright (c) 2018-2020 Charles Mallah
@license MIT license

@sample Output will be generated like this, all output here is ordered by time:
`> TOTAL TIME   = 0.030000 s
`--------------------------------------------------------------------------------------
`| FILE                : FUNCTION                    : LINE   : TIME   : %     : #    |
`--------------------------------------------------------------------------------------
`| map                 : new                         :   301  : 0.1330 : 52.2  :    2 |
`| map                 : unpackTileLayer             :   197  : 0.0970 : 38.0  :   36 |
`| engine              : loadAtlas                   :   512  : 0.0780 : 30.6  :    1 |
`| map                 : init                        :   292  : 0.0780 : 30.6  :    1 |
`| map                 : setTile                     :    38  : 0.0500 : 19.6  : 20963|
`| engine              : new                         :   157  : 0.0220 : 8.6   :    1 |
`| map                 : unpackObjectLayer           :   281  : 0.0190 : 7.5   :    2 |
`--------------------------------------------------------------------------------------
`| ui                  : sizeCharLimit               :   328  : ~      : ~     :    2 |
`| modules/profiler    : stop                        :   192  : ~      : ~     :    1 |
`| ui                  : sizeWidthToScreenWidthHalf  :   301  : ~      : ~     :    4 |
`| map                 : setRectGridTo               :   255  : ~      : ~     :    7 |
`| ui                  : sizeWidthToScreenWidth      :   295  : ~      : ~     :   11 |
`| character           : warp                        :    32  : ~      : ~     :   15 |
`| panels              : Anon                        :     0  : ~      : ~     :    1 |
`--------------------------------------------------------------------------------------

The partition splits the notable code that is running the slowest, all other code is running
too fast to determine anything specific, instead of displaying "0.0000" the script will tidy
this up as "~". Table headers % and # refer to percentage total time, and function call count.

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
local outputFile = "profiler.lua"
local nilTime = "0.0000" -- Detect empty time, replace with tag below
local emptyToThis = "~"
local fW = 20 -- Width of the file column
local fnW = 28 -- Width of the function name column
local lW = 7 -- Width of the line column
local tW = 7 -- Width of the time taken column
local rW = 6 -- Width of the relative percentage column
local cW = 5 -- Width of the call count column
local str = "s: %-"
local reportSaved = "> Report saved to: "
local outputHeader = "| %-"..fW..str..fnW..str..lW..str..tW..str..rW..str..cW.."s|\n"
local formatHeader = string.format(outputHeader, "FILE", "FUNCTION", "LINE", "TIME", "%", "#")
local outputTitle = "%-"..fW.."."..fW..str..fnW.."."..fnW..str..lW.."s"
local formatOutput = "| %s: %-"..tW..str..rW..str..cW.."s|\n"
local formatTotalTime = "Total time: %f s\n"
local formatFunLine = "%"..(lW - 2).."i"
local formatFunTime = "%04.4f"
local formatFunRelative = "%03.1f"
local formatFunCount = "%"..(cW - 1).."i"

--[[ Locals ]]--

local module = {}
local getTime = os.clock
local string, debug, table = string, debug, table
local reportCache = {}
local allReports = {}
local reportCount = 0
local startTime = 0
local stopTime = 0
local printFun = nil
local verbosePrint = false

local function functionReport(information)
  local src = information.short_src
  if not src then
    src = "<C>"
  elseif string.sub(src, #src - 3, #src) == ".lua" then
    src = string.sub(src, 1, #src - 4)
  end
  local name = information.name
  if not name then
    name = "Anon"
  elseif string.sub(name, #name - 1, #name) == "_l" then
    name = string.sub(name, 1, #name - 2)
  end
  local title = string.format(outputTitle, src, name,
  string.format(formatFunLine, information.linedefined or 0))
  local report = reportCache[title]
  if not report then
    report = {
      title = string.format(outputTitle, src, name,
      string.format(formatFunLine, information.linedefined or 0)),
      count = 0, timer = 0,
    }
    reportCache[title] = report
    reportCount = reportCount + 1
    allReports[reportCount] = report
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
  reportCache = {}
  allReports = {}
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
  if not stopTime then
    module.stop()
  end
  filename = filename or "profiler.log"
  table.sort(allReports, function(a, b) return a.timer > b.timer end)
  local fileWriter = io.open(filename, "w+")
  local divide = false
  local totalTime = stopTime - startTime
  local totalTimeOutput = "> "..string.format(formatTotalTime, totalTime)
  fileWriter:write(totalTimeOutput)
  if printFun ~= nil then
    printFun(totalTimeOutput)
  end
  fileWriter:write(divider)
  fileWriter:write(formatHeader)
  fileWriter:write(divider)
  for i = 1, reportCount do
    local funcReport = allReports[i]
    if funcReport.count > 0 and funcReport.timer <= totalTime then
      local printThis = true
      if outputFile ~= "" then
        if singleSearchReturn(funcReport.title, outputFile) then
          printThis = false
        end
      end
      if printThis then -- Remove lines that are not needed
        if singleSearchReturn(funcReport.title, "[[C]]") then
          printThis = false
        end
      end
      if printThis then
        local count = string.format(formatFunCount, funcReport.count)
        local timer = string.format(formatFunTime, funcReport.timer)
        local relTime = string.format(formatFunRelative, (funcReport.timer / totalTime) * 100)
        if not divide and timer == nilTime then
          fileWriter:write(divider)
          divide = true
        end
        if timer == nilTime then
          timer = emptyToThis
          relTime = emptyToThis
        end
        -- Build final line
        local output = string.format(formatOutput, funcReport.title, timer, relTime, count)
        fileWriter:write(output)
        -- This is a verbose print to the attached print function
        if printFun ~= nil and verbosePrint then
          printFun(output)
        end
      end
    end
  end
  fileWriter:write(divider)
  fileWriter:close()
  if printFun ~= nil then
    printFun(reportSaved.."'"..filename.."'")
  end
end

--[[ End ]]--
return module
