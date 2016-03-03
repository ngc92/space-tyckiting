# Space Tyckiting Python client

![logo](logo.png)

*Author: ngc92*

## Synopsis

requires the following julia packages
```sh
# install julia packages
Pkg.add("JSON")
Pkg.add("PyCall")

# Run
python ./cli.py
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
 3. Run your custom AI with `python ./cli --ai your_ai`



## Testing

Currently there are no tests defined.