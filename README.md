# lua-profiler

## Vignette

**Title**:
lua-profiler

**Version**:
1.0

**Description**:
Code profiling for Lua based code;
The output is a report file (text) and optionally to a console or other logger.

The initial reason for this project was to reduce  misinterpretations of
code profiling caused by the lengthy measurement time of the 'ProFi' profiler v1.3;
and then to remove the self-profiler functions from the output report.

I would like note that the profiler code has been substantially rewritten
to remove dependence to the OO class definition, and repetitions in code;
thus this profiler has a smaller code footprint and substantially reduced
execution time up to 900% faster.

The second purpose was to allow slight customisation of the output report,
which I have parametrised the output report and rewritten.

Caveats: I didn't include an 'inspection' function that ProFi had, also the RAM
output is gone.

Please configure the profiler output in top of the code, particularly the
location of the profiler source file (if not in the 'main' root source directory).


**Authors**:
Charles Mallah

**Copyright**:
(c) 2018-2020 Charles Mallah

**License**:
MIT license

**Sample**:
Output will be generated like this, all output here is ordered by time:

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
    | game/game            : accessTABL_USER       : 1063  : ~      : ~     :   1 |
    -------------------------------------------------------------------------------


The partition splits the notable code that is running the slowest, all other code is running
too fast to determine anything specific, instead of displaying "0.0000" the script will tidy
this up as "~". Table headers % and # refer to percentage total time, and function call count.


**Example**:
Print a profile report of a code block

    local profiler = require("profiler")
    profiler.start()
    -- Code block and/or called functions to profile --
    profiler.stop()
    profiler.report("profiler.log")



**Example**:
Profile a code block and allow mirror print to a custom print function

    local profiler = require("profiler")
    function exampleConsolePrint()
      -- Custom function in your code-base to print to file or console --
    end
    profiler.attachPrintFunction(exampleConsolePrint, true)
    profiler.start()
    -- Code block and/or called functions to profile --
    profiler.stop()
    profiler.report("profiler.log") -- exampleConsolePrint will now be called from this



## API

**attachPrintFunction** (fn, verbose\*) :   

> Attach a print function to the profiler, to receive a single string parameter  
> &rarr; **fn** (function) <*required*>  
> &rarr; **verbose** (boolean) <*default: false*>  

**start** () :   

> Start the profiling  

**stop** () :   

> Stop profiling  

**report** (filename\*) :   

> Writes the profile report to file (will stop profiling if not stopped already)  
> &rarr; **filename** (string) <*default: "profiler.log"*> `File will be created and overwritten`  
