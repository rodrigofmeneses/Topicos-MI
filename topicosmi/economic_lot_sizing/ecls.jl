push!(LOAD_PATH, "modules/")

using Pkg

# using JuMP
# using Gurobi

import Data
import Parameters
import Formulations

# Read the parameters from command line
params = Parameters.readInputParameters(ARGS)

# Read instance data
inst = Data.readData("instances/52_1.txt")

if params.form == "std"
    Formulations.standardFormulation(inst, params)
elseif params.form == "mcd"
    Formulations.multicommodityFormulation(inst, params)
end