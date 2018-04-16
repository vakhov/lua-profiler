# love-profiler

Code performance profiling for Lua.

Original concept from: 
  ProFi v1.3, by Luke Perkin 2012

The initial reason for this project was to remove any misinterpretations of
code profiling caused by the lengthy measurement time of the ProFi profiler;
and to remove the self-profiler functions from the output report.

I would like note that the profiler code has been substantially rewritten 
to remove dependence to the OO class definition, and repetitions in code; 
thus this profiler has a smaller code footprint and substantially reduced 
execution time in the range of hundreds of percent up to 900% faster.

The second purpose was to allow slight customisation of the output report, 
which I have parametrised the output report and rewritten.

Caveats: I didn't include an 'inspection' function that ProFi had, also the RAM
output is gone.

## Example output:

  ```
  > TOTAL TIME   = 0.003000 s
  
  -------------------------------------------------------------------------------
  | FILE                 : FUNCTION              : LINE  : TIME   : %     : #   |
  -------------------------------------------------------------------------------
  | game/game            : updateActors          : 15526 : 0.0020 : 66.7  :   1 |
  | monkey_box/engine    : screen2Visible        : 1650  : 0.0020 : 66.7  :   2 |
  -------------------------------------------------------------------------------
  | monkey_box/animation : fastAnimationMove     : 1048  : ~      : ~     :   2 |
  | monkey_box/animation : curvePercent          :   95  : ~      : ~     :  91 |
  | monkey_box/engine    : updateLight           : 3021  : ~      : ~     :   1 |
  | monkey_box/helper    : world2isoDistance     :  360  : ~      : ~     :   3 |
  | monkey_box/engine    : updateParticles       : 5400  : ~      : ~     :   1 |
  | monkey_box/helper    : tableLength           :  682  : ~      : ~     :   1 |
  | monkey_box/engine    : AudioVolume           : 2164  : ~      : ~     :   1 |
  | main                 : debugProfileUpdate    : 1378  : ~      : ~     :   1 |
  | monkey_box/profiler  : profilerStop          :  341  : ~      : ~     :   1 |
  | game/game            : accessTABL_USER       : 1063  : ~      : ~     :   1 |
  -------------------------------------------------------------------------------
  ```
  
  All output here is ordered by time.
  
  The partition splits the notable code that is running the slowest, all 
  other code is running too fast to determine anything specific, instead of displaying
  "0.0000" the script will tidy this up as "~". 
  
  Table headers % and # refer to percentage of total time, and function call 
  count, respectively.
  

## Usage examples:

### Print a profile report of a code block;
  
  ```
  -- Set-up:
  require("profiler") -- Run this once per program only
  
  -- Profiling:
  profilerStart()
  ... -- Code to profile, code block and/or called functions
  profilerStop()
  profilerReport("profiler.log")
  ```

  
### Profile a code block and allow mirror print to a custom print function;

  ```
  -- Set-up:
  require("profiler")
  function exampleConsolePrint()
    ... -- A custom function in your code-base to print to another file or a console stack  
  end
  attachPrintFunction(exampleConsolePrint, true) -- Function and verbose output
  
  -- Profiling:
  profilerStart()
  ... -- Code to profile, code block and/or called functions
  profilerStop()
  profilerReport("profiler.log") -- exampleConsolePrint can be called from this
  ```
  
  
### Close:

Please configure the profiler output in top of the code, particularly the 
location of the profiler source file (if not in the 'main' root source directory).

The output should be much easier to configure to your liking.
