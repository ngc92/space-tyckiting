# Space Tyckiting Python client

![logo](logo.png)

*Author: ngc92*

## Synopsis

```sh
# install julia packages
julia ./setup.jl

# Run
julia ./cli.jl
```

## Prerequisites

Julia 4.x (http://julialang.org/). 
Uses PyCall for accessing the python websocket package (same as the python client), 
so julia needs to be able to find an installed python that has this package, see the 
installing instructions for the python client for further information.
```

## How-to start with new AI?

There is a dummy AIs available in `tyckiting_client/ai/` folder that can be used as a template.
 1. Copy `dummy.jl` to `your_ai.jl`
 2. Implement behaviour in the `move()` method.
 3. Run your custom AI with `julia ./cli.jl --ai your_ai`

For testing the AI, it might be helpful to start cli.jl in a julia interpreter and then just call 
the start_client() function to avoid the startup time of the julia interpreter.

## Testing

Currently there are no tests defined.


## Known issues
Crashes when the game ends :(