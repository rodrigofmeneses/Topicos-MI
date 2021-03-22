using PackageCompiler

create_sysimage([:JuMP,:Gurobi]; sysimage_path="ecls.dylib", precompile_execution_file="ecls.jl")