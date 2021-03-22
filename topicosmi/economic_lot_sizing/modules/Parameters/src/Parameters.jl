module Parameters

struct ParameterData
  instName::String
  form::String
  mip::Int
  solver::String
  maxtime::Int
  tolgap::Float64
  printsol::Int
  disablesolver::Int
  maxnodes::Int
end

export ParameterData, readInputParameters

function readInputParameters(ARGS)
  ### Set standard values for the parameters ###
  instName = "instances/52_1.txt"
  form = "std"
  mip = 1
  solver = "Gurobi"
  maxtime = 60
  tolgap = 0.000001
  printsol = 0
  disablesolver = 0
  maxnodes = 10000000.0

  ### Read the parameters and set correct values whenever provided ###
  for param in 1:length(ARGS)
    if ARGS[param] == "--inst"
      instName = ARGS[param+1]
      param += 1
    elseif ARGS[param] == "--form"
      form = ARGS[param+1]
      param += 1
    elseif ARGS[param] == "--mip"
      mip = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--solver"
      solver = ARGS[param+1]
      param += 1
    elseif ARGS[param] == "--maxtime"
      maxtime = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--tolgap"
      tolgap = parse(Float64,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--printsol"
      printsol = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--disablesolver"
      disablesolver = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--maxnodes"
      maxnodes = parse(Float64,ARGS[param+1])
      param += 1
    end
  end

  params = ParameterData(instName,form,mip,solver,maxtime,tolgap,printsol,disablesolver,maxnodes)

  return params

end ### end readInputParameters

end ### end module
