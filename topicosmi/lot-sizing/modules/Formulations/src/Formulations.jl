module Formulations

using JuMP
using Gurobi

using Data
using Parameters

mutable struct stdFormVars
  x
  y
  s
  xr
  yr
  sr
end

export standardFormulation, stdFormVars

function standardFormulation(inst::InstanceData, params::ParameterData)
    N = inst.N

    ### select solver ###
    if params.solver == "Gurobi"
        model = Model(Gurobi.Optimizer)
        set_optimizer_attribute(model, "TimeLimit", params.maxtime) # Time limit
        set_optimizer_attribute(model, "MIPGap", params.tolgap) # Relative MIP optimality gap
        set_optimizer_attribute(model, "NodeLimit", params.maxnodes) # MIP node limit
        set_optimizer_attribute(model, "Cuts", 3) # Global cut aggressiveness setting. 
    else
        println("No solver selected")
        return 0
    end

    ### variables """
    @variable(model, 0 <= x[t=1:N] <= Inf)
    @variable(model, 0 <= xr[t=1:N] <= Inf)
    @variable(model, y[t=1:N], Bin)
    @variable(model, yr[t=1:N], Bin)
    @variable(model, 0 <= s[t=1:N] <= Inf)
    @variable(model, 0 <= sr[t=1:N] <= Inf)

    ### objective function ###
    @objective(model, Min, sum(inst.P[t]*x[t] + inst.H[t]*s[t] + inst.F[t]*y[t] for t=1:N) + sum(inst.PR[t]*xr[t] + inst.HR[t]*sr[t] + inst.FR[t]*yr[t] for t=1:N))

    ### constraints ###
    # no tempo t = 1 a qtd produzida e remanufaturada menos a sobra tem que atender a demanda
    @constraint(model, balance0, x[1] + xr[1] - s[1] == inst.D[1])
    
    @constraint(model, balance[t=2:N], s[t-1] + x[t] + xr[t] - s[t] == inst.D[t])
end

end